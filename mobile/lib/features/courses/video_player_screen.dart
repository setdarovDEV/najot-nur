import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/secure_screen.dart';

/// In-app lesson video player.
///
/// Replaces the old "hand the URL to an external app" flow. Playing inside the
/// app matters for three reasons: an HLS source starts in about a second
/// instead of downloading the whole MP4 first, the screenshot/recording block
/// keeps applying to paid content, and the buffering state is visible to the
/// learner instead of being a frozen external player.
///
/// [url] is preferably an HLS master playlist; a progressive MP4 also works
/// and is what the screen gets while a lesson is still transcoding.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
    this.isHls = false,
  });

  final String url;
  final String title;

  /// Whether [url] is an HLS playlist — only affects the quality hint shown
  /// to the user; the player detects the format itself.
  final bool isHls;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Lessons are landscape-friendly but the app is portrait-locked; the
    // player is the one screen where rotating is expected.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      // Access is carried in the URL (playback token for playlists, presigned
      // signature for segments), so no auth headers are sent — S3/R2 reject
      // requests that present both query-string auth and an auth header.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _chewie = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          playbackSpeeds: const [0.75, 1.0, 1.25, 1.5, 2.0],
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.wine,
            handleColor: AppColors.wine,
            bufferedColor: Colors.white24,
            backgroundColor: Colors.white10,
          ),
          errorBuilder: (_, message) => _ErrorView(message: message),
        );
      });
    } catch (e) {
      await controller.dispose();
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SecureScreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: _error != null
              ? _ErrorView(message: l.videoOpenError)
              : _chewie == null
                  ? const _LoadingView()
                  : Chewie(controller: _chewie!),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
        SizedBox(height: 16),
        Text(
          'Video tayyorlanmoqda…',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
