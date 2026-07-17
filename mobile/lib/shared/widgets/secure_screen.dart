import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/security_channel.dart';

/// Turns on screenshot/recording protection (Android FLAG_SECURE) while this
/// widget is mounted and releases it when the last one leaves the tree.
///
/// Wrap only the screens that show paid content (video lesson screens);
/// everywhere else capturing stays allowed. Ref-counted so nested/stacked
/// secure routes don't fight over the flag.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});
  final Widget child;

  /// True while at least one [SecureScreen] is mounted. The capture-warning
  /// overlay uses this to only flag recordings on protected screens (iOS
  /// can't block capture, only warn).
  static final ValueNotifier<bool> protectionActive = ValueNotifier(false);

  static int _mounted = 0;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    SecureScreen._mounted++;
    if (SecureScreen._mounted == 1) {
      SecureScreen.protectionActive.value = true;
      // Fire-and-forget: the flag lands within a frame; failure (e.g. on a
      // platform without the channel) must not break the screen itself.
      SecurityChannel.instance
          .setSecure(enabled: true)
          .catchError((Object e) {
        debugPrint('SecureScreen.setSecure(true) failed: $e');
        return false;
      });
    }
  }

  @override
  void dispose() {
    SecureScreen._mounted--;
    if (SecureScreen._mounted == 0) {
      SecureScreen.protectionActive.value = false;
      SecurityChannel.instance
          .setSecure(enabled: false)
          .catchError((Object e) {
        debugPrint('SecureScreen.setSecure(false) failed: $e');
        return false;
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
