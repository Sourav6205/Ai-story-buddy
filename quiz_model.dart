// lib/models/quiz_model.dart
// Data model for the quiz — keeps UI layer decoupled from data shape.

/// Represents a single quiz question with dynamic options.
/// Options are NOT hardcoded; they are deserialized from JSON at runtime,
/// so the quiz can support 3, 4, or 5 options with zero code changes.
class QuizModel {
  final String question;
  final List<String> options;
  final String answer;

  const QuizModel({
    required this.question,
    required this.options,
    required this.answer,
  });

  /// Primary constructor: parse straight from a JSON map.
  /// Throws [FormatException] if required keys are missing.
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List) {
      throw const FormatException(
        'Quiz JSON must contain an "options" list.',
      );
    }

    return QuizModel(
      question: json['question'] as String? ??
          (throw const FormatException('Missing "question" field.')),
      options: List<String>.from(rawOptions),
      answer: json['answer'] as String? ??
          (throw const FormatException('Missing "answer" field.')),
    );
  }

  /// Convenience: check whether a given user selection is correct.
  bool isCorrect(String selected) =>
      selected.trim().toLowerCase() == answer.trim().toLowerCase();

  @override
  String toString() =>
      'QuizModel(question: $question, options: $options, answer: $answer)';
}
