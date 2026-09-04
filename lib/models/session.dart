import 'package:cloud_firestore/cloud_firestore.dart';

class GameSession {
  final String id;
  final DateTime date;
  final String location;
  final String hostPlayerId;
  final String status; // 'geplant' | 'abgeschlossen'

  GameSession({
    required this.id,
    required this.date,
    required this.location,
    required this.hostPlayerId,
    required this.status,
  });

  factory GameSession.fromMap(String id, Map<String, dynamic> data) {
    return GameSession(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] as String? ?? '',
      hostPlayerId: data['hostPlayerId'] as String? ?? '',
      status: data['status'] as String? ?? 'geplant',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'location': location,
      'hostPlayerId': hostPlayerId,
      'status': status,
    };
  }
}