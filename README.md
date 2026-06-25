# 🤖 AI Story Buddy

A **child-friendly Flutter app** that narrates an interactive story using Text-to-Speech and presents a dynamic quiz to test comprehension — all in a colourful, animated single-screen experience.

---

## 📱 Screenshots

> Run the app on a device or emulator to see the full experience.

---

## 🏗️ Architecture

The project follows **Clean Architecture** with three distinct layers:

```
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                           │
│   screens/story_screen.dart   widgets/*.dart            │
│   • Reads state via ref.watch()                         │
│   • Calls notifier methods — zero business logic        │
└───────────────────────────┬─────────────────────────────┘
                            │  Riverpod providers
┌───────────────────────────▼─────────────────────────────┐
│                  Business Logic Layer                   │
│   providers/story_provider.dart                         │
│   • StoryNotifier (StateNotifier)                       │
│   • StoryState (immutable snapshot)                     │
│   • StoryPhase enum (idle → preparing → narrating →     │
│     quiz → success)                                     │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                    Data / Service Layer                 │
│   models/quiz_model.dart      services/tts_service.dart │
│   • Pure Dart data classes    • flutter_tts wrapper     │
│   • JSON deserialization      • Async speak() / stop()  │
│   • isCorrect() helper        • ValueNotifier<TtsState> │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility |
|---|---|
| **UI** | Render state, forward events to notifier |
| **Business Logic** | Orchestrate state transitions, handle TTS lifecycle |
| **Data/Service** | Model data, wrap third-party APIs |

---

## 📁 Folder Structure

```
lib/
├── main.dart                  # App entry point + ProviderScope
├── models/
│   └── quiz_model.dart        # Immutable quiz data + fromJson()
├── services/
│   └── tts_service.dart       # flutter_tts wrapper + state notifier
├── providers/
│   └── story_provider.dart    # All Riverpod providers + StoryNotifier
├── screens/
│   └── story_screen.dart      # Single screen — pure UI
└── widgets/
    ├── buddy_widget.dart       # Animated robot mascot (CustomPainter)
    ├── story_card.dart         # Story text card with sound wave
    ├── quiz_card.dart          # Dynamic quiz options (JSON-driven)
    └── success_dialog.dart     # Confetti celebration overlay
```

---

## 🔄 State Management (Riverpod)

### Why Riverpod?

- **Compile-safe** — no magic strings, no `BuildContext` needed in providers
- **Testable** — providers are plain Dart; easy to override in tests
- **Efficient** — only widgets that `watch` a changed field rebuild

### Provider Graph

```
ttsServiceProvider   storyTextProvider   quizProvider
        │                   │                 │
        └───────────────────▼─────────────────┘
                    storyNotifierProvider
                    (StoryNotifier / StoryState)
                            │
                      StoryScreen
                      (watches state)
```

### State Machine

```
idle ──[tap button]──▶ preparing
                            │
                      [TTS ready]
                            ▼
                        narrating ──[error]──▶ idle (+ ttsError)
                            │
                    [completion handler]
                            ▼
                          quiz
                            │
              ┌─────────────┴──────────────┐
         [wrong]                        [correct]
              │                              │
    isWrongAnswer=true              StoryPhase.success
    (shake + haptic)                (confetti overlay)
              │                              │
         [reset]                       [dismiss]
              ▼                              ▼
           quiz                           idle
```

---

## 🎯 Quiz Rendering Approach

The quiz is **100% data-driven** — the UI never hardcodes any question, option, or answer:

1. `quizProvider` holds a `QuizModel` parsed from JSON
2. `QuizCard` receives the model and maps `quiz.options` → buttons
3. Adding/removing options requires **only a JSON change** — zero Dart code changes

```dart
// Dynamic option rendering — supports 3, 4, or 5 options
...quiz.options.asMap().entries.map((entry) {
  return _OptionButton(option: entry.value, ...);
}),
```

Answer checking is encapsulated in the model:

```dart
bool isCorrect(String selected) =>
    selected.trim().toLowerCase() == answer.trim().toLowerCase();
```

---

## ⚡ Performance Optimisations

### Widget Rebuilds
- `ref.watch` on `storyNotifierProvider` triggers rebuilds only when `StoryState` changes
- `StoryState` implements `==` and `hashCode` — prevents unnecessary rebuilds on identical state
- Sub-widgets (`_ErrorCard`, `_ReadStoryButton`, `_BackgroundBubbles`) are separated so only affected subtrees rebuild

### Const Widgets
- All decorative and static widgets use `const` constructors
- `_BackgroundBubbles` is wrapped in `IgnorePointer` + `const` — zero hit-testing overhead

### Animation Performance
- `flutter_animate` uses `AnimationController` under the hood — GPU-composited
- `CustomPainter` for the robot: single draw call per frame, no widget tree overhead
- Shake animation uses `Transform` (composited layer) not layout changes

### Low-End Device Optimisations
- `BouncingScrollPhysics` — lighter than `ClampingScrollPhysics` on low RAM
- No heavy image assets — all visuals are code-drawn (CustomPainter + Container)
- `confetti` package auto-limits particle count on slower devices

---

## 📦 Caching Strategy

| Data Type | Strategy |
|---|---|
| **Story text** | Static `const String` — zero I/O |
| **Quiz JSON** | Static `const String` — zero I/O; `Provider` caches parsed model |
| **TTS engine** | Single `TtsService` instance via `Provider` (not re-created on rebuild) |
| **TTS audio** | flutter_tts caches synthesised audio in the OS TTS engine |

In a production app with remote story/quiz data, add:

```dart
// Example: add shared_preferences or hive for offline caching
final quizProvider = FutureProvider<QuizModel>((ref) async {
  final cached = await cache.get('quiz');
  if (cached != null) return QuizModel.fromJson(cached);
  final remote = await api.fetchQuiz();
  await cache.set('quiz', remote);
  return remote;
});
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Android device/emulator with **Android 5.0 (API 21)** or higher
- Text-to-Speech engine installed (Google TTS recommended)

### Installation

```bash
# Clone the project
git clone https://github.com/your-org/ai_story_buddy.git
cd ai_story_buddy

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build Release APK

```bash
flutter build apk --release --target-platform android-arm64
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management |
| `flutter_tts` | ^4.0.2 | Text-to-Speech narration |
| `confetti` | ^0.7.0 | Celebration particles |
| `flutter_animate` | ^4.5.0 | Declarative animations |

---

## 🧪 Testing

The clean architecture makes testing straightforward:

```dart
// Override providers in tests
final container = ProviderContainer(overrides: [
  ttsServiceProvider.overrideWithValue(MockTtsService()),
  quizProvider.overrideWithValue(QuizModel(...)),
]);

// Test state transitions
container.read(storyNotifierProvider.notifier).startNarration();
expect(container.read(storyNotifierProvider).phase, StoryPhase.preparing);
```

---

## 🌐 Extending the App

### Adding More Stories

1. Create a `StoryModel` class similar to `QuizModel`
2. Add a list of stories to a `storiesProvider`
3. Pass the selected story into `StoryNotifier`

### Fetching Quiz from API

Replace the static JSON string in `story_provider.dart`:

```dart
final quizProvider = FutureProvider<QuizModel>((ref) async {
  final response = await http.get(Uri.parse('https://api.example.com/quiz/1'));
  return QuizModel.fromJson(jsonDecode(response.body));
});
```

### Localisation

Wrap story text and quiz JSON behind a locale-aware provider and use Flutter's `AppLocalizations` for UI strings.

---

## 🎨 Design System

| Token | Value | Usage |
|---|---|---|
| Primary gradient | `#6A1B9A → #0277BD` | Background |
| Story card | `#FFF9C4 → #FFE0B2` | Warm yellow — story feel |
| Quiz card | `#E3F2FD → #E8EAF6` | Cool blue — thinking mode |
| Success | `#4CAF50` | Correct answers, buddy happy state |
| Error | `#E53935` | Wrong answers, TTS errors |
| Body font | Nunito / system sans | Rounded, readable for children |

---

## 📄 Licence

MIT — free to use, modify, and distribute.
