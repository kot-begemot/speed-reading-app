# Speed Reader

A cross-platform **speed-reading app** for Android and iOS, built with Flutter. Import a book, then read it one word (or small group of words) at a time in a fixed focus point — the classic RSVP (Rapid Serial Visual Presentation) technique — while the full text stays visible below and follows along.

---

## What it is & why

Most people read at ~200–300 words per minute, limited partly by eye movement across lines and by silently "pronouncing" each word. This app removes the line-scanning cost by flashing words in one place, with the **optimal-recognition letter highlighted** to anchor your eyes, so you can train yourself to read faster.

It also keeps the original text visible in a second panel that highlights the current word and auto-scrolls, so you never lose your place and can tap any word to jump there.

**Core idea:** open your library → add a book (TXT/EPUB/PDF/DOCX/…) → read it in the focus reader at an adjustable speed → your progress is saved per book and resumes where you left off.

The functional specification lives in [`speed_reading_app_functional_spec.md`](speed_reading_app_functional_spec.md); the staged build plan and architecture decisions are in [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md).

---

## Features

- **Library** — grid of books with cover/title/author/progress, search by title/author/file, a "Continue reading" shortcut, and per-book actions (open, details, rename, reset progress, remove).
- **Import** — pick a file and import it. Supported: `.txt`, `.md`, `.html`, `.rtf`, `.epub`, `.pdf`, `.docx`. Clean text is extracted (EPUB has a fallback parser; PDFs need selectable text — scanned/image PDFs are out of scope). Import states cover unsupported / unreadable / no-text / duplicate.
- **Focus reader** — current word/group centered between guide lines, with the optimal-recognition letter highlighted; live WPM / words-per-entry / font-size readout; time left / time passed; a draggable progress slider.
- **Helper panel** — the full text as paragraphs, the active word/group highlighted (yellow by default), auto-scrolled into view; tap any word to jump. Can be hidden to give the focus reader the full screen. Renders lazily per paragraph, so it stays smooth even on 100k-word books.
- **Controls** — play/pause, restart, back/forward 5 s, previous/next sentence, seek, tap-to-jump.
- **Settings** — reading speed (100–1000 WPM, slider + number), font family, font size (16–72), words per entry (1–5), helper toggle, light/dark/system theme, and a dedicated **color settings** screen (7 reader colors, each with a picker, plus reset). Quick settings are also reachable from inside the reader and apply live.
- **Persistence** — reading position, progress, and last-opened are saved per book and resume across app restarts (including being force-killed while reading).

---

## Tech stack

- **Flutter** 3.41.6 / **Dart** 3.11.4 — targets Android & iOS.
- **State management:** [Riverpod 3](https://riverpod.dev) (`flutter_riverpod`).
- **Persistence:** [Hive CE](https://pub.dev/packages/hive_ce) for book *metadata*; book *text* is stored as plain files on disk (loaded lazily); `shared_preferences` for settings.
- **Parsing:** `epubx` + `archive` (EPUB, with a manual fallback), `syncfusion_flutter_pdf` (PDF text), `docx_to_text` (DOCX), built-in strippers for HTML/RTF/Markdown.
- **UI:** `scrollable_positioned_list` (helper auto-scroll), `flutter_colorpicker` (color settings), `file_picker`, `path_provider`, `uuid`.

### Architecture highlights

- **Storage split** — the Hive box holds only `BookMeta` (title, author, progress, word count, …). The full text lives at `<app-documents>/books/<id>.txt` and is read + tokenized lazily when the reader opens; the tokenized word list is never persisted (re-tokenizing is cheaper than serializing). This keeps the library list and search instant even with large books.
- **Drift-free reader engine** — `ReaderEngine` (pure logic, no UI) advances words with a one-shot timer that re-schedules itself against an ideal timeline anchored at play time, so timing never drifts at high WPM. Its time source is injectable, which makes it fully testable with `fake_async`.
- **Tokenizer contract** — `WordTokenizer` produces one structure (`words`, sentence/paragraph start indices, paragraph spans) used everywhere: word counting at import, sentence/paragraph jumps in the engine, and per-paragraph rendering in the helper.

---

## Project structure

```
lib/
├── main.dart                 # boot: Hive + Riverpod + seed
├── app.dart                  # MaterialApp, theming
├── models/                   # BookMeta, ReaderSettings, ReaderState, TokenizedText
├── providers/                # Riverpod: books, settings, reader session
├── screens/                  # library, reader, settings, color settings, details, add-book flow
├── services/                 # storage, settings, seed, import, parsers, reader engine
├── utils/                    # tokenizer, central-letter, time estimator
├── theme/                    # app theme, reader colors
└── widgets/                  # book card, focus view, helper view, controls, progress bar, …

test/                         # unit + widget tests (see "Testing")
assets/sample/                # bundled sample books (seeded on first run)
speed_reading_app_functional_spec.md   # what to build
IMPLEMENTATION_PLAN.md                  # how it was built, stage by stage
```

---

## Prerequisites

- The **Flutter SDK** (3.41.x, stable channel). Verify with `flutter --version`.
- For Android: Android SDK + an emulator or a connected device.
- For iOS: Xcode + a simulator or device (macOS only).

Make sure `flutter` is on your `PATH` before running the commands below.

---

## Running the app

From the project root (`speed-reading-app/`):

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate Hive adapters (only needed after changing @HiveType models)
dart run build_runner build

# 3. Run on a connected device / running emulator
flutter run
```

### Launching an Android emulator

```bash
flutter emulators                       # list available emulators
flutter emulators --launch <emulator>   # start one by its id
flutter devices                         # confirm it shows up and note its device id
flutter run -d <device-id>
```

On first launch the library is seeded with two sample books so there's something to read immediately.

### Building release artifacts

```bash
flutter build apk            # Android APK
flutter build appbundle      # Android App Bundle (for Play)
flutter build ios            # iOS (macOS + Xcode required)
```

---

## Testing

The project has a unit/widget test suite (46 tests across 12 files) covering the
tokenizer, parsers (real PDF/DOCX/EPUB round-trips), the reader engine
(drift-free timing via `fake_async`, navigation, snapping), storage round-trips,
settings persistence, seeding idempotency, and the reader provider
(resume + persist-on-exit + missing-file handling).

```bash
# Run everything
flutter test

# Run a single file
flutter test test/reader_engine_test.dart

# With coverage
flutter test --coverage    # writes coverage/lcov.info
```

Static analysis (kept clean as a gate between features):

```bash
flutter analyze
dart format --set-exit-if-changed lib test   # formatting check
```

### Manual verification on a device

The reading experience and persistence are easiest to confirm by hand:

1. `flutter run`, open a book, press play — words advance at the set WPM, the
   helper panel highlights and auto-scrolls.
2. Open **Settings** → change speed/theme/colors → see them apply live.
3. Read partway, exit the reader, fully close the app, reopen it and open the
   same book — it resumes exactly where you left off.

---

## Known limitations (post-MVP)

These are intentionally out of the first version (see the spec's MVP scope):

- OCR for scanned/image-only PDFs.
- `.mobi` / `.azw` formats.
- Cloud sync between devices.
- Custom imported fonts and separate focus/helper font sizes.
- EPUB cover extraction (covers currently show a placeholder).

### Open design question

The "central letter" highlight currently follows the spec's **rule table**
(`reading` → highlight index 2). The spec's worked *example* shows index 3
(`rea[D]ing`), which contradicts the table. The behavior is a one-line change in
[`lib/utils/central_letter_calculator.dart`](lib/utils/central_letter_calculator.dart)
if the examples are preferred over the table.
