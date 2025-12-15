/// Model for AI feedback on user's German writing
class AIFeedback {
  final String originalText;
  final bool isCorrect;
  final String? correctedText;
  final List<GrammarError> errors;
  final List<String> suggestions;
  final String overallFeedback;
  final int score; // 0-100

  AIFeedback({
    required this.originalText,
    required this.isCorrect,
    this.correctedText,
    required this.errors,
    required this.suggestions,
    required this.overallFeedback,
    required this.score,
  });

  factory AIFeedback.fromJson(Map<String, dynamic> json) {
    return AIFeedback(
      originalText: json['originalText'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      correctedText: json['correctedText'],
      errors:
          (json['errors'] as List?)
              ?.map((e) => GrammarError.fromJson(e))
              .toList() ??
          [],
      suggestions: List<String>.from(json['suggestions'] ?? []),
      overallFeedback: json['overallFeedback'] ?? '',
      score: json['score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'isCorrect': isCorrect,
      'correctedText': correctedText,
      'errors': errors.map((e) => e.toJson()).toList(),
      'suggestions': suggestions,
      'overallFeedback': overallFeedback,
      'score': score,
    };
  }
}

/// Model for individual grammar/spelling errors
class GrammarError {
  final String errorType; // grammar, spelling, word_choice, style
  final String errorText; // The incorrect part
  final String correction; // The correct version
  final String explanation; // Why it's wrong (in Turkish)
  final String rule; // Grammar rule name
  final List<String> examples; // Example sentences
  final int startIndex; // Position in original text
  final int endIndex;

  GrammarError({
    required this.errorType,
    required this.errorText,
    required this.correction,
    required this.explanation,
    required this.rule,
    required this.examples,
    required this.startIndex,
    required this.endIndex,
  });

  factory GrammarError.fromJson(Map<String, dynamic> json) {
    return GrammarError(
      errorType: json['errorType'] ?? 'grammar',
      errorText: json['errorText'] ?? '',
      correction: json['correction'] ?? '',
      explanation: json['explanation'] ?? '',
      rule: json['rule'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
      startIndex: json['startIndex'] ?? 0,
      endIndex: json['endIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'errorType': errorType,
      'errorText': errorText,
      'correction': correction,
      'explanation': explanation,
      'rule': rule,
      'examples': examples,
      'startIndex': startIndex,
      'endIndex': endIndex,
    };
  }
}

/// Model for alternative expressions
class AlternativeExpression {
  final String expression;
  final String context; // When to use this
  final String level; // A1, A2, B1, B2, C1, C2

  AlternativeExpression({
    required this.expression,
    required this.context,
    required this.level,
  });

  factory AlternativeExpression.fromJson(Map<String, dynamic> json) {
    return AlternativeExpression(
      expression: json['expression'] ?? '',
      context: json['context'] ?? '',
      level: json['level'] ?? 'B1',
    );
  }

  Map<String, dynamic> toJson() {
    return {'expression': expression, 'context': context, 'level': level};
  }
}
