import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/utils/central_letter_calculator.dart';

void main() {
  test('central letter index follows the basic-rule table', () {
    expect(CentralLetterCalculator.indexFor('a'), 0); // 1
    expect(CentralLetterCalculator.indexFor('on'), 1); // 2–5
    expect(CentralLetterCalculator.indexFor('speed'), 1); // 5
    expect(CentralLetterCalculator.indexFor('reading'), 2); // 7 → table
    expect(CentralLetterCalculator.indexFor('functionality'), 3); // 13 → 10+
  });

  test('empty word is safe', () {
    expect(CentralLetterCalculator.indexFor(''), 0);
  });
}
