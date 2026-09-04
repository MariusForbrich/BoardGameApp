import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/firestore_service.dart';

class MessagesScreen extends StatefulWidget {
  final String sessionId;
  const MessagesScreen({super.key, required this.sessionId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _service = FirestoreService();
  final _textController = TextEditingController();
  String? _selectedPlayerId;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.getMessages(widget.sessionId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Fehler beim Laden der Nachrichten:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return const Center(child: Text('Noch keine Nachrichten.'));
              }
              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final senderId = message['senderId'] as String? ?? '';
                  final text = message['text'] as String? ?? '';
                  return ListTile(
                    leading: const Icon(Icons.message_outlined),
                    title: Text(text),
                    subtitle: _SenderLabel(playerId: senderId),
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
                    decoration: const InputDecoration(labelText: 'Ich bin'),
                    items: players
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
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
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'z. B. "Ich komme 10 Min. später"',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Senden'),
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
    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Nachricht eingeben.')),
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
      await _service.sendMessage(widget.sessionId, _selectedPlayerId!, text);
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Senden: $e')),
        );
      }
    }
  }
}

class _SenderLabel extends StatelessWidget {
  final String playerId;
  const _SenderLabel({required this.playerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Player?>(
      future: FirestoreService().getPlayer(playerId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '…';
        return Text('von $name');
      },
    );
  }
}