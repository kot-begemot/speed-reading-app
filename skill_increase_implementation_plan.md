# Implementation Plan: Level-Based Skill Unlocking & Settings Override

This plan outlines the design and implementation for restricting access to the standalone "Skills" drills based on the user's active level in the Training Program, with a settings override for developer/power-user flexibility.

## Justification & Benefits (Why this makes sense)

Speed reading is a physical and cognitive skill that requires conditioning visual muscles and processing capabilities in a specific sequence. Allowing users to practice advanced drills without foundational training can lead to frustration and poor habits.

Here is the proposed pedagogical mapping:

1. **Level 1 (Foundational Focus)**: 
   * **Schulte Table** & **Visual Word Match**: Trains basic eye stabilization, central focus, and shape-pattern recognition.
2. **Level 2 (Visual Span Expansion)**: 
   * **Number Tracking** & **Pyramid Expansion**: Encourages vertical and horizontal eye-span widening and sequence tracking.
3. **Level 3 (Advanced Visual Coordination)**: 
   * **Schulte-Gorbov Table** & **Peripheral Vision**: Introduces higher mental switching load and recognition at extreme horizontal bounds.
4. **Level 4+ (Cognitive Reading & Chunking)**: 
   * **Flash Recognition** & **Chunk Reading**: Challenges the brain to read and comprehend multi-word chunks in milliseconds.

### Design Decisions:

* **Training Level Alignment**: Tying unlocks to the Training Program Level aligns the standalone library with the core curriculum.
* **Settings Bypass**: A "Unlock all skills" setting is added under a new "Developer / Trainer Options" section. This allows developers to test advanced screens easily and lets advanced users bypass the locking system entirely.
* **Friendly UX**: When tapping a locked skill, the app will show a helpful dialog/bottom sheet explaining how to unlock it, encouraging the user to progress in their program.

---

## Proposed Changes

### Core Models & State Management

#### [MODIFY] [reader_settings.dart](file:///Users/a/Desktop/Projects/Apps/speed-reading-app/lib/models/reader_settings.dart)
* Add `unlockAllSkills` boolean flag (defaults to `false`).
* Update `copyWith`, `toJson`, and `fromJson` methods to serialize and deserialize this value.

#### [MODIFY] [settings_provider.dart](file:///Users/a/Desktop/Projects/Apps/speed-reading-app/lib/providers/settings_provider.dart)
* Add a `setUnlockAllSkills(bool)` mutation helper inside `SettingsNotifier`.

---

### User Interface Settings

#### [MODIFY] [settings_screen.dart](file:///Users/a/Desktop/Projects/Apps/speed-reading-app/lib/screens/settings_screen.dart)
* Add a new section `TRAINER OPTIONS` below "Interface & Theme".
* Add a toggle tile `Unlock all skills` ("Bypass level locks for practice drills").

---

### Training Screens & Cards

#### [MODIFY] [exercise_card.dart](file:///Users/a/Desktop/Projects/Apps/speed-reading-app/lib/widgets/trainer/exercise_card.dart)
* Accept an optional `unlockLevel` integer to display descriptive lock text (e.g. `LOCKED (LVL 2)` or `UNLOCK AT LVL 2` in the chip).
* If locked, change the action button style to show a lock icon or a locked state rather than a call-to-action button, and apply a muted visual style.

#### [MODIFY] [skill_training_screen.dart](file:///Users/a/Desktop/Projects/Apps/speed-reading-app/lib/screens/trainer/skill_training_screen.dart)
* Add `unlockLevel` (integer) metadata to `_DrillDef`.
* Watch `trainerProfileProvider` and `settingsProvider` to determine the user's level and check if the locks should be active.
* Evaluate drill lock state: `isLocked = !unlockAllSkills && (userLevel < drill.unlockLevel)`.
* If locked, pass `ExerciseStatus.locked` to `ExerciseCard`.
* Update the `_start` method: if a drill is locked, display a dialog detailing the required level and encouraging the user to do their Program training.

---

## Verification Plan

### Automated Tests
* Run `flutter test` to ensure no regressions in settings serialization:
```bash
flutter test
```

### Manual Verification
1. **Initial State (Level 1)**:
   * Navigate to **Skill Training**.
   * Verify *Schulte Table* and *Visual Word Match* are unlocked.
   * Verify other drills (e.g., *Chunk Reading*, *Peripheral Vision*) are locked and display their corresponding unlock levels.
   * Verify that tapping a locked drill shows the dialog explaining that it requires Level X.
2. **Toggle Bypass**:
   * Go to **Settings** and toggle **Unlock all skills** to active.
   * Return to **Skill Training**.
   * Verify all drills are now unlocked and can be launched immediately.
3. **Program Progression**:
   * Complete enough sessions to level up the profile to Level 2.
   * Verify *Number Tracking* and *Pyramid Expansion* automatically unlock without the bypass toggle enabled.
