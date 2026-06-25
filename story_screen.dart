// lib/screens/story_screen.dart
// Single-screen UI. Reads state from providers and delegates ALL logic
// to StoryNotifier — zero business logic in this file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/story_provider.dart';
import '../widgets/buddy_widget.dart';
import '../widgets/story_card.dart';
import '../widgets/quiz_card.dart';
import '../widgets/success_dialog.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only the slice of state we need — minimises rebuilds
    final state = ref.watch(storyNotifierProvider);
    final notifier = ref.read(storyNotifierProvider.notifier);
    final storyText = ref.watch(storyTextProvider);
    final quiz = ref.watch(quizProvider);

    final isNarrating = state.phase == StoryPhase.narrating;
    final isPreparing = state.phase == StoryPhase.preparing;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6A1B9A), // Deep purple
                  Color(0xFF283593), // Indigo
                  Color(0xFF0277BD), // Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative bubbles — purely cosmetic, using IgnorePointer so
          // they don't intercept touches
          const IgnorePointer(child: _BackgroundBubbles()),

          // ── Main scrollable content ──────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // App title
                      const Text(
                        '✨ AI Story Buddy ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(
                              color: Color(0x60000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.3, end: 0),

                      const SizedBox(height: 20),

                      // Buddy mascot
                      BuddyWidget(
                        isHappy: state.isSuccess,
                        isSpeaking: isNarrating,
                      )
                          .animate()
                          .fadeIn(duration: 700.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      // ── Error card ─────────────────────────────────────
                      if (state.hasError)
                        _ErrorCard(
                          message: state.ttsError!,
                          onRetry: notifier.retry,
                        ),

                      // ── "Read Me a Story" button ───────────────────────
                      if (!state.hasError &&
                          state.phase != StoryPhase.quiz &&
                          state.phase != StoryPhase.success)
                        _ReadStoryButton(
                          isPreparing: isPreparing,
                          isNarrating: isNarrating,
                          onTap: notifier.startNarration,
                        ),

                      // ── Story card (always visible once narration starts)
                      if (state.phase != StoryPhase.idle || state.hasError)
                        StoryCard(
                          storyText: storyText,
                          isNarrating: isNarrating,
                        ),

                      // ── Quiz card ──────────────────────────────────────
                      if (state.phase == StoryPhase.quiz ||
                          state.phase == StoryPhase.success)
                        QuizCard(
                          quiz: quiz,
                          selectedOption: state.selectedOption,
                          isWrongAnswer: state.isWrongAnswer,
                          onOptionSelected: notifier.selectOption,
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Success overlay — sits above everything ─────────────────────
          if (state.isSuccess)
            SuccessDialog(onDismiss: notifier.reset),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets (private — not exported)
// ─────────────────────────────────────────────────────────────────────────────

class _ReadStoryButton extends StatelessWidget {
  const _ReadStoryButton({
    required this.isPreparing,
    required this.isNarrating,
    required this.onTap,
  });

  final bool isPreparing;
  final bool isNarrating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool disabled = isPreparing || isNarrating;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          decoration: BoxDecoration(
            gradient: disabled
                ? const LinearGradient(
                    colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: disabled
                ? []
                : const [
                    BoxShadow(
                      color: Color(0x60FF6F00),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPreparing) ...[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                const Text('🎙️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
              ],
              Text(
                isPreparing
                    ? 'Getting Ready...'
                    : isNarrating
                        ? 'Reading Story...'
                        : 'Read Me a Story!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.elasticOut,
          delay: 400.ms,
        );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF9A9A), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('😕', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFB71C1C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Color(0xFFE53935)),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ).animate().shakeX(duration: 400.ms).fadeIn();
  }
}

/// Purely decorative background circles — uses const and IgnorePointer
/// to have zero impact on layout performance.
class _BackgroundBubbles extends StatelessWidget {
  const _BackgroundBubbles();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          _Bubble(left: -40, top: 80, diameter: 160, opacity: 0.08),
          _Bubble(right: -30, top: 200, diameter: 120, opacity: 0.06),
          _Bubble(left: 60, bottom: 300, diameter: 90, opacity: 0.07),
          _Bubble(right: 20, bottom: 100, diameter: 200, opacity: 0.05),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.diameter,
    required this.opacity,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }
}
