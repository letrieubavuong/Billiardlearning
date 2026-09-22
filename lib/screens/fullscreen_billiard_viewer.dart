import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FullscreenBilliardViewer extends StatefulWidget {
  final Widget child;

  const FullscreenBilliardViewer({super.key, required this.child});

  @override
  State<FullscreenBilliardViewer> createState() =>
      _FullscreenBilliardViewerState();
}

class _FullscreenBilliardViewerState extends State<FullscreenBilliardViewer> {
  @override
  void initState() {
    super.initState();
    // Hide status bar & navigation bar (immersive mode)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Force landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore system UI bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Restore default orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: widget.child,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
