import 'package:flutter/material.dart';

import 'trainer_tokens.dart';
import '../../models/training_content.dart';

/// Fully interactive Comprehension Test (quiz) screen with question navigation,
/// option selection, answer mapping, and completion callback.
class ComprehensionTestScreen extends StatefulWidget {
  final List<ComprehensionQuestion> questions;
  final void Function(int correctCount)? onComplete;

  const ComprehensionTestScreen({
    super.key,
    required this.questions,
    this.onComplete,
  });

  @override
  State<ComprehensionTestScreen> createState() => _ComprehensionTestScreenState();
}

class _ComprehensionTestScreenState extends State<ComprehensionTestScreen> {
  TTheme get t => T.of(context);
  int _currentQuestionIndex = 0;
  
  // Maps question index to the selected option index (0 to 3)
  final Map<int, int> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOptions[_currentQuestionIndex] = index;
    });
  }

  void _goBack() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _goNextOrSubmit() {
    if (_selectedOptions[_currentQuestionIndex] == null) {
      // Show snackbar if no option is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option before moving forward.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _submitQuiz() {
    int correctCount = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final selected = _selectedOptions[i];
      final correct = widget.questions[i].correctOptionIndex;
      if (selected == correct) {
        correctCount++;
      }
    }

    if (widget.onComplete != null) {
      widget.onComplete!(correctCount);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    if (widget.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No questions available.')),
      );
    }

    final question = widget.questions[_currentQuestionIndex];
    final progressFraction = (_currentQuestionIndex + 1) / widget.questions.length;
    final isLastQuestion = _currentQuestionIndex == widget.questions.length - 1;

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top area: close + progress segments + counter.
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 6,
                        color: t.borderStrong.withValues(alpha: 0.5),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressFraction.clamp(0.0, 1.0),
                          child: Container(color: T.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentQuestionIndex + 1} / ${widget.questions.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Body.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lock chip.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: t.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.border, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 14, color: t.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'Passage hidden during the quiz',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'QUESTION ${_currentQuestionIndex + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: T.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.prompt,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.options.length,
                        itemBuilder: (context, index) {
                          final optionText = question.options[index];
                          final isSelected = _selectedOptions[_currentQuestionIndex] == index;
                          final letter = String.fromCharCode(65 + index); // A, B, C, D

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AnswerOption(
                              letter: letter,
                              text: optionText,
                              selected: isSelected,
                              onTap: () => _selectOption(index),
                            ),
                          );
                        },
                      ),
                    ),
                    // Nav buttons.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 12),
                      child: Row(
                        children: [
                          if (_currentQuestionIndex > 0) ...[
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: _goBack,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: t.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: t.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _goNextOrSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: T.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLastQuestion ? 'Submit Test' : 'Next Question',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isLastQuestion
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? t.primaryBg : t.surfaceLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? T.primary : t.border,
            width: selected ? 1.4 : 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: T.primary.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? T.primary : t.surfaceLow,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? T.primary : t.border,
                  width: 0.8,
                ),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : t.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
