// lib/services/tts_service.dart
// Encapsulates all flutter_tts interactions so the rest of the app
// never imports flutter_tts directly — easy to swap engines later.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Possible states the TTS engine can be in.
enum TtsState { idle, preparing, speaking, completed, error }

/// Thin wrapper around [FlutterTts] that exposes a clean async API
/// and a [ValueNotifier] for reactive state.
class TtsService {
  TtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();

  // ── Public reactive state ──────────────────────────────────────────────────
  final ValueNotifier<TtsState> stateNotifier =
      ValueNotifier(TtsState.idle);

  String? lastError;

  // ── Private completers ─────────────────────────────────────────────────────
  Completer<void>? _speakCompleter;

  // ── Initialisation ─────────────────────────────────────────────────────────
  void _init() {
    _tts.setStartHandler(() {
      stateNotifier.value = TtsState.speaking;
    });

    _tts.setCompletionHandler(() {
      stateNotifier.value = TtsState.completed;
      _speakCompleter?.complete();
      _speakCompleter = null;
    });

    _tts.setCancelHandler(() {
      stateNotifier.value = TtsState.idle;
      _speakCompleter?.complete();
      _speakCompleter = null;
    });

    _tts.setErrorHandler((message) {
      lastError = message.toString();
      stateNotifier.value = TtsState.error;
      _speakCompleter?.completeError(message.toString());
      _speakCompleter = null;
    });
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Configure TTS engine settings. Call once before speaking.
  Future<void> configure({
    String language = 'en-US',
    double speechRate = 0.45, // Slightly slow for children
    double pitch = 1.1,       // Slightly higher — friendlier tone
    double volume = 1.0,
  }) async {
    await Future.wait([
      _tts.setLanguage(language),
      _tts.setSpeechRate(speechRate),
      _tts.setPitch(pitch),
      _tts.setVolume(volume),
    ]);
  }

  /// Speak [text] and return a [Future] that resolves when narration ends.
  Future<void> speak(String text) async {
    // Guard: don't start if already speaking
    if (stateNotifier.value == TtsState.speaking) return;

    stateNotifier.value = TtsState.preparing;
    lastError = null;

    try {
      await configure();

      // Create completer so callers can await completion
      _speakCompleter = Completer<void>();
      await _tts.speak(text);

      // Wait for completion/cancel/error handler to resolve
      await _speakCompleter!.future;
    } catch (e) {
      lastError = e.toString();
      stateNotifier.value = TtsState.error;
      rethrow;
    }
  }

  /// Stop any ongoing speech and reset to idle.
  Future<void> stop() async {
    await _tts.stop();
    stateNotifier.value = TtsState.idle;
  }

  /// Release resources — call in dispose().
  Future<void> dispose() async {
    await _tts.stop();
    stateNotifier.dispose();
  }
}
