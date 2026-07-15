import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/theme/app_colors.dart';

/// Generic in-app WebView used for both Uzum Nasiya steps:
///  - buyer registration (opened when check-status says the user isn't
///    verified yet)
///  - OTP/SMS confirmation after a contract is created
///
/// Pops with `true` the moment navigation reaches a URL starting with
/// [returnUrlPrefix] (the app never actually needs that URL to resolve —
/// it's a sentinel we handed to Uzum Nasiya as `callback`). Pops with
/// `false` if the user closes the screen manually before that happens.
class NasiyaWebViewScreen extends StatefulWidget {
  const NasiyaWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.returnUrlPrefix,
  });

  final String url;
  final String title;
  /// When null, the screen never auto-closes — only the close button does.
  final String? returnUrlPrefix;

  @override
  State<NasiyaWebViewScreen> createState() => _NasiyaWebViewScreenState();
}

class _NasiyaWebViewScreenState extends State<NasiyaWebViewScreen> {
  double _progress = 0;
  bool _closed = false;

  void _closeWithResult(bool result) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _closeWithResult(false),
        ),
      ),
      body: Column(
        children: [
          if (_progress < 1)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2,
              color: AppColors.wine,
              backgroundColor: AppColors.line,
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                thirdPartyCookiesEnabled: true,
                sharedCookiesEnabled: true,
              ),
              onProgressChanged: (controller, progress) {
                if (!mounted) return;
                setState(() => _progress = progress / 100);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url?.toString() ?? '';
                final prefix = widget.returnUrlPrefix;
                if (prefix != null && url.startsWith(prefix)) {
                  _closeWithResult(true);
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
          ),
        ],
      ),
    );
  }
}
