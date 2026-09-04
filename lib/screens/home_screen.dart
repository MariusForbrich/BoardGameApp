import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import 'suggestions_screen.dart';
import 'rating_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final hasSession = sessionProvider.upcomingSession != null;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Board Gamer App'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt),
              tooltip: 'Spieler:in hinzufügen',
              onPressed: () => _showAddPlayerDialog(context),
            ),
          ],
          bottom: hasSession
              ? const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.event), text: 'Termin'),
                    Tab(icon: Icon(Icons.casino), text: 'Spiele'),
                    Tab(icon: Icon(Icons.star_rate), text: 'Bewertung'),
                    Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Nachrichten'),
                  ],
                )
              : null,
        ),
        body: sessionProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasSession
                ? const _NoSessionView()
                : TabBarView(
                    children: [
                      _SessionDetails(session: sessionProvider.upcomingSession!),
                      SuggestionsScreen(sessionId: sessionProvider.upcomingSession!.id),
                      RatingScreen(session: sessionProvider.upcomingSession!),
                      MessagesScreen(sessionId: sessionProvider.upcomingSession!.id),
                    ],
                  ),
      ),
    );
  }
}

/// Dialog zum schnellen Anlegen einer neuen Spieler:in (Name reicht).
void _showAddPlayerDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Spieler:in hinzufügen'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            await FirestoreService().addPlayer(name);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Hinzufügen'),
        ),
      ],
    ),
  );
}

class _NoSessionView extends StatelessWidget {
  const _NoSessionView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Es ist aktuell kein Termin geplant.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _createTestSession(context),
              icon: const Icon(Icons.add),
              label: const Text('Test-Termin anlegen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestSession(BuildContext context) async {
    final session = GameSession(
      id: '',
      date: DateTime.now().add(const Duration(days: 3)),
      location: 'Bei Marius',
      hostPlayerId: '',
      status: 'geplant',
    );
    await FirestoreService().createSession(session);
  }
}

class _SessionDetails extends StatelessWidget {
  final GameSession session;
  const _SessionDetails({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd.MM.yyyy – HH:mm', 'de_DE');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(session.date),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_outlined),
              const SizedBox(width: 8),
              Text(session.location),
            ],
          ),
          const SizedBox(height: 8),
          _HostRow(hostPlayerId: session.hostPlayerId),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showHostPicker(context, session.id),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Gastgeber:in ändern'),
          ),
        ],
      ),
    );
  }

  void _showHostPicker(BuildContext context, String sessionId) {
    final sessionProvider = context.read<SessionProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gastgeber:in wählen'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Player>>(
            stream: FirestoreService().getPlayers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final players = snapshot.data!;
              if (players.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Noch keine Spieler:innen angelegt. '
                    'Über das Symbol oben rechts hinzufügen.',
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(player.name),
                    onTap: () async {
                      await sessionProvider.setHost(player.id);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}

class _HostRow extends StatelessWidget {
  final String hostPlayerId;
  const _HostRow({required this.hostPlayerId});

  @override
  Widget build(BuildContext context) {
    if (hostPlayerId.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.person_outline),
          SizedBox(width: 8),
          Text('Noch kein:e Gastgeber:in festgelegt'),
        ],
      );
    }

    return FutureBuilder<Player?>(
      future: FirestoreService().getPlayer(hostPlayerId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '…';
        return Row(
          children: [
            const Icon(Icons.person_outline),
            const SizedBox(width: 8),
            Text('Gastgeber:in: $name'),
          ],
        );
      },
    );
  }
}