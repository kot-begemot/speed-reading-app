import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/utils/time_estimator.dart';

void main() {
  test('progress is a clamped fraction', () {
    expect(TimeEstimator.progress(0, 100), 0);
    expect(TimeEstimator.progress(50, 100), 0.5);
    expect(TimeEstimator.progress(100, 100), 1.0);
    expect(TimeEstimator.progress(5, 0), 0); // no divide-by-zero
  });

  test('estimated time left uses actual words, not entries', () {
    // 600 words remaining at 300 WPM = 2 minutes.
    expect(TimeEstimator.estimatedTimeLeft(0, 600, 300),
        const Duration(minutes: 2));
    // Halfway through 600 at 300 WPM = 1 minute.
    expect(TimeEstimator.estimatedTimeLeft(300, 600, 300),
        const Duration(minutes: 1));
  });

  test('millisecondsPerEntry matches the spec formula', () {
    // 300 WPM, 1 word/entry = 200 ms.
    expect(TimeEstimator.millisecondsPerEntry(300, 1), 200);
    // 300 WPM, 3 words/entry = 600 ms.
    expect(TimeEstimator.millisecondsPerEntry(300, 3), 600);
    // 600 WPM, 1 word/entry = 100 ms.
    expect(TimeEstimator.millisecondsPerEntry(600, 1), 100);
  });
}
