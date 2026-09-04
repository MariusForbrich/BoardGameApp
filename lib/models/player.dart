import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  Player({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory Player.fromMap(String id, Map<String, dynamic> data) {
    return Player(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}