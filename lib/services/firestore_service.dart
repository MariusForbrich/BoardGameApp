import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';
import '../models/session.dart';
import '../models/suggestion.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Player

  Future<void> createPlayer(Player player) async {
    await _db.collection('players').doc(player.id).set(player.toMap());
  }

  Future<Player?> getPlayer(String playerId) async {
    final doc = await _db.collection('players').doc(playerId).get();
    if (!doc.exists) return null;
    return Player.fromMap(doc.id, doc.data()!);
  }

  Stream<List<Player>> getPlayers() {
    return _db.collection('players').orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Player.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> addPlayer(String name) async {
    final doc = await _db.collection('players').add({
      'name': name,
      'email': '',
      'createdAt': Timestamp.now(),
    });
    return doc.id;
  }

  // nächsten Termin anzeigen

  Stream<GameSession?> getUpcomingSession() {
    return _db
        .collection('sessions')
        .where('status', isEqualTo: 'geplant')
        .orderBy('date')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return GameSession.fromMap(doc.id, doc.data());
    });
  }

  Future<String> createSession(GameSession session) async {
    final doc = await _db.collection('sessions').add(session.toMap());
    return doc.id;
  }

  // hostplayer

  Future<void> setHost(String sessionId, String playerId) async {
    await _db.collection('sessions').doc(sessionId).update({
      'hostPlayerId': playerId,
    });
  }

  // Spiele vorschlagen

  Stream<List<GameSuggestion>> getSuggestions(String sessionId) {
    return _db
        .collection('suggestions')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameSuggestion.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addSuggestion(GameSuggestion suggestion) async {
    await _db.collection('suggestions').add(suggestion.toMap());
  }

  // Voting

  Future<void> castVote(String suggestionId, String playerId, int value) async {
   
    final voteId = '${suggestionId}_$playerId';
    await _db.collection('votes').doc(voteId).set({
      'suggestionId': suggestionId,
      'playerId': playerId,
      'value': value,
    });
  }

  Future<void> removeVote(String suggestionId, String playerId) async {
    final voteId = '${suggestionId}_$playerId';
    await _db.collection('votes').doc(voteId).delete();
  }

  Stream<List<Map<String, dynamic>>> getVotesForSuggestion(String suggestionId) {
    return _db
        .collection('votes')
        .where('suggestionId', isEqualTo: suggestionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Rating

  Future<void> addRating(
    String sessionId,
    String playerId, {
    required int hostRating,
    required int foodRating,
    required int eveningRating,
    String? comment,
  }) async {
    await _db.collection('ratings').add({
      'sessionId': sessionId,
      'playerId': playerId,
      'hostRating': hostRating,
      'foodRating': foodRating,
      'eveningRating': eveningRating,
      'comment': comment,
    });
  }

  Stream<List<Map<String, dynamic>>> getRatings(String sessionId) {
    return _db
        .collection('ratings')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Nachrichten

  Stream<List<Map<String, dynamic>>> getMessages(String sessionId) {
    return _db
        .collection('messages')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendMessage(String sessionId, String senderId, String text) async {
    await _db.collection('messages').add({
      'sessionId': sessionId,
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.now(),
    });
  }
}
