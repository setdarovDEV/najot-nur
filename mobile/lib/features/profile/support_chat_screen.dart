import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/support_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import 'support_chat_service.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<SupportMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _live = false;
  StreamSubscription<SupportChatEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachWebSocket();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!ref.read(authControllerProvider).isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final msgs = await ref.read(supportRepositoryProvider).messages();
      if (mounted) setState(() => _messages = msgs);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _attachWebSocket() {
    if (!ref.read(authControllerProvider).isLoggedIn) return;
    final service = ref.read(supportChatServiceProvider);
    unawaited(service.connect());
    _wsSub = service.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case SupportChatConnected():
          if (!_live) setState(() => _live = true);
        case SupportChatDisconnected():
          if (_live) setState(() => _live = false);
        case SupportMessageReceived(:final message):
          setState(() {
            _messages = _messages.any((m) => m.id == message.id)
                ? _messages
                : [..._messages, message];
          });
          _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await ref.read(supportRepositoryProvider).send(text);
      _ctrl.clear();
      if (mounted) {
        setState(() {
          _messages = _messages.any((m) => m.id == msg.id)
              ? _messages
              : [..._messages, msg];
        });
        _scrollToBottom();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;

    if (!isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.supportChatTitle),
        titleSpacing: 20,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _live ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _live ? 'Onlayn' : 'Oflayn',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const AppLoader()
                : _messages.isEmpty
                    ? _EmptyChat(label: l.chatNoMessages)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _Bubble(
                          msg: _messages[i],
                          supportLabel: l.chatSupport,
                        ),
                      ),
          ),
          _ChatInputBar(
            ctrl: _ctrl,
            sending: _sending,
            hint: l.chatInputHint,
            sendLabel: l.chatSend,
            sendingLabel: l.chatSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.wine100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 36, color: AppColors.wine),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.supportLabel});
  final SupportMessage msg;
  final String supportLabel;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isFromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? AppLocalizations.of(context).user : supportLabel,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.wine : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: isUser ? null : Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.ink,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.ctrl,
    required this.sending,
    required this.hint,
    required this.sendLabel,
    required this.sendingLabel,
    required this.onSend,
  });

  final TextEditingController ctrl;
  final bool sending;
  final String hint;
  final String sendLabel;
  final String sendingLabel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              enabled: !sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.wine100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: sending
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 46,
                    height: 46,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: AppColors.wine, strokeWidth: 2.5),
                      ),
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('send'),
                    width: 46,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wine,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
