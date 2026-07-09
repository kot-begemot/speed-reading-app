import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/screens/trainer/schulte_runtime_screen.dart';
import 'package:speed_reading_app/screens/trainer/number_tracking_runtime_screen.dart';
import 'package:speed_reading_app/screens/trainer/peripheral_vision_runtime_screen.dart';
import 'package:speed_reading_app/screens/trainer/flash_recognition_runtime_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Schulte Table game loop verification', (tester) async {
    int? scoreValue;
    int? errorsValue;
    int? durationValue;

    await tester.pumpWidget(
      MaterialApp(
        home: SchulteRuntimeScreen(
          showIntro: false,
          onComplete: (score, errors, durationSecs) {
            scoreValue = score;
            errorsValue = errors;
            durationValue = durationSecs;
          },
        ),
      ),
    );

    // Initial state: starts at 1, timer is at 00:00
    expect(find.text('00:00'), findsOneWidget);

    // Trigger an error tap at the start (tapping 2 when 1 is expected)
    final cell2 = find.descendant(
      of: find.byType(AspectRatio),
      matching: find.text('2'),
    );
    await tester.tap(cell2);
    await tester.pump(const Duration(milliseconds: 350));

    // Tap numbers in sequence from 1 to 25
    for (int i = 1; i <= 25; i++) {
      final cellFinder = find.descendant(
        of: find.byType(AspectRatio),
        matching: find.text('$i'),
      );
      await tester.tap(cellFinder);
      await tester.pump();
    }

    // Should render completion screen
    expect(find.text('Exercise Complete!'), findsOneWidget);

    // Tap Continue to trigger callback
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(scoreValue, isNotNull);
    expect(errorsValue, 1);
    expect(durationValue, isNotNull);
  });

  testWidgets('Number Tracking game loop verification', (tester) async {
    int? scoreValue;
    int? errorsValue;

    await tester.pumpWidget(
      MaterialApp(
        home: NumberTrackingRuntimeScreen(
          onComplete: (score, errors, durationSecs) {
            scoreValue = score;
            errorsValue = errors;
          },
        ),
      ),
    );

    // Tapping correct targets from 1 to 8
    for (int i = 1; i <= 8; i++) {
      final tokenFinder = find.descendant(
        of: find.byKey(const Key('play_field_stack')),
        matching: find.text('$i'),
      );
      await tester.tap(tokenFinder);
      await tester.pump();
    }

    // Tapping distractor to increment errors
    // Distractors are numbers between 10 and 40.
    final distractorFinder = find.descendant(
      of: find.byKey(const Key('play_field_stack')),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          final val = int.tryParse(widget.data!);
          return val != null && val >= 10;
        }
        return false;
      }),
    ).first;
    await tester.tap(distractorFinder);
    await tester.pump(const Duration(milliseconds: 350));

    // Tap final target to complete
    final token9 = find.descendant(
      of: find.byKey(const Key('play_field_stack')),
      matching: find.text('9'),
    );
    await tester.tap(token9);
    await tester.pump();

    expect(find.text('Exercise Complete!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(scoreValue, isNotNull);
    expect(errorsValue, 1);
  });

  testWidgets('Peripheral Vision round-based verification', (tester) async {
    int? scoreValue;
    int? errorsValue;

    await tester.pumpWidget(
      MaterialApp(
        home: PeripheralVisionRuntimeScreen(
          onComplete: (score, errors, durationSecs) {
            scoreValue = score;
            errorsValue = errors;
          },
        ),
      ),
    );

    // Play through all 10 rounds
    for (int r = 0; r < 10; r++) {
      // 1. Wait for flashing phase (starts showing central dot + flashes word)
      await tester.pump(const Duration(milliseconds: 900));

      // 2. Identify target word from active flash in the Stack (which excludes crosshair '+')
      final flashTextFinder = find.descendant(
        of: find.byKey(const Key('peripheral_field_stack')),
        matching: find.byWidgetPredicate((widget) => widget is Text && widget.data != '+'),
      );
      expect(flashTextFinder, findsOneWidget);
      final targetWord = (tester.widget(flashTextFinder) as Text).data!;

      // 3. Move to answering phase
      await tester.pump(const Duration(milliseconds: 700));

      // 4. Tap the option with the target word
      await tester.tap(find.text(targetWord));
      await tester.pump();

      // 5. Move past feedback phase to next round
      await tester.pump(const Duration(milliseconds: 1300));
    }

    expect(find.text('Exercise Complete!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(scoreValue, 100); // 100% accuracy
    expect(errorsValue, 0);
  });

  testWidgets('Flash Recognition round-based verification', (tester) async {
    int? scoreValue;
    int? errorsValue;

    await tester.pumpWidget(
      MaterialApp(
        home: FlashRecognitionRuntimeScreen(
          onComplete: (score, errors, durationSecs) {
            scoreValue = score;
            errorsValue = errors;
          },
        ),
      ),
    );

    // Play through all 10 rounds
    for (int r = 0; r < 10; r++) {
      // 1. Wait for flashing phase
      await tester.pump(const Duration(milliseconds: 900));

      // 2. Identify target phrase from flash card inside the AnimatedSwitcher (filter out mask '#')
      final flashTextFinder = find.descendant(
        of: find.byType(AnimatedSwitcher),
        matching: find.byWidgetPredicate((widget) => widget is Text && !widget.data!.contains('#')),
      );
      expect(flashTextFinder, findsOneWidget);
      final targetPhrase = (tester.widget(flashTextFinder) as Text).data!;

      // 3. Move to answering phase
      await tester.pump(const Duration(milliseconds: 400));

      // 4. Tap the correct option button (use descendant of GestureDetector to avoid tapping the fading text in switcher)
      final optionButton = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.text(targetPhrase),
      ).first;
      await tester.tap(optionButton);
      await tester.pump();

      // 5. Move past feedback phase to next round
      await tester.pump(const Duration(milliseconds: 1300));
    }

    expect(find.text('Exercise Complete!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(scoreValue, 100); // 100% accuracy
    expect(errorsValue, 0);
  });
}
