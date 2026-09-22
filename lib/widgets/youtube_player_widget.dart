import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FullScreenPlayerManager {
  static final ValueNotifier<YoutubePlayerController?> activeController =
      ValueNotifier(null);
}

class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;
  final int? startSeconds;
  final int? endSeconds;
  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    this.startSeconds,
    this.endSeconds,
  });

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _isWindows = false;

  @override
  void initState() {
    super.initState();
    _isWindows = !kIsWeb && Platform.isWindows;
    if (!_isWindows) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          forceHD: false,
          startAt: widget.startSeconds ?? 0,
          endAt: widget.endSeconds,
        ),
      );
      _controller.addListener(_fullscreenListener);
    }
  }

  void _fullscreenListener() {
    if (!mounted) return;
    if (_isWindows) return;
    if (_controller.value.isFullScreen) {
      if (FullScreenPlayerManager.activeController.value != _controller) {
        FullScreenPlayerManager.activeController.value = _controller;
      }
    } else {
      if (FullScreenPlayerManager.activeController.value == _controller) {
        FullScreenPlayerManager.activeController.value = null;
      }
    }
    setState(() {});
  }

  @override
  void deactivate() {
    if (!_isWindows) {
      _controller.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (!_isWindows) {
      _controller.removeListener(_fullscreenListener);
      if (FullScreenPlayerManager.activeController.value == _controller) {
        FullScreenPlayerManager.activeController.value = null;
      }
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _launchYoutubeUrl() async {
    final url = Uri.parse("https://www.youtube.com/watch?v=${widget.videoId}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWindows) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: InkWell(
          onTap: _launchYoutubeUrl,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://img.youtube.com/vi/${widget.videoId}/0.jpg",
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.black54),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 48,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller.value.isFullScreen) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.cyanAccent,
            progressColors: const ProgressBarColors(
              playedColor: Colors.cyanAccent,
              handleColor: Colors.cyanAccent,
            ),
          ),
        ),
      ),
    );
  }
}
