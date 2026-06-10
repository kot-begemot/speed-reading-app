/// Computes the "optimal recognition point" letter index to highlight in the
/// focus word (spec §3 "Central letter logic").
///
/// Implements the spec's labelled "Basic rule" table:
/// ```
/// 1 letter    -> 0
/// 2–5 letters -> 1
/// 6–9 letters -> 2
/// 10+ letters -> 3
/// ```
/// NOTE: the spec's worked example `reading -> rea[D]ing` highlights index 3,
/// which contradicts the table (6–9 → index 2 → `re[A]ding`). We follow the
/// table; flip [_longIndex]/the 6–9 branch if the examples are preferred.
class CentralLetterCalculator {
  const CentralLetterCalculator._();

  static int indexFor(String word) {
    final n = word.length;
    if (n <= 1) return 0;
    if (n <= 5) return 1;
    if (n <= 9) return 2;
    return 3;
  }
}
