# Speed Reading App Functional Spec

## 1. Main Screens

### A. Library Screen

This is the first screen users see.

**Purpose:** Show available books and allow users to search, open, or add a new book.

**Main elements:**

| Area | Functionality |
|---|---|
| Header | App name, settings shortcut |
| Search bar | Search local library by title, author, file name |
| Known books library | List/grid of built-in or previously added books |
| Add book button | Import a new file from device/cloud |
| Book card | Cover/title/author/progress/last opened date |
| Continue reading section | Shows the last active book |

**Book card actions:**

- Open reader
- View book details
- Remove from library
- Rename title
- Reset reading progress

**Supported text/book formats:**

The app should aim to support:

- `.txt`
- `.epub`
- `.pdf`
- `.docx`
- `.html`
- `.rtf`
- `.md`
- `.mobi` / `.azw` later if feasible

For MVP, prioritize:

1. TXT
2. EPUB
3. PDF
4. DOCX

PDF support should extract selectable text where possible. Scanned/image PDFs may require OCR later.

---

## 2. Add Book Flow

### Add Book Screen / Modal

**User flow:**

1. User taps **Add Book**.
2. App opens file picker.
3. User selects a supported file.
4. App parses the file into clean text.
5. App stores metadata and reading progress.
6. Book appears in the library.

**Import states:**

- Loading/parsing
- Success
- Unsupported format
- File unreadable
- No extractable text
- Duplicate book detected

**Stored book data:**

```text
Book {
  id
  title
  author
  filePath
  format
  plainText
  words[]
  currentWordIndex
  totalWords
  addedAt
  lastOpenedAt
  coverImage?
}
```

---

## 3. Reading Screen

The reading screen is split into two sections.

### A. Top Section — Speed Reading Focus View

This is the main speed reading area.

**Purpose:** Show the current word or word group in the center.

#### Layout

```text
 ------------------------------------------------
| Speed: 350 WPM       Words: 1       Font: 32   |
|                                                |
|                 ─────────────                  |
|                                                |
|                    rea[D]ing                   |
|                                                |
|                 ─────────────                  |
|                                                |
| Time left: 12:40        Time passed: 03:20     |
| [========== progress bar ==========-----]      |
 ------------------------------------------------
```

#### Required elements

| Element | Description |
|---|---|
| Current word | Displayed in the center |
| Central letter highlight | One letter highlighted to guide eye focus |
| Guide lines | Horizontal visual lines above and below the word |
| Speed info | Current WPM |
| Words per entry | Shows 1–5 words per display tick |
| Progress bar | At the bottom of the top reader section |
| Time left | Bottom-left |
| Time passed | Bottom-right |
| Play/pause controls | Start or pause speed reading |
| Previous/next controls | Jump backward/forward by word, sentence, or paragraph |

#### Central letter logic

The app should highlight the “optimal recognition point” of the word.

Basic rule:

```text
1-letter word  -> highlight character 0
2–5 letters    -> highlight character 1
6–9 letters    -> highlight character 2
10+ letters    -> highlight character 3 or 4
```

Examples:

```text
reading -> rea[D]ing
functionality -> fun[C]tionality
```

The highlight color should come from the color settings.

---

### B. Bottom Section — Full Text Helper View

This is the second split-screen section.

**Purpose:** Show the original text as normal reading text while highlighting the current word.

#### Required elements

| Element | Description |
|---|---|
| Full text | Displayed as normal paragraph text |
| Current word highlight | Current word highlighted in yellow by default |
| Auto-scroll | Keeps current word visible |
| Tap word | Jump speed reader to that word |
| Optional visibility | Can be disabled in settings |

#### Highlight behavior

The current word should be highlighted with a yellow background by default.

Example:

```text
The user can read faster by focusing on each [highlighted] word...
```

When using “Words per entry” greater than 1, highlight the full active group.

Example:

```text
The user can [read faster by] focusing...
```

---

## 4. Reader Controls

The reading screen should support:

| Control | Function |
|---|---|
| Play / Pause | Start or stop word playback |
| Restart | Go back to beginning |
| Back 5 seconds | Move backward based on WPM |
| Forward 5 seconds | Move forward based on WPM |
| Previous sentence | Jump to previous sentence |
| Next sentence | Jump to next sentence |
| Slider/progress drag | Jump to any point in the book |
| Tap word in helper text | Jump to that word |
| Exit reader | Save current position and return to library |

---

## 5. Settings

Settings should be accessible globally and from the reader screen.

### Main Settings Screen

| Setting | Type | Example |
|---|---|---|
| Words per minute speed | Slider + number input | 100–1000 WPM |
| Font type | Dropdown | System, Serif, Sans, Monospace |
| Font size | Slider | 16–72 |
| Words per entry | Segmented selector | 1, 2, 3, 4, 5 |
| Color selection | Opens dedicated color screen | Reader colors |
| Disable second helper screen | Toggle | On/off |

---

### A. Words Per Minute Speed

**Setting:** `wordsPerMinute`

Recommended range:

```text
Minimum: 100 WPM
Default: 300 WPM
Maximum: 1000 WPM
```

The app should calculate display interval like this:

```text
millisecondsPerEntry = 60000 / wordsPerMinute * wordsPerEntry
```

Example:

```text
300 WPM, 1 word per entry = 200 ms per word
300 WPM, 3 words per entry = 600 ms per group
```

---

### B. Font Type

**Setting:** `fontFamily`

Options:

- System default
- Serif
- Sans serif
- Monospace
- Custom imported font later

This applies to:

- Focus reader word
- Helper text section
- Book text display

---

### C. Font Size

**Setting:** `fontSize`

Recommended range:

```text
Minimum: 16
Default: 32 for focus reader
Maximum: 72
```

Separate font sizes could be useful later:

```text
focusFontSize
helperTextFontSize
```

For MVP, one font size setting is enough.

---

### D. Words Per Entry

**Setting:** `wordsPerEntry`

Options:

```text
1, 2, 3, 4, 5
```

This controls how many words are shown in the central reader at once.

Example:

| Setting | Display |
|---|---|
| 1 | `reading` |
| 2 | `reading speed` |
| 3 | `reading speed improves` |
| 4 | `reading speed improves with` |
| 5 | `reading speed improves with practice` |

The helper text should highlight the same word group.

---

### E. Color Selection Screen

This should be a dedicated screen opened from settings.

#### Color Settings

| Color option | Default |
|---|---|
| Current word color | Black/white depending on theme |
| Central letter highlight color | Red or orange |
| Guide line color | Gray |
| Helper text highlight color | Yellow |
| Background color | App theme background |
| Focus section background | Dark or light neutral |
| Progress bar color | Accent color |

#### Color Selection Screen Layout

```text
Color Settings

Current word color        [color preview]
Central letter color      [color preview]
Guide lines color         [color preview]
Helper highlight color    [color preview]
Background color          [color preview]
Progress bar color        [color preview]

[Reset to default]
```

Each row opens a color picker.

---

### F. Disable Second Helper Screen

**Setting:** `showHelperText`

Options:

```text
true / false
```

When enabled:

```text
Top section: 50%
Bottom section: 50%
```

When disabled:

```text
Focus reader takes full screen
```

The progress bar and time info stay visible in both modes.

---

## 6. App Navigation

Recommended navigation structure:

```text
LibraryScreen
 ├── BookDetailsScreen
 ├── AddBookFlow
 ├── ReaderScreen
 │    └── QuickReaderSettingsModal
 └── SettingsScreen
      └── ColorSettingsScreen
```

---

## 7. Reader State

The app should remember progress per book.

```text
ReaderState {
  bookId
  currentWordIndex
  isPlaying
  wordsPerMinute
  wordsPerEntry
  elapsedTime
  estimatedTimeLeft
}
```

When the user exits the reader, the app saves:

- Current word index
- Progress percentage
- Time spent
- Last opened timestamp

---

## 8. Progress and Time Calculation

### Progress

```text
progress = currentWordIndex / totalWords
```

### Time passed

Based on actual reading session time.

```text
timePassed = now - sessionStartTime
```

### Estimated time left

```text
remainingWords = totalWords - currentWordIndex
minutesLeft = remainingWords / wordsPerMinute
```

When `wordsPerEntry` is more than 1, WPM should still represent actual words per minute, not entries per minute.

---

## 9. Recommended MVP Scope

For the first working version, build:

1. Library screen
2. Import TXT and EPUB
3. Reader screen with split view
4. Current word display with highlighted central letter
5. Helper text with yellow current word highlight
6. WPM setting
7. Font size setting
8. Words per entry setting
9. Toggle to disable helper screen
10. Save reading progress

Then add PDF, DOCX, advanced colors, book metadata, and cloud sync later.

---

## 10. Suggested Flutter Component Structure

```text
lib/
 ├── main.dart
 ├── app.dart
 ├── models/
 │    ├── book.dart
 │    ├── reader_settings.dart
 │    └── reader_state.dart
 ├── screens/
 │    ├── library_screen.dart
 │    ├── reader_screen.dart
 │    ├── settings_screen.dart
 │    ├── color_settings_screen.dart
 │    └── book_details_screen.dart
 ├── widgets/
 │    ├── book_card.dart
 │    ├── focus_word_view.dart
 │    ├── helper_text_view.dart
 │    ├── reader_progress_bar.dart
 │    ├── reader_controls.dart
 │    └── setting_row.dart
 ├── services/
 │    ├── book_import_service.dart
 │    ├── text_parser_service.dart
 │    ├── reader_engine.dart
 │    └── storage_service.dart
 └── utils/
      ├── word_tokenizer.dart
      ├── time_estimator.dart
      └── central_letter_calculator.dart
```

---

## 11. Core Functionality Summary

The app should behave like this:

A user opens the app and sees their book library. They can search existing books or add a new one. After opening a book, the reading screen shows a speed-reading focus word in the upper section, with a highlighted central letter and guide lines. The bottom section shows the full original text with the active word highlighted in yellow. The user can control speed, font, font size, words per entry, colors, and whether the helper text section is visible. Reading progress, time passed, and estimated time left are always visible and saved per book.
