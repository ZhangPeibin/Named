import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_providers.dart';

@immutable
class AudioPlaybackState {
  const AudioPlaybackState({
    this.activeId,
    this.isPlaying = false,
    this.isLoading = false,
    this.speed = 1.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  /// The id of the clip currently loaded into the player, if any.
  final String? activeId;
  final bool isPlaying;
  final bool isLoading;

  /// The current playback speed. Shared across the app.
  final double speed;
  final Duration position;
  final Duration duration;

  bool isPlayingId(String id) => activeId == id && isPlaying;
  bool isLoadingId(String id) => activeId == id && isLoading;

  AudioPlaybackState copyWith({
    Object? activeId = _sentinel,
    bool? isPlaying,
    bool? isLoading,
    double? speed,
    Duration? position,
    Duration? duration,
  }) {
    return AudioPlaybackState(
      activeId: identical(activeId, _sentinel)
          ? this.activeId
          : activeId as String?,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

const Object _sentinel = Object();

/// A single [AudioPlayer] shared by the whole app, so only one clip plays at a
/// time and every play/speed control stays consistent.
class AudioPlaybackController extends Notifier<AudioPlaybackState> {
  late final AudioPlayer _player;
  final Map<String, Uint8List> _byteCache = {};
  final StreamController<String> _completions =
      StreamController<String>.broadcast();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  String? _currentUrl;
  int _requestId = 0;

  /// Emits the [AudioPlaybackState.activeId] whenever a clip finishes.
  Stream<String> get completions => _completions.stream;

  @override
  AudioPlaybackState build() {
    _player = AudioPlayer();
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
    _stateSub = _player.onPlayerStateChanged.listen((value) {
      if (value == PlayerState.completed) {
        return;
      }
      state = state.copyWith(isPlaying: value == PlayerState.playing);
    });
    _positionSub = _player.onPositionChanged.listen((value) {
      state = state.copyWith(position: value);
    });
    _durationSub = _player.onDurationChanged.listen((value) {
      state = state.copyWith(duration: value);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      final id = state.activeId;
      state = state.copyWith(isPlaying: false, position: state.duration);
      if (id != null) {
        _completions.add(id);
      }
    });
    ref.onDispose(() {
      unawaited(_stateSub?.cancel());
      unawaited(_positionSub?.cancel());
      unawaited(_durationSub?.cancel());
      unawaited(_completeSub?.cancel());
      unawaited(_completions.close());
      unawaited(_player.dispose());
    });
    return const AudioPlaybackState();
  }

  /// Toggles playback for [id]. If another clip is playing it is replaced.
  /// [resolveUrl] is called lazily so callers can synthesize audio first.
  Future<void> toggle(
    String id,
    Future<String?> Function() resolveUrl, {
    double? speed,
  }) async {
    final url = await resolveUrl();
    if (url == null) {
      return;
    }
    final targetSpeed = speed ?? state.speed;

    if (state.activeId == id && _currentUrl == url) {
      if (state.isPlaying) {
        await _player.pause();
        return;
      }
      if (_player.state == PlayerState.paused) {
        await _player.setPlaybackRate(targetSpeed);
        state = state.copyWith(speed: targetSpeed);
        await _player.resume();
        return;
      }
    }
    await _play(id, url, targetSpeed);
  }

  /// Forces a (re)play for [id].
  Future<void> play(
    String id,
    Future<String?> Function() resolveUrl, {
    double? speed,
  }) async {
    final url = await resolveUrl();
    if (url == null) {
      return;
    }
    await _play(id, url, speed ?? state.speed);
  }

  Future<void> _play(String id, String url, double speed) async {
    final token = ++_requestId;
    state = state.copyWith(
      activeId: id,
      isLoading: true,
      isPlaying: false,
      speed: speed,
      position: Duration.zero,
      duration: Duration.zero,
    );
    final bytes = await _loadBytes(url);
    if (token != _requestId) {
      return;
    }
    await _player.stop();
    await _player.setPlaybackRate(speed);
    _currentUrl = url;
    await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
    if (token != _requestId) {
      return;
    }
    state = state.copyWith(activeId: id, isLoading: false, speed: speed);
  }

  Future<void> setSpeed(double speed, {String? id}) async {
    state = state.copyWith(speed: speed);
    if (id == null || state.activeId == id) {
      await _player.setPlaybackRate(speed);
    }
  }

  /// Applies a speed to the current player without changing the shared state
  /// speed (used by the reader, which has its own speed control).
  Future<void> applyPlaybackRate(double speed) async {
    await _player.setPlaybackRate(speed);
  }

  Future<void> seekBy(int seconds) async {
    final target = state.position + Duration(seconds: seconds);
    await seekTo(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> pause() async {
    await _player.pause();
  }

  /// Stops playback if [id] is the active clip.
  Future<void> stopIf(String id) async {
    if (state.activeId == id) {
      await stop();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
    state = const AudioPlaybackState();
  }

  Future<Uint8List> _loadBytes(String url) async {
    final cached = _byteCache[url];
    if (cached != null) {
      return cached;
    }
    final data = await ref.read(audioBytesApiProvider).fetch(url);
    final bytes = Uint8List.fromList(data);
    _byteCache[url] = bytes;
    return bytes;
  }
}

final audioPlaybackControllerProvider =
    NotifierProvider<AudioPlaybackController, AudioPlaybackState>(
      AudioPlaybackController.new,
    );
