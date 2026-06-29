import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart' show Color;
import 'package:just_audio/just_audio.dart';

Future<AudioPlayerHandler> initAudioService() {
  return AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.najot.nur.audio',
      androidNotificationChannelName: 'Najot Nur Audio',
      androidNotificationChannelDescription:
          'Audio kitoblar uchun media boshqaruvlari',
      androidNotificationOngoing: true,
      // Keep notification (and lock-screen controls) visible while paused.
      androidStopForegroundOnPause: false,
      androidNotificationClickStartsActivity: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      notificationColor: Color(0xFF8A1538), // AppColors.wine
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  static const _skipInterval = Duration(seconds: 10);

  bool _interrupted = false;

  AudioPlayerHandler() {
    _initSession();

    // Forward just_audio events to audio_service clients (notification, lock screen).
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Keep the media item duration up to date so the lock-screen seek bar works.
    _player.durationStream.listen((duration) {
      final current = mediaItem.valueOrNull;
      if (current == null) return;
      mediaItem.add(current.copyWith(duration: duration));
    });
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Pause when headphones are unplugged.
    session.becomingNoisyEventStream.listen((_) => _player.pause());

    // Pause/resume around phone calls / other audio interruptions.
    session.interruptionEventStream.listen(_handleInterruption);
  }

  Future<void> _handleInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      if (_player.playing) {
        _interrupted = true;
        await _player.pause();
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          break;
      }
      if (_interrupted && !_player.playing) {
        _interrupted = false;
        await _player.play();
      }
    }
  }

  Future<void> loadUrl(
    String url, {
    String title = '',
    String artist = '',
    Uri? artUri,
  }) async {
    await _player.stop();
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist,
      artUri: artUri,
      duration: Duration.zero,
    );
    mediaItem.add(item);
    final duration = await _player.setUrl(url);
    if (duration != null) {
      mediaItem.add(item.copyWith(duration: duration));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> rewind() => _seekBy(-_skipInterval);

  @override
  Future<void> fastForward() => _seekBy(_skipInterval);

  Future<void> _seekBy(Duration delta) async {
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;
    final raw = pos + delta;
    final target = raw < Duration.zero
        ? Duration.zero
        : raw > dur
            ? dur
            : raw;
    await _player.seek(target);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.playPause,
        MediaAction.stop,
      },
      // Compact notification shows: rewind | play-pause | fast-forward
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
