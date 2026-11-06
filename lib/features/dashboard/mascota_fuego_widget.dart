import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Presenta la ilustración en reposo y reproduce un clip aleatorio por toque.
class MascotaFuegoWidget extends StatefulWidget {
  const MascotaFuegoWidget({
    super.key,
    this.onTap,
    this.width = 156,
    this.height = 180,
  });

  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  State<MascotaFuegoWidget> createState() => _MascotaFuegoWidgetState();
}

class _MascotaFuegoWidgetState extends State<MascotaFuegoWidget> {
  static const _clips = <String>[
    'assets/animations/saludo.mp4',
    'assets/animations/hidratarse.mp4',
  ];

  final List<VideoPlayerController> _players = [];
  final Random _random = Random();
  int _activeIndex = 0;
  int _playSession = 0;
  bool _playing = false;
  bool _ready = false;
  bool _failed = false;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializePlayers());
  }

  Future<void> _initializePlayers() async {
    try {
      for (final asset in _clips) {
        final player = VideoPlayerController.asset(asset);
        _players.add(player);
        await player.initialize();
        await player.setVolume(0);
        await player.setLooping(false);
        player.addListener(() => _handlePlayerUpdate(player));
      }
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _handlePlayerUpdate(VideoPlayerController player) {
    if (!mounted ||
        !_playing ||
        _switching ||
        player != _players[_activeIndex]) {
      return;
    }
    final value = player.value;
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.isCompleted) {
      setState(() => _playing = false);
    }
  }

  Future<void> _playRandomClip() async {
    if (!_ready ||
        _failed ||
        _playing ||
        _switching ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    widget.onTap?.call();
    final session = ++_playSession;
    _switching = true;
    final previous = _players[_activeIndex];
    _activeIndex = _random.nextInt(_players.length);
    final next = _players[_activeIndex];
    try {
      await previous.pause();
      await next.seekTo(Duration.zero);
      if (mounted && session == _playSession) {
        setState(() => _playing = true);
        await next.play();
      }
    } catch (_) {
      if (mounted) setState(() => _playing = false);
    } finally {
      _switching = false;
    }
  }

  @override
  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _players.isEmpty ? null : _players[_activeIndex];
    final canPlay = _ready && !_failed && !_playing && !_switching;
    return Semantics(
      button: true,
      enabled: canPlay,
      label: 'Mascota solar. Reproducir una animación aleatoria',
      child: MouseRegion(
        cursor: canPlay ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canPlay ? () => unawaited(_playRandomClip()) : null,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_playing || !_ready || _failed)
                  Image.asset(
                    'assets/mascota/fuego_frente.png',
                    width: widget.width,
                    height: widget.height,
                    fit: BoxFit.contain,
                    semanticLabel: 'Mascota de fuego',
                  ),
                if (_playing && _ready && !_failed && controller != null)
                  _VideoSurface(
                    controller: controller,
                    width: widget.width,
                    height: widget.height,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.controller,
    required this.width,
    required this.height,
  });

  final VideoPlayerController controller;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (!controller.value.isInitialized) return const SizedBox.shrink();
      final video = SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
      return video;
    },
  );
}
