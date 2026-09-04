import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../models/session.dart';
import '../services/firestore_service.dart';

class RatingScreen extends StatefulWidget {
  final GameSession session;
  const RatingScreen({super.key, required this.session});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _service = FirestoreService();
  final _commentController = TextEditingController();
  String? _selectedPlayerId;
  int _hostRating = 0;
  int _foodRating = 0;
  int _eveningRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.event, size: 18),
              const SizedBox(width: 6),
              Text('Bewertung für ${dateFormat.format(widget.session.date)}'),
              const SizedBox(width: 16),
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 6),
              _HostNameLabel(hostPlayerId: widget.session.hostPlayerId),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.getRatings(widget.session.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Fehler beim Laden der Bewertungen:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final ratings = snapshot.data!;
              if (ratings.isEmpty) {
                return const Center(
                  child: Text('Noch keine Bewertungen abgegeben.'),
                );
              }
              return ListView.builder(
                itemCount: ratings.length,
                itemBuilder: (context, index) => _RatingCard(rating: ratings[index]),
              );
            },
          ),
        ),
        const Divider(height: 1),
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              StreamBuilder<List<Player>>(
                stream: _service.getPlayers(),
                builder: (context, snapshot) {
                  final players = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedPlayerId,
                    decoration: const InputDecoration(labelText: 'Ich bin'),
                    items: players
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPlayerId = value),
                  );
                },
              ),
              const SizedBox(height: 8),
              _StarRow(
                label: 'Gastgeber:in',
                value: _hostRating,
                onChanged: (v) => setState(() => _hostRating = v),
              ),
              _StarRow(
                label: 'Essen',
                value: _foodRating,
                onChanged: (v) => setState(() => _foodRating = v),
              ),
              _StarRow(
                label: 'Abend allg.',
                value: _eveningRating,
                onChanged: (v) => setState(() => _eveningRating = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: 'Kommentar (optional)'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Bewertung abschicken'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Person auswählen.')),
      );
      return;
    }
    if (_hostRating == 0 || _foodRating == 0 || _eveningRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle drei Kategorien bewerten.')),
      );
      return;
    }

    try {
      await _service.addRating(
        widget.session.id,
        _selectedPlayerId!,
        hostRating: _hostRating,
        foodRating: _foodRating,
        eveningRating: _eveningRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      setState(() {
        _hostRating = 0;
        _foodRating = 0;
        _eveningRating = 0;
      });
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Danke für deine Bewertung!')),
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

class _StarRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StarRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        ...List.generate(5, (index) {
          final starValue = index + 1;
          return IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              starValue <= value ? Icons.star : Icons.star_border,
              color: starValue <= value ? Colors.amber : null,
            ),
            onPressed: () => onChanged(starValue),
          );
        }),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  final Map<String, dynamic> rating;
  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final playerId = rating['playerId'] as String? ?? '';
    final host = rating['hostRating'] ?? 0;
    final food = rating['foodRating'] ?? 0;
    final evening = rating['eveningRating'] ?? 0;
    final comment = rating['comment'] as String?;

    return FutureBuilder<Player?>(
      future: FirestoreService().getPlayer(playerId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '…';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Gastgeber:in: $host/5 · Essen: $food/5 · Abend: $evening/5'),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('"$comment"', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HostNameLabel extends StatelessWidget {
  final String hostPlayerId;
  const _HostNameLabel({required this.hostPlayerId});

  @override
  Widget build(BuildContext context) {
    if (hostPlayerId.isEmpty) {
      return const Text('noch kein:e Gastgeber:in');
    }
    return FutureBuilder<Player?>(
      future: FirestoreService().getPlayer(hostPlayerId),
      builder: (context, snapshot) {
        return Text(snapshot.data?.name ?? '…');
      },
    );
  }
}