# Speed Reading App — Implementation Plan (v2)

Source of truth for *what* to build: [speed_reading_app_functional_spec.md](speed_reading_app_functional_spec.md).
This document is the *how* and the *order*. We execute **stage by stage**: build → verify → correct → next.

> **v2 changes (review feedback integrated):**
> 1. Book text is stored as a **file on disk**, not inside the Hive record; `words[]` is **not persisted** — re-tokenized on open.
> 2. Tokenizer output format (structured tokens with sentence/paragraph boundaries) is **locked at Stage 3**, before the engine needs it.
> 3. Reader timing uses a **one-shot self-rescheduling timer** against an ideal schedule, not `Timer.periodic`.
> 4. Helper text renders **per-paragraph lazily** — moved from Stage 7 "polish" into Stage 5 core scope.
> 5. EPUB parsing gets an explicit **fallback path** (epubx is semi-abandoned); Syncfusion **license condition** recorded.
> 6. Minor: colors persisted as int, 5s-skip snaps to group boundary, idempotent seeding, `flutter_colorpicker` dependency deferred to Stage 6.

## Locked technical decisions

| Decision | Choice |
|---|---|
| Framework | Flutter 3.41.6 / Dart 3.11.4 (`/home/eijao/langs/.flutter-sdk/bin/flutter`) |
| State management | Riverpod (`flutter_riverpod`) |
| Persistence — book metadata + progress | **Hive CE** (`hive_ce` + `hive_ce_flutter`, codegen via `hive_ce_generator` + `build_runner`) — original `hive`/`hive_generator` is abandoned and its `analyzer <7` ceiling is incompatible with Dart 3.11; Hive CE is the maintained drop-in fork |
| Persistence — book text | Plain `.txt` file per book in app documents dir (`path_provider`), loaded lazily |
| Persistence — settings | `shared_preferences` (JSON; colors serialized as `int` via `color.value`) |
| Tokenization | **Not persisted.** Re-tokenized on book open (tens of ms for 100k words — cheaper than serializing) |
| Reader timing | One-shot `Timer` rescheduled against an ideal-schedule timestamp (no `Timer.periodic` drift) |
| Target platforms | Android, iOS |
| Theme | Light + Dark + System (both, user-switchable) |

### Package shortlist (pinned at scaffolding)

| Purpose | Package | Notes |
|---|---|---|
| State | `flutter_riverpod` | |
| DB | `hive_ce`, `hive_ce_flutter`, `hive_ce_generator` (dev), `build_runner` (dev) | Metadata only — no full text in boxes. CE fork (original Hive abandoned, breaks on Dart 3.11) |
| Settings | `shared_preferences` | |
| File picking | `file_picker` | |
| Paths | `path_provider`, `path` | Also used for book text files |
| EPUB parsing | `epubx` | ⚠️ Semi-abandoned; expect failures on non-standard manifests. Fallback: unzip via `archive` + manual XHTML strip (see Stage 3) |
| PDF text extraction | `syncfusion_flutter_pdf` | ⚠️ Community license: free only while revenue < $1M/yr; requires registration. Acceptable for this project — recorded here so it's not a surprise later |
| DOCX text extraction | `docx_to_text` (pure Dart) | |
| TXT / MD / HTML / RTF | manual (dart:io + small helpers) | |
| Color picker | `flutter_colorpicker` | **Added at Stage 6**, not at scaffolding — it's the only consumer; keeps early builds lean |
| IDs | `uuid` | |

> PDF for scanned/image pages (OCR) is explicitly **out of MVP** per spec §1.

---

## Storage architecture (v2 decision)

A 100k+ word book stored as `plainText` + `words[]` inside one Hive record means two full copies of the text read into memory whenever the box opens — the library list would pull megabytes just to render titles. Therefore:

```text
Hive box "books"  →  BookMeta { id, title, author, format, sourceFilePath,
                                textFileName, totalWords, currentWordIndex,
                                progress, addedAt, lastOpenedAt, coverImagePath? }

App documents dir →  books/<id>.txt        (clean extracted plain text)
                     covers/<id>.png       (optional cover)

In memory only    →  TokenizedText          (built on reader open, never persisted)
```

Rules:

- Library screen reads **only** the Hive box — cheap, instant.
- Reader open: read `books/<id>.txt` → tokenize → build `TokenizedText`.
- Remove book: delete Hive record **and** its text/cover files.
- `totalWords` is computed once at import and stored in meta (so the library can show it without loading text).

---

## Tokenizer contract (locked at Stage 3, consumed by Stage 4+)

`List<String>` is not enough — the engine needs sentence/paragraph jumps and the helper view needs per-paragraph rendering. The tokenizer produces one structure used everywhere:

```text
TokenizedText {
  words: List<String>                  // flat word list, index = global word index
  sentenceStarts: List<int>            // word indices where sentences begin (sorted)
  paragraphStarts: List<int>           // word indices where paragraphs begin (sorted)
  paragraphs: List<ParagraphSpan>      // { startWordIndex, endWordIndex } per paragraph
}
```

- Sentence/paragraph jump = binary search over `sentenceStarts` / `paragraphStarts`.
- Helper view renders paragraph N by slicing `words[span.start..span.end]`.
- This format is **fixed here** so Stage 4 (engine) and Stage 5 (UI) build against it without rework.

---

## Stage map (overview)

| Stage | Title | Outcome |
|---|---|---|
| 0 | Scaffolding & infra | Runnable empty app, deps, theme, Hive+Riverpod boot |
| 1 | Domain models & storage | BookMeta / ReaderSettings / ReaderState + Hive adapters + StorageService (meta + text files) + settings provider |
| 2 | Library screen (seeded data) | Library UI with cards, search, continue-reading — fed by seeded data |
| 3 | Add-book flow, parsers & tokenizer | File picker + TXT/EPUB/PDF/DOCX → clean text file + meta; **TokenizedText contract implemented & tested** |
| 4 | Reader engine (pure logic) | Drift-free timer engine, central-letter calc, time estimator — provider-driven, no UI |
| 5 | Reader screen UI | Split view: focus word + **lazy per-paragraph helper** + progress/time + controls + helper toggle |
| 6 | Settings & color screens | Main settings + dedicated color settings screen, all live-applied |
| 7 | Persistence wiring & polish | Save/resume per book, book details, rename/remove/reset, last-opened, exit-save |

Each stage below lists: **scope**, **files touched**, **deliverable**, **verify**.

---

## Stage 0 — Scaffolding & infrastructure

**Scope**
- `flutter create` with org id, Android + iOS only.
- Add pinned dependencies to `pubspec.yaml` (**without** `flutter_colorpicker` — deferred to Stage 6).
- Create the `lib/` folder skeleton from spec §10.
- App shell: `ProviderScope` in `main.dart`, `MaterialApp` in `app.dart` with light/dark/system theming wired to a `ThemeMode` provider (stub).
- Initialize Hive in `main()` (`Hive.initFlutter()`), open boxes lazily later.
- Centralized `AppTheme` (light + dark `ThemeData`) and app-color palette placeholder.
- Trivial placeholder home screen ("Library — coming soon") so the app runs.

**Files**
- `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/theme/app_theme.dart`, empty dirs `models/ screens/ widgets/ services/ utils/`, `android/`, `ios/`.

**Deliverable:** app builds and launches showing a placeholder screen; light/dark follows system.

**Verify**
- `flutter pub get` clean, `flutter analyze` clean.
- App runs on Android emulator (or `flutter run` device) without errors.
- Toggling system dark mode flips app theme.

---

## Stage 1 — Domain models & storage layer

**Scope**
- `BookMeta` model (replaces fat `Book` from spec §2 schema — see *Storage architecture* above): `id, title, author, sourceFilePath, format, textFileName, totalWords, currentWordIndex, progress, addedAt, lastOpenedAt, coverImagePath?`.
  - **No `plainText`, no `words[]` in the Hive record.** Text lives in `books/<id>.txt`; tokens are runtime-only.
- `ReaderSettings` model (spec §5): `wordsPerMinute, fontFamily, fontSize, wordsPerEntry, showHelperText`, plus color fields (spec §5E): currentWordColor, centralLetterColor, guideLineColor, helperHighlightColor, backgroundColor, focusBackgroundColor, progressBarColor, and `themeMode`.
  - JSON serialization stores every color as `int` (`color.value`) and rebuilds via `Color(value)`.
- `ReaderState` model (spec §7): `bookId, currentWordIndex, isPlaying, wordsPerMinute, wordsPerEntry, elapsedTime, estimatedTimeLeft` (runtime, not all persisted).
- Hive `TypeAdapter`s via codegen for `BookMeta` (+ enums as needed).
- `StorageService`:
  - `books` box CRUD (add/get/getAll/update/remove), update progress.
  - **Text file I/O:** `writeBookText(id, text)`, `readBookText(id)`, `deleteBookFiles(id)` under `path_provider` documents dir.
  - Remove = Hive record + text file + cover file, atomically as far as practical.
- `SettingsService`: load/save `ReaderSettings` via `shared_preferences` (JSON-encoded), defaults from spec (300 WPM, font 32, 1 word/entry, helper on).
- Riverpod providers: `booksProvider` (list, refreshable), `settingsProvider` (StateNotifier, live), `themeModeProvider`.

**Files**
- `lib/models/book_meta.dart` (+ `.g.dart`), `lib/models/reader_settings.dart`, `lib/models/reader_state.dart`, `lib/services/storage_service.dart`, `lib/services/settings_service.dart`, `lib/providers/*.dart`.

**Deliverable:** models + persistence usable from anywhere; settings survive app restart; book text round-trips through disk.

**Verify**
- `build_runner` generates adapters cleanly.
- Unit test: write BookMeta + text file, reopen, read both back equal; remove deletes both.
- Unit test: settings (incl. a non-default color) survive provider-container restart; color round-trips through int.
- `flutter analyze` clean.

---

## Stage 2 — Library screen (with seeded data)

**Scope** (spec §1)
- `LibraryScreen`: header (app name + settings shortcut), search bar, "Continue reading" section (last opened book), known-books grid/list, Add-book FAB.
- `BookCard` widget: cover/title/author/progress bar/last-opened — rendered **from BookMeta only**, no text loading.
- Card actions menu: Open / Details / Remove / Rename / Reset progress (wire Remove/Rename/Reset to StorageService now; Open routes to a stub reader).
- Local search: filter by title/author/file name.
- Seed 1–2 bundled sample `.txt` books on first run.
  - **Idempotent:** a `seeded=true` flag in `shared_preferences` guards against duplicate seeding on every launch; re-seeding also skipped if a book with the same seed id exists.

**Files**
- `lib/screens/library_screen.dart`, `lib/widgets/book_card.dart`, `lib/services/seed_service.dart`, asset `assets/sample/*.txt`, navigation setup.

**Deliverable:** functional library browsing over real Hive data (seeded), all card actions work except Open (stub).

**Verify**
- Search filters live.
- Remove/Rename/Reset mutate Hive and UI updates; Remove also deletes the text file.
- Continue-reading shows most-recent `lastOpenedAt`.
- Cold-restart twice: seed books appear exactly once.

---

## Stage 3 — Add-book flow, parsers & tokenizer

**Scope** (spec §1, §2)
- `BookImportService`: pick file (`file_picker`), detect format, route to parser, produce clean text + metadata, **write text file + BookMeta** (compute `totalWords` once here), dedupe-check, store.
- `TextParserService` with per-format extractors:
  - TXT / MD: raw read (+ strip markdown for MD optionally).
  - HTML / RTF: strip tags/markup to plain text.
  - EPUB: `epubx` → concatenate chapter text, pull title/author/cover.
    - **Fallback path:** if `epubx` throws or yields empty text, unzip via `archive`, read `content.opf` spine order, strip XHTML per chapter manually. Budget extra time here — real-world EPUBs are messy; any file failing both paths surfaces the "File unreadable" state, never a crash.
  - PDF: `syncfusion_flutter_pdf` text extraction; if no extractable text → "No extractable text" state.
  - DOCX: `docx_to_text`.
- `word_tokenizer.dart`: implements the **TokenizedText contract** (see above) — flat `words`, `sentenceStarts`, `paragraphStarts`, `paragraphs` spans. This is the single tokenization code path for import (word count) and reader (runtime).
- Import states UI (spec §2): loading/parsing, success, unsupported, unreadable, no-text, duplicate.
- MVP priority order honored: TXT + EPUB first-class; PDF + DOCX included; HTML/RTF/MD best-effort.

**Files**
- `lib/services/book_import_service.dart`, `lib/services/text_parser_service.dart`, `lib/utils/word_tokenizer.dart` (+ `lib/models/tokenized_text.dart`), `lib/screens/add_book_*` (modal or screen + states).

**Deliverable:** real import of TXT/EPUB/PDF/DOCX → book appears in library with correct word count; tokenizer contract frozen and tested.

**Verify**
- Import one sample of each format; word counts sane; text clean (no tag soup).
- Import a deliberately malformed EPUB → fallback parses it or "unreadable" state shows (no crash).
- Unsupported extension → correct error state.
- Re-importing same file → duplicate detected.
- Unit tests on tokenizer: word splitting, sentence boundaries (abbreviations like "т.д.", "Mr." don't split), paragraph spans cover all words with no gaps/overlaps.

---

## Stage 4 — Reader engine (pure logic, no UI)

**Scope** (spec §3, §4, §8)
- `central_letter_calculator.dart`: index by word length (1→0, 2–5→1, 6–9→2, 10+→3/4).
- `time_estimator.dart`: `progress`, `timePassed` (session-based), `estimatedTimeLeft = remainingWords / WPM`; WPM always = actual words/min even when wordsPerEntry > 1 (spec §8 note).
- `reader_engine.dart`: the playback engine.
  - Holds current entry index (group of `wordsPerEntry` words), play/pause.
  - **Drift-free ticking:** no `Timer.periodic`. On play, record `scheduleAnchor = now`; each tick schedules a one-shot `Timer` for `anchor + (n+1) * msPerEntry - now`, so error never accumulates (matters at 600+ WPM where msPerEntry ≈ 100 ms). `msPerEntry = 60000 / WPM * wordsPerEntry`.
  - Changing WPM / wordsPerEntry mid-play: cancel pending timer, re-anchor schedule at current position, continue — cadence changes on the very next tick.
  - Navigation: word/sentence/paragraph prev-next (binary search over `sentenceStarts`/`paragraphStarts` from TokenizedText), back/forward 5s (= 5 × WPM/60 words, **snapped to the current group boundary** so the helper highlight never straddles groups), restart, seek-to-fraction, jump-to-word-index (also group-snapped).
  - Tracks elapsed session time; exposes current word index, current group span (for helper highlight).
- Riverpod `readerEngineProvider` (family by bookId) exposing immutable `ReaderState` snapshots.

**Files**
- `lib/services/reader_engine.dart`, `lib/utils/central_letter_calculator.dart`, `lib/utils/time_estimator.dart`, `lib/providers/reader_provider.dart`.

**Deliverable:** engine fully drivable from tests; emits correct word at correct cadence with no cumulative drift.

**Verify**
- Unit tests: central-letter table; ms-per-entry math; 5s skip math incl. group snapping; sentence/paragraph boundary jumps; estimated-time-left.
- Drive engine with `fake_async` for N ticks at 300 WPM → expected indices; simulate 10 min at 600 WPM → cumulative drift below one tick.
- Change WPM mid-run in test → next tick lands on new cadence.

---

## Stage 5 — Reader screen UI

**Scope** (spec §3, §4, §5F)
- `ReaderScreen` split layout: top focus 50% / bottom helper 50%; when `showHelperText=false` focus is full screen (progress + time stay).
- `FocusWordView`: centered current word/group, central letter highlighted (color from settings), guide lines above/below, top info row (WPM, words-per-entry, font size).
- `HelperTextView` — **lazy per-paragraph rendering (core scope, not polish):**
  - Never one giant `RichText` over the whole book — thousands of `TextSpan`s rebuilt 5×/sec would kill frame rate.
  - `ListView.builder` keyed by paragraph (from `TokenizedText.paragraphs`); each item is one paragraph's `RichText`.
  - Only the paragraph containing the active group rebuilds on tick (select via Riverpod so other paragraphs don't re-render).
  - Highlight spans the full active group (color from settings, yellow default).
  - Auto-scroll keeps the active paragraph visible (scroll-to-index by paragraph; smooth within view).
  - Tap word → `jumpToWord` (per-paragraph hit-testing keeps `TapGestureRecognizer` count bounded).
- `ReaderProgressBar` + time-left (left) / time-passed (right).
- `ReaderControls`: play/pause, restart, back-5s, fwd-5s, prev/next sentence, seek slider, exit (saves position).
- Quick settings modal entry point (filled in Stage 6).

**Files**
- `lib/screens/reader_screen.dart`, `lib/widgets/focus_word_view.dart`, `lib/widgets/helper_text_view.dart`, `lib/widgets/reader_progress_bar.dart`, `lib/widgets/reader_controls.dart`.

**Deliverable:** open a book → speed-read end to end with both panes working, smooth on a 100k-word book.

**Verify**
- Play/pause, all jumps, slider seek, tap-to-jump in helper all move both panes in sync.
- Helper auto-scrolls; toggle hides it and focus goes full-screen.
- Central letter visibly highlighted at the right index across word lengths.
- **Perf check:** load a 100k+ word book, play at 600 WPM with helper visible — no visible jank (spot-check with DevTools frame chart; only the active paragraph rebuilds).

---

## Stage 6 — Settings & color screens

**Scope** (spec §5)
- **Add `flutter_colorpicker` dependency now** (deferred from Stage 0).
- `SettingsScreen`: WPM (slider + numeric input, 100–1000), font type dropdown (System/Serif/Sans/Mono), font size slider (16–72), words-per-entry segmented (1–5), helper toggle, theme mode (light/dark/system), link to color screen.
- `ColorSettingsScreen`: rows for current-word / central-letter / guide-line / helper-highlight / background / focus-background / progress-bar colors, each opens `flutter_colorpicker`; "Reset to default".
- `QuickReaderSettingsModal`: subset (WPM, words-per-entry, font size, helper toggle) reachable from reader, applies live.
- `setting_row.dart` shared widget.
- All changes flow through `settingsProvider` → live re-render of library/reader (engine re-anchors cadence per Stage 4).

**Files**
- `lib/screens/settings_screen.dart`, `lib/screens/color_settings_screen.dart`, `lib/widgets/setting_row.dart`, quick-settings modal in reader.

**Deliverable:** every setting in spec §5 adjustable, persisted, and live-applied.

**Verify**
- Change WPM mid-read → cadence changes on next tick.
- Colors change focus/helper/guides live; reset restores defaults; custom colors survive restart (int round-trip).
- Theme mode switch works; settings survive restart.

---

## Stage 7 — Persistence wiring & polish

**Scope** (spec §1, §7)
- On reader exit / app pause (`AppLifecycleState.paused`): persist `currentWordIndex`, progress %, time spent, `lastOpenedAt` to BookMeta.
- On reopen: read text file, tokenize, resume at saved word index (snapped to group boundary).
- `BookDetailsScreen`: metadata, progress, actions (open/rename/remove/reset).
- Continue-reading + progress bars reflect saved state across restarts.
- Edge handling: empty library, parse failures surfaced, missing/corrupt text file for an existing meta record (offer re-import or remove).
- Final `flutter analyze` clean, manual QA pass against spec §11 narrative.

**Files**
- `lib/screens/book_details_screen.dart`, lifecycle hooks in `reader_screen.dart` / `app.dart`, StorageService progress methods.

**Deliverable:** full MVP per spec §9, progress durable per book.

**Verify**
- Read halfway, exit, kill app, reopen → resumes exact position; library shows correct progress + last-opened.
- Kill app mid-playback (lifecycle pause path) → position still saved.
- Delete the text file manually, open book → graceful error, no crash.
- Walk the spec §11 user story start to finish.

---

## Known risks register

| Risk | Mitigation | Stage |
|---|---|---|
| `epubx` fails on real-world EPUBs | `archive` + manual XHTML fallback; "unreadable" state as last resort | 3 |
| Syncfusion license terms change / revenue threshold | Recorded; swap to `pdf_text`-class package or drop PDF if ever needed | 3 |
| Timer drift at high WPM | One-shot rescheduling against ideal schedule; drift test in CI | 4 |
| Helper view jank on long books | Per-paragraph `ListView.builder`, single-paragraph rebuilds; perf gate in Stage 5 verify | 5 |
| Hive record bloat | Text on disk, tokens runtime-only; meta-only box | 1 |

## Working agreement

- One stage at a time. After each: I report what's done + how to verify; you check; we correct; then next.
- Spec is source of truth; deviations get flagged before coded. **Deviation already flagged & accepted:** spec §2 `Book` schema's `plainText`/`words[]` fields are realized as a disk file + runtime tokens, not Hive fields (see *Storage architecture*).
- `flutter analyze` clean is a gate between stages; tokenizer/engine unit tests are a gate for Stages 3–4; perf check is a gate for Stage 5.
- No premature features (OCR, cloud sync, mobi/azw, custom fonts, per-section font sizes) — explicitly post-MVP per spec §9.