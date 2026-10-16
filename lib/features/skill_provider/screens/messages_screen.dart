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
  bool _loadingThreads = true;
  bool _loadingMessages = false;
  bool _loadInProgress = false;
  bool _reloadQueued = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _loadThreads(forceRefresh: false);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    _loadThreads(forceRefresh: true);
  }

  Future<void> _loadThreads({bool forceRefresh = false}) async {
    if (_loadInProgress) {
      _reloadQueued = true;
      return;
    }
    _loadInProgress = true;
    final showSpinner = _threads.isEmpty;
    if (showSpinner && mounted) {
      setState(() => _loadingThreads = true);
    }
    try {
      final providerId = await resolveProviderId();
      final threads = await _service.getThreads(
        providerId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _loadingThreads = false;
      });
      if (_selected == null && threads.isNotEmpty) {
        await _selectThread(threads.first, forceRefresh: forceRefresh);
      } else if (_selected != null) {
        final stillExists =
            threads.any((thread) => thread.id == _selected!.id);
        if (!stillExists && threads.isNotEmpty) {
          await _selectThread(threads.first, forceRefresh: forceRefresh);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingThreads = false);
      }
    } finally {
      _loadInProgress = false;
      if (_reloadQueued) {
        _reloadQueued = false;
        await _loadThreads(forceRefresh: true);
      }
    }
  }

  Future<void> _selectThread(
    MessageThread thread, {
    bool forceRefresh = false,
  }) async {
    if (mounted) {
      setState(() {
        _selected = thread;
        _loadingMessages = true;
      });
    }
    try {
      final msgs = await _service.getMessages(
        thread.id,
        forceRefresh: forceRefresh,
      );
      if (!mounted || _selected?.id != thread.id) return;
      setState(() {
        _messages = msgs;
        _loadingMessages = false;
      });
    } catch (_) {
      if (!mounted || _selected?.id != thread.id) return;
      setState(() => _loadingMessages = false);
    }
  }

  Future<void> _send() async {
    if (_selected == null || _textController.text.trim().isEmpty) return;
    await _service.sendMessage(
      threadId: _selected!.id,
      text: _textController.text.trim(),
    );
    _textController.clear();
    await _selectThread(_selected!, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.teacherPageBackground,
      appBar: const TealPageHeader(title: 'Messages'),
      body: _loadingThreads
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Row(
              children: [
                Container(
                  width: 280,
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _threads.length,
                    itemBuilder: (_, i) {
                      final t = _threads[i];
                      final selected = _selected?.id == t.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Material(
                          color: selected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.teacherAccentSky
                                  .withValues(alpha: 0.14),
                              child: Text(
                                t.learnerName.isNotEmpty ? t.learnerName[0] : '?',
                                style: const TextStyle(
                                  color: AppTheme.teacherAccentSky,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(t.learnerName,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(t.lastMessage, maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            onTap: () => _selectThread(t, forceRefresh: false),
                          ),
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE3EEEC)),
                            ),
                          ),
                          width: double.infinity,
                          child: Text(_selected!.learnerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              )),
                        ),
                      Expanded(
                        child: _loadingMessages
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : ListView.builder(
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
                                constraints: const BoxConstraints(maxWidth: 420),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: m.isFromProvider
                                      ? AppTheme.teacherHeaderGradient
                                      : null,
                                  color: m.isFromProvider
                                      ? null
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(
                                      m.isFromProvider ? 18 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      m.isFromProvider ? 4 : 18,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  m.text,
                                  style: TextStyle(
                                    color: m.isFromProvider
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  filled: true,
                                  fillColor: Color(0xFFF4F8F7),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton.filled(
                              onPressed: _send,
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.send),
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
