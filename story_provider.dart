// lib/providers/story_provider.dart
// All business logic lives here. The UI layer only reads from these providers
// and calls the exposed methods — zero logic in widgets.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_model.dart';
import '../services/tts_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Immutable state class
// ─────────────────────────────────────────────────────────────────────────────

/// All possible screen phases — drives what the UI renders.
enum StoryPhase {
  idle,       // Initial state — show "Read Me a Story" button
  preparing,  // TTS engine initialising
  narrating,  // Audio is playing
  quiz,       // Narration done — quiz visible
  success,    // Correct answer given
}

/// Immutable snapshot of the entire app state.
/// Riverpod re-renders ONLY widgets that depend on changed fields
/// thanks to manual equality / copyWith.
class StoryState {
  const StoryState({
    this.phase = StoryPhase.idle,
    this.selectedOption,
    this.isWrongAnswer = false,
    this.ttsError,
  });

  final StoryPhase phase;
  final String? selectedOption;  // Last option the child tapped
  final bool isWrongAnswer;      // Drives shake animation
  final String? ttsError;        // Non-null → show error card

  bool get hasError => ttsError != null;
  bool get isNarrating => phase == StoryPhase.narrating;
  bool get isSuccess => phase == StoryPhase.success;

  StoryState copyWith({
    StoryPhase? phase,
    String? selectedOption,
    bool? isWrongAnswer,
    String? ttsError,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return StoryState(
      phase: phase ?? this.phase,
      selectedOption: clearSelection ? null : (selectedOption ?? this.selectedOption),
      isWrongAnswer: isWrongAnswer ?? this.isWrongAnswer,
      ttsError: clearError ? null : (ttsError ?? this.ttsError),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryState &&
          phase == other.phase &&
          selectedOption == other.selectedOption &&
          isWrongAnswer == other.isWrongAnswer &&
          ttsError == other.ttsError;

  @override
  int get hashCode => Object.hash(phase, selectedOption, isWrongAnswer, ttsError);
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz data provider
// ─────────────────────────────────────────────────────────────────────────────

/// The quiz JSON.  In a real app this would be fetched from an API/asset file.
/// Keeping it here as a provider makes it trivially injectable/mockable in tests.
///
/// NOTE: options are generated dynamically — add/remove items in the JSON
/// and the quiz card adjusts with ZERO code changes.
const _quizJson = '''
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": [
    "Red",
    "Green",
    "Blue",
    "Yellow"
  ],
  "answer": "Blue"
}
''';

final quizProvider = Provider<QuizModel>((ref) {
  return QuizModel.fromJson(jsonDecode(_quizJson) as Map<String, dynamic>);
});

// ─────────────────────────────────────────────────────────────────────────────
// Story text provider
// ─────────────────────────────────────────────────────────────────────────────

const storyText =
    'Once upon a time, a clever little robot named Pip lost his shiny '
    'blue gear in the Whispering Woods. He searched high and low, asking '
    'the wise old owl and the bouncy bunny for help. Finally, a friendly '
    'firefly named Flo lit up the dark forest floor — and there it was, '
    'gleaming between two mossy rocks! Pip hugged Flo and promised to '
    'always be kind to every creature in the woods. And from that day on, '
    'the Whispering Woods were never dark again.';

final storyTextProvider = Provider<String>((ref) => storyText);

// ─────────────────────────────────────────────────────────────────────────────
// TTS service provider — single shared instance
// ─────────────────────────────────────────────────────────────────────────────

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  // Dispose when the provider scope is closed
  ref.onDispose(service.dispose);
  return service;
});

// ─────────────────────────────────────────────────────────────────────────────
// Main story notifier
// ─────────────────────────────────────────────────────────────────────────────

class StoryNotifier extends StateNotifier<StoryState> {
  StoryNotifier(this._tts, this._story, this._quiz)
      : super(const StoryState());

  final TtsService _tts;
  final String _story;
  final QuizModel _quiz;

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Triggered when the child taps "Read Me a Story".
  Future<void> startNarration() async {
    if (state.phase == StoryPhase.narrating ||
        state.phase == StoryPhase.preparing) return;

    state = state.copyWith(
      phase: StoryPhase.preparing,
      clearError: true,
    );

    try {
      // speak() resolves only after completion handler fires
      await _tts.speak(_story);

      // Narration finished successfully → show quiz
      state = state.copyWith(phase: StoryPhase.quiz);
    } catch (e) {
      state = state.copyWith(
        phase: StoryPhase.idle,
        ttsError: 'Oops! I couldn\'t read the story. Tap to try again!',
      );
    }
  }

  /// Triggered when a quiz option is tapped.
  Future<void> selectOption(String option) async {
    if (state.phase != StoryPhase.quiz) return;

    state = state.copyWith(
      selectedOption: option,
      isWrongAnswer: false,
    );

    if (_quiz.isCorrect(option)) {
      // Small delay so the selection highlight renders before dialog
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(phase: StoryPhase.success);
    } else {
      // Trigger shake animation by toggling the flag
      state = state.copyWith(isWrongAnswer: true);
      await Future.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(
        isWrongAnswer: false,
        clearSelection: true,
      );
    }
  }

  /// Reset everything — called after success dialog is dismissed.
  void reset() {
    _tts.stop();
    state = const StoryState();
  }

  /// Retry after a TTS error.
  void retry() {
    state = const StoryState();
    startNarration();
  }
}

/// The provider the UI binds to.
final storyNotifierProvider =
    StateNotifierProvider<StoryNotifier, StoryState>((ref) {
  return StoryNotifier(
    ref.watch(ttsServiceProvider),
    ref.watch(storyTextProvider),
    ref.watch(quizProvider),
  );
});
