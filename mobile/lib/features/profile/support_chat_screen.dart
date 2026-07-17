import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    if (!isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Glass header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: GlassEntrance(
                    child: Row(
                      children: [
                        _GlassBackButton(onTap: () => context.pop()),
                        Expanded(
                          child: Text(
                            l.supportChatTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.glassFillDark
                                : AppColors.glassFillLight,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: dark
                                  ? AppColors.glassStrokeDark
                                  : AppColors.glassStrokeLight,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _live
                                      ? AppColors.success
                                      : mutedColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _live ? 'Onlayn' : 'Oflayn',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const AppLoader()
                      : _messages.isEmpty
                          ? _EmptyChat(label: l.chatNoMessages)
                          : ListView.builder(
                              controller: _scroll,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AppColors.glassFillDark : AppColors.glassFillLight,
          border: Border.all(
            color:
                dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight,
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassEntrance(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.wine300.withValues(alpha: 0.16)
                      : AppColors.wine100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 36, color: accent),
              ),
            ),
            const SizedBox(height: 16),
            GlassEntrance(
              delay: GlassMotion.entranceStep,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat bubble: own messages ride the wine gradient, the other side sits on
/// a frosted fill with a hairline stroke.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.supportLabel});
  final SupportMessage msg;
  final String supportLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
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
              style: TextStyle(
                fontSize: 11,
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.wineGradient : null,
                color: isUser
                    ? null
                    : (dark
                        ? AppColors.glassFillDark
                        : AppColors.glassFillLight),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: dark
                            ? AppColors.glassStrokeDark
                            : AppColors.glassStrokeLight,
                        width: 0.5,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.wine.withValues(alpha: 0.24)
                        : (dark
                            ? AppColors.glassShadowDark
                            : AppColors.glassShadowLight),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : textColor,
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

/// Frosted bottom input bar (glass chrome): blurred fill, top hairline,
/// gradient send button.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final fill = dark ? AppColors.glassFillDark : AppColors.glassFillLight;
    final stroke =
        dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurChrome,
          sigmaY: AppColors.glassBlurChrome,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: fill,
            border: Border(top: BorderSide(color: stroke, width: 0.5)),
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
                  style: TextStyle(fontSize: 15, color: textColor),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: mutedColor),
                    filled: true,
                    fillColor: dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.wine.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: stroke, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: stroke, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: dark ? AppColors.wine300 : AppColors.wine,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: sending
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 46,
                        height: 46,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color:
                                  dark ? AppColors.wine300 : AppColors.wine,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    : GlassPressable(
                        key: const ValueKey('send'),
                        onTap: onSend,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.wineGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.wine.withValues(alpha: 0.30),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
