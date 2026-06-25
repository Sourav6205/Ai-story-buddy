// lib/widgets/quiz_card.dart
// Renders the quiz dynamically from QuizModel.
// Options are generated from JSON — no hardcoded answers in UI code.
// Wrong answer → shake + haptic. Correct answer → handled by provider.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/quiz_model.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.quiz,
    required this.selectedOption,
    required this.isWrongAnswer,
    required this.onOptionSelected,
  });

  final QuizModel quiz;
  final String? selectedOption;
  final bool isWrongAnswer;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFE8EAF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF7986CB).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz header
            Row(
              children: const [
                Text('🧠', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text(
                  'Quick Quiz!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3949AB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF9FA8DA), thickness: 1.5),
            const SizedBox(height: 12),

            // Question text
            Text(
              quiz.question,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 16),

            // Dynamically generated option buttons
            // Supports any number of options — driven purely by JSON
            ...quiz.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return _OptionButton(
                index: index,
                option: option,
                isSelected: selectedOption == option,
                isWrong: isWrongAnswer && selectedOption == option,
                onTap: () => onOptionSelected(option),
              );
            }),
          ],
        ),
      ),
    );

    // Shake the whole card on a wrong answer
    if (isWrongAnswer) {
      // Trigger haptic feedback whenever isWrongAnswer flips to true
      HapticFeedback.mediumImpact();
      card = card
          .animate()
          .shakeX(hz: 6, amount: 8, duration: 500.ms);
    }

    return card
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.index,
    required this.option,
    required this.isSelected,
    required this.isWrong,
    required this.onTap,
  });

  final int index;
  final String option;
  final bool isSelected;
  final bool isWrong;
  final VoidCallback onTap;

  // Emojis used as labels — keeps the UI fun without extra image assets
  static const _labels = ['🔴', '🟢', '🔵', '🟡', '🟣'];

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isWrong
        ? const Color(0xFFE53935)
        : isSelected
            ? const Color(0xFF43A047)
            : const Color(0xFF9FA8DA);

    final Color bgColor = isWrong
        ? const Color(0xFFFFEBEE)
        : isSelected
            ? const Color(0xFFE8F5E9)
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              index < _labels.length ? _labels[index] : '⭐',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isWrong
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFF1A237E),
                ),
              ),
            ),
            if (isWrong) const Icon(Icons.close, color: Color(0xFFE53935)),
          ],
        ),
      ),
    );
  }
}
