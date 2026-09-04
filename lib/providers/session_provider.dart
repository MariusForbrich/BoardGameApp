import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../services/firestore_service.dart';

class SessionProvider extends ChangeNotifier {
  final FirestoreService _service;
  StreamSubscription<GameSession?>? _subscription;

  GameSession? _upcomingSession;
  GameSession? get upcomingSession => _upcomingSession;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  SessionProvider(this._service) {
    _listenToUpcomingSession();
  }

  void _listenToUpcomingSession() {
    _subscription = _service.getUpcomingSession().listen((session) {
      _upcomingSession = session;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> setHost(String playerId) async {
    final session = _upcomingSession;
    if (session == null) return;
    await _service.setHost(session.id, playerId);
    // Der Stream aktualisiert _upcomingSession automatisch,
    // sobald Firestore die Änderung zurückspiegelt.
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}