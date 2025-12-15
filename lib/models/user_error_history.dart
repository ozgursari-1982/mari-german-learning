import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking user's error history for personalization
class UserErrorHistory {
  final String userId;
  final List<ErrorRecord> errors;
  final Map<String, int> errorFrequency; // rule -> count
  final Map<String, DateTime> lastErrorDate; // rule -> last occurrence
  final List<String> weakAreas; // Most common error rules
  final DateTime lastUpdated;

  UserErrorHistory({
    required this.userId,
    required this.errors,
    required this.errorFrequency,
    required this.lastErrorDate,
    required this.weakAreas,
    required this.lastUpdated,
  });

  factory UserErrorHistory.empty(String userId) {
    return UserErrorHistory(
      userId: userId,
      errors: [],
      errorFrequency: {},
      lastErrorDate: {},
      weakAreas: [],
      lastUpdated: DateTime.now(),
    );
  }

  factory UserErrorHistory.fromMap(Map<String, dynamic> map) {
    return UserErrorHistory(
      userId: map['userId'] ?? '',
      errors: (map['errors'] as List?)
              ?.map((e) => ErrorRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      errorFrequency: Map<String, int>.from(map['errorFrequency'] ?? {}),
      lastErrorDate: (map['lastErrorDate'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    key,
                    (value as Timestamp).toDate(),
                  )) ??
          {},
      weakAreas: List<String>.from(map['weakAreas'] ?? []),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'errors': errors.map((e) => e.toMap()).toList(),
      'errorFrequency': errorFrequency,
      'lastErrorDate': lastErrorDate.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'weakAreas': weakAreas,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Get top N most frequent errors
  List<String> getTopErrors(int n) {
    final sorted = errorFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Check if a rule is a recurring error (appeared 3+ times)
  bool isRecurringError(String rule) {
    return (errorFrequency[rule] ?? 0) >= 3;
  }

  /// Get recent errors (last 30 days)
  List<ErrorRecord> getRecentErrors({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return errors.where((e) => e.date.isAfter(cutoff)).toList();
  }

  /// Create a copy with updated fields
  UserErrorHistory copyWith({
    String? userId,
    List<ErrorRecord>? errors,
    Map<String, int>? errorFrequency,
    Map<String, DateTime>? lastErrorDate,
    List<String>? weakAreas,
    DateTime? lastUpdated,
  }) {
    return UserErrorHistory(
      userId: userId ?? this.userId,
      errors: errors ?? this.errors,
      errorFrequency: errorFrequency ?? this.errorFrequency,
      lastErrorDate: lastErrorDate ?? this.lastErrorDate,
      weakAreas: weakAreas ?? this.weakAreas,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Individual error record
class ErrorRecord {
  final String id;
  final String rule; // Grammar rule name (e.g., "Akkusativ", "Perfekt")
  final String errorType; // grammar, spelling, word_choice, style
  final String errorText;
  final String correction;
  final DateTime date;
  final String? context; // Original text where error occurred

  ErrorRecord({
    required this.id,
    required this.rule,
    required this.errorType,
    required this.errorText,
    required this.correction,
    required this.date,
    this.context,
  });

  factory ErrorRecord.fromMap(Map<String, dynamic> map) {
    return ErrorRecord(
      id: map['id'] ?? '',
      rule: map['rule'] ?? '',
      errorType: map['errorType'] ?? 'grammar',
      errorText: map['errorText'] ?? '',
      correction: map['correction'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      context: map['context'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rule': rule,
      'errorType': errorType,
      'errorText': errorText,
      'correction': correction,
      'date': Timestamp.fromDate(date),
      'context': context,
    };
  }
}

