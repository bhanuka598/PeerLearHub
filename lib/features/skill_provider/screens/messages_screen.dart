import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/provider_message.dart';
import '../services/message_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _service = MessageService.instance;
  List<MessageThread> _threads = [];
  MessageThread? _selected;
  List<ProviderMessage> _messages = [];
  final _textController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final threads = await _service.getThreads(getCurrentProviderId());
    if (mounted) {
      setState(() {
        _threads = threads;
        _loading = false;
        if (_selected == null && threads.isNotEmpty) {
          _selectThread(threads.first);
        }
      });
    }
  }

  Future<void> _selectThread(MessageThread thread) async {
    final msgs = await _service.getMessages(thread.id);
    if (mounted) {
      setState(() {
        _selected = thread;
        _messages = msgs;
      });
    }
  }

  Future<void> _send() async {
    if (_selected == null || _textController.text.trim().isEmpty) return;
    await _service.sendMessage(
      threadId: _selected!.id,
      text: _textController.text.trim(),
    );
    _textController.clear();
    await _selectThread(_selected!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Messages'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Row(
              children: [
                SizedBox(
                  width: 280,
                  child: ListView.builder(
                    itemCount: _threads.length,
                    itemBuilder: (_, i) {
                      final t = _threads[i];
                      final selected = _selected?.id == t.id;
                      return ListTile(
                        selected: selected,
                        selectedTileColor:
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.iconBackground,
                          child: Text(t.learnerName[0]),
                        ),
                        title: Text(t.learnerName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(t.lastMessage, maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        onTap: () => _selectThread(t),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      if (_selected != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          width: double.infinity,
                          child: Text(_selected!.learnerName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final m = _messages[i];
                            return Align(
                              alignment: m.isFromProvider
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: m.isFromProvider
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  m.text,
                                  style: TextStyle(
                                    color: m.isFromProvider
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _send,
                              icon: const Icon(Icons.send,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
