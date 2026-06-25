// lib/widgets/story_card.dart
// Displays the story text inside an animated, colourful card.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.storyText,
    required this.isNarrating,
  });

  final String storyText;
  final bool isNarrating;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isNarrating
              ? const Color(0xFFFFB300)
              : const Color(0xFFFFCC02).withOpacity(0.5),
          width: isNarrating ? 2.5 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Story Time!" header
            Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  isNarrating ? 'Listening...' : 'Story Time!',
                  style: const TextStyle(
                    fontFamily: 'Fredoka One',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                if (isNarrating) ...[
                  const SizedBox(width: 8),
                  _SoundWave(),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFFFCC02), thickness: 1.5),
            const SizedBox(height: 12),

            // Story text
            Text(
              storyText,
              style: const TextStyle(
                fontSize: 16.5,
                height: 1.65,
                color: Color(0xFF4E342E),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

/// Three animated dots that pulse like a sound wave during narration.
class _SoundWave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFE65100),
            borderRadius: BorderRadius.circular(2),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleY(
              begin: 0.3,
              end: 1.0,
              duration: Duration(milliseconds: 350 + i * 80),
              delay: Duration(milliseconds: i * 100),
            );
      }),
    );
  }
}
