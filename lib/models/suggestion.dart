import 'package:cloud_firestore/cloud_firestore.dart';

class GameSuggestion {
  final String id;
  final String sessionId;
  final String gameName;
  final String suggestedBy;
  final DateTime createdAt;

  GameSuggestion({
    required this.id,
    required this.sessionId,
    required this.gameName,
    required this.suggestedBy,
    required this.createdAt,
  });

  factory GameSuggestion.fromMap(String id, Map<String, dynamic> data) {
    return GameSuggestion(
      id: id,
      sessionId: data['sessionId'] as String? ?? '',
      gameName: data['gameName'] as String? ?? '',
      suggestedBy: data['suggestedBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'gameName': gameName,
      'suggestedBy': suggestedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}