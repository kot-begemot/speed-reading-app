# PDF-native reading — implementation plan

Read PDFs **without reflowing them into plain text**: keep the original file, render the
actual page (layout + images) in the bottom section, and highlight the currently-active
word on the page while the top focus reader does RSVP as usual.

Companion to the main [IMPLEMENTATION_PLAN.md](../IMPLEMENTATION_PLAN.md). Built stage by
stage: build → verify → correct → next.

## Locked decisions (the "simplest & fastest" path)

| Decision | Choice |
|---|---|
| PDF library | **`pdfrx`** (already added, `^2.4.4`) — one package that both renders pages (`PdfPageView`) AND exposes text with rects (`PdfPage.loadText()` → `PdfPageText.fragments` / `charRects`) in the **same coordinate space**. Avoids reconciling two libraries' coordinates. |
| Word boxes | Computed **on the fly when the book opens**. No sidecar cache in v1 (revisit only if large PDFs feel slow). |
| Default behavior | PDFs open in **page-view mode** by default. The existing text-reflow parse becomes a **fallback** used only when the PDF has no text layer. No per-import toggle in v1. |
| Book identity | No new model "kind". Reuse `format == 'pdf'`; the reader branches on it. The **original `.pdf`** is kept on disk (instead of an extracted `.txt`). |
| Engine | **Unchanged.** `ReaderEngine` only needs a word list + sentence/paragraph starts. We give it those; each word additionally carries `(pageNumber, rect)` for the page overlay. |

> `pdfrx` pulls a native rendering engine (`pdfrx_engine`) — bumps build size and adds a
> platform dependency. Accepted for this feature.

## What stays vs changes

- **Unchanged:** focus reader (RSVP), controls, progress/time, settings, the whole engine.
- **Changes:** for `format == 'pdf'` books, the bottom **helper** is a rendered PDF page
  with a highlight overlay instead of the reflowed `RichText` paragraph list.

---

## Stage 0 — Spike / de-risk (THROWAWAY, do first)

The whole feature hinges on three uncertain things; prove them before building UI.

**Scope**
- Load a real text-layer PDF with `pdfrx`, `loadText()` a page, and inspect `fragments` +
  `charRects`: confirm we can assemble **words in reading order** with a bounding `PdfRect`
  each. (pdfrx already segments fragments; verify quality.)
- Render the page with `PdfPageView` and draw a test rectangle over a known word, proving
  the **coordinate mapping**: PDF points → widget pixels (`scale = renderedSize / page size`)
  and the **Y-axis flip** (PDF origin bottom-left vs Flutter top-left). Use
  `toRectInDocument` if it fits.
- Note reading-order quality on a 1-column and a 2-column page.

**Deliverable:** a scratch screen that renders page 1 and highlights word #K at the right
spot, with a printed ordered word list.

**Verify:** highlight visually sits on the correct word; word order matches reading order
on a simple PDF. If reading order/coords are unworkable, stop and reconsider here (cheapest
place to bail).

---

## Stage 1 — PDF word index service

**Scope**
- `PdfWordIndex` model: `words: List<String>`, `sentenceStarts`, `paragraphStarts`,
  `paragraphs` (so it satisfies what the engine + nav need, mirroring `TokenizedText`),
  PLUS `boxes: List<PdfWordBox>` where `PdfWordBox { int pageNumber; Rect rect; }` aligned
  1:1 with `words`.
- `PdfTextIndexer`: open the PDF via pdfrx, iterate pages in order, `loadText()`, group
  fragments → words, append to the flat list with page+rect. Derive sentence boundaries
  from terminal punctuation (reuse `WordTokenizer._endsSentence` logic — extract it to a
  shared helper) and paragraph boundaries from large vertical gaps / new pages.
- Store rects in **page-local PDF coordinates**; map to pixels at render time.

**Files:** `lib/models/pdf_word_index.dart`, `lib/services/pdf_text_indexer.dart`; small
refactor exposing the sentence-end predicate from `word_tokenizer.dart`.

**Deliverable:** given a PDF path, an in-memory index of ordered words + page/rect +
sentence/paragraph starts.

**Verify:** unit test — generate a small PDF with Syncfusion (we already do this in tests),
read it back with the indexer, assert word count, that words are ordered, and that boxes
carry sane page numbers + non-empty rects.

---

## Stage 2 — Reader session for PDF books

**Scope**
- Extend `readerSessionProvider` (or add a sibling) so that for `format == 'pdf'` it builds
  the `PdfWordIndex` (Stage 1) and feeds the **same `ReaderEngine`** a `TokenizedText`
  assembled from the index's words/sentence/paragraph starts. The session also exposes the
  `boxes` + the opened `PdfDocument` (pdfrx) for rendering.
- Keep one open `PdfDocument` per session; dispose on teardown (alongside engine dispose).
- Resume position works unchanged (word index persists in `BookMeta`).

**Files:** `lib/providers/reader_provider.dart` (branch), maybe a `PdfReaderSession` variant
of `ReaderSession`.

**Deliverable:** opening a PDF book yields a running engine + a live pdfrx document + the
word→box index.

**Verify:** provider test — open a generated PDF book, engine resumes at saved index, boxes
list length == word count.

---

## Stage 3 — PDF page-view helper (render + highlight overlay)

**Scope** — the visible payoff.
- `PdfHelperView` widget replacing the helper for PDF books:
  - `PdfPageView` showing the page of the **active word** (from `engine.state` →
    `currentWordIndex` → `boxes[i].pageNumber`).
  - A `Stack` overlay drawing the highlight rect for the active group, mapping each
    `PdfWordBox.rect` (PDF points) to the rendered page rect (scale + Y-flip), colored from
    `settings.helperHighlightColor`.
  - **Auto-flip:** when the active word's page changes, swap the rendered page.
  - **Tap-to-jump:** hit-test the tap against `boxes` on the current page → `jumpToWord`.
- Wire `ReaderScreen` to branch: `format == 'pdf'` → `PdfHelperView`; else current
  `HelperTextView`. Landscape/portrait split logic stays (page view goes where the helper
  panel is).

**Files:** `lib/widgets/pdf_helper_view.dart`, branch in `lib/screens/reader_screen.dart`.

**Deliverable:** open a PDF, press play — the focus reader advances; the bottom shows the
real page (images and all) with the current word boxed; pages flip as reading crosses them.

**Verify (device):** highlight tracks the active word; tapping a word jumps both panes;
page flips at boundaries; images render. Spot-check a 2-column PDF for order sanity.

---

## Stage 4 — Import wiring (PDF stored natively)

**Scope**
- `BookImportService`: for `.pdf`, **store the original file** at `books/<id>.pdf` and set
  `format == 'pdf'`; compute `totalWords` from the Stage-1 index.
- If the PDF has **no text layer** (index empty), fall back to the current behavior — try
  the text parse; if that's also empty, the existing "No extractable text" state (OCR stays
  out of scope, but now the failure is explicit).
- `StorageService`: generalize text I/O so a book's payload can be `<id>.pdf` (binary) as
  well as `<id>.txt`. Removal deletes whichever exists.

**Files:** `lib/services/book_import_service.dart`, `lib/services/storage_service.dart`.

**Deliverable:** importing a PDF produces a page-view book end to end.

**Verify:** import a text-layer PDF → opens in page mode; import an image-only PDF → clean
"no extractable text" message.

---

## Stage 5 — Polish, perf, edges

**Scope**
- Page-image **cache** for current ± 1 page (pdfrx may handle this; verify no re-render
  thrash on every tick — only re-render on page change, not per word).
- Highlight overlay updates per word without re-rendering the page image.
- Big-PDF perf check (open time, memory, smooth playback).
- URL-imported PDFs (the `importUrl` PDF branch) route into the same native path if we keep
  the bytes.
- Tests where practical (indexer grouping, coordinate-mapping math as a pure function).

**Deliverable:** smooth, durable PDF page reading; MVP of the feature complete.

**Verify:** play a multi-page text PDF at 400 WPM — no jank, correct page flips, highlight
always on the right word; resume across restart lands on the right page.

---

## Risks

| Risk | Mitigation | Stage |
|---|---|---|
| Reading order wrong on multi-column / complex layouts | Prove on real PDFs in the spike; document as a known limitation; engine still plays in pdfrx's order | 0 |
| Coordinate mapping (scale + Y flip) fiddly | Isolate as a pure, tested function; prove visually in the spike | 0/5 |
| pdfrx word segmentation too coarse/fine | Inspect in spike; if needed, regroup `charRects` into words ourselves | 0/1 |
| Per-tick page re-render = jank | Re-render only on page change; overlay redraw is cheap | 5 |
| No text layer (scanned PDFs) | Detect empty index → fall back to text parse → explicit no-text message; OCR out of scope | 4 |
| Native engine size/build | Accepted; documented | — |

## Out of scope (v1)

OCR for scanned PDFs; text selection/copy on the page; reflow toggle per book; caching the
word index to disk; non-PDF formats getting page-view.
