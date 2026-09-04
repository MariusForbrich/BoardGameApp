import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/suggestion.dart';
import '../services/firestore_service.dart';

class SuggestionsScreen extends StatefulWidget {
  final String sessionId;
  const SuggestionsScreen({super.key, required this.sessionId});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _gameController = TextEditingController();
  final _service = FirestoreService();
  String? _selectedPlayerId;

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedPlayerId == null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Wähle unten deine Person aus, um mitzustimmen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: StreamBuilder<List<GameSuggestion>>(
            stream: _service.getSuggestions(widget.sessionId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Fehler beim Laden der Vorschläge:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final suggestions = snapshot.data!;
              if (suggestions.isEmpty) {
                return const Center(
                  child: Text('Noch keine Spiele vorgeschlagen.'),
                );
              }
              return ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return _SuggestionTile(
                    suggestion: suggestions[index],
                    currentPlayerId: _selectedPlayerId,
                    service: _service,
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              StreamBuilder<List<Player>>(
                stream: _service.getPlayers(),
                builder: (context, snapshot) {
                  final players = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedPlayerId,
                    decoration: const InputDecoration(
                      labelText: 'Ich bin / Vorgeschlagen von',
                    ),
                    items: players
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPlayerId = value),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gameController,
                      decoration: const InputDecoration(
                        labelText: 'Spielname',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Vorschlagen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final gameName = _gameController.text.trim();

    if (gameName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Spielnamen eingeben.')),
      );
      return;
    }
    if (_selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Person auswählen.')),
      );
      return;
    }

    try {
      await _service.addSuggestion(GameSuggestion(
        id: '',
        sessionId: widget.sessionId,
        gameName: gameName,
        suggestedBy: _selectedPlayerId!,
        createdAt: DateTime.now(),
      ));
      _gameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$gameName" wurde vorgeschlagen.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }
}

class _SuggestionTile extends StatelessWidget {
  final GameSuggestion suggestion;
  final String? currentPlayerId;
  final FirestoreService service;

  const _SuggestionTile({
    required this.suggestion,
    required this.currentPlayerId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getVotesForSuggestion(suggestion.id),
      builder: (context, snapshot) {
        final votes = snapshot.data ?? [];
        final voteCount = votes.length;
        final hasVoted = currentPlayerId != null &&
            votes.any((v) => v['playerId'] == currentPlayerId);

        return ListTile(
          leading: const Icon(Icons.casino_outlined),
          title: Text(suggestion.gameName),
          subtitle: _SuggestedByLabel(playerId: suggestion.suggestedBy),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$voteCount'),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: hasVoted ? Theme.of(context).colorScheme.primary : null,
                ),
                tooltip: currentPlayerId == null
                    ? 'Erst Person auswählen'
                    : (hasVoted ? 'Stimme zurückziehen' : 'Abstimmen'),
                onPressed: currentPlayerId == null
                    ? null
                    : () async {
                        if (hasVoted) {
                          await service.removeVote(suggestion.id, currentPlayerId!);
                        } else {
                          await service.castVote(suggestion.id, currentPlayerId!, 1);
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestedByLabel extends StatelessWidget {
  final String playerId;
  const _SuggestedByLabel({required this.playerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Player?>(
      future: FirestoreService().getPlayer(playerId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '…';
        return Text('Vorgeschlagen von $name');
      },
    );
  }
}