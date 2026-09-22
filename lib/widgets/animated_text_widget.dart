import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedTextWidget extends StatelessWidget {
  final String text;
  final String type; // 'marquee', 'typewriter', 'fade', 'scale'
  final Color color;
  final double fontSize;
  final double speed; // 1.0 (default), higher is faster

  const AnimatedTextWidget({
    super.key,
    required this.text,
    this.type = 'marquee',
    this.color = Colors.cyanAccent,
    this.fontSize = 16.0,
    this.speed = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget animatedChild;

    switch (type) {
      case 'typewriter':
        animatedChild = TypewriterText(
          text: text,
          color: color,
          fontSize: fontSize,
          speed: speed,
        );
        break;
      case 'fade':
        animatedChild = FadePulseText(
          text: text,
          color: color,
          fontSize: fontSize,
          speed: speed,
        );
        break;
      case 'scale':
        animatedChild = ScalePulseText(
          text: text,
          color: color,
          fontSize: fontSize,
          speed: speed,
        );
        break;
      case 'marquee':
      default:
        animatedChild = MarqueeText(
          text: text,
          color: color,
          fontSize: fontSize,
          speed: speed,
        );
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Center(child: animatedChild),
    );
  }
}

// 1. MARQUEE (Scrolling Text)
class MarqueeText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double speed;

  const MarqueeText({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.speed,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!mounted) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    // Calculate duration based on speed and length
    final double baseSpeed = 40.0 * widget.speed; // pixels per second
    final int durationMs =
        ((maxScroll - _scrollController.offset) / baseSpeed * 1000).round();

    _scrollController
        .animateTo(
          maxScroll,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        )
        .then((_) {
          if (mounted) {
            _scrollController.jumpTo(0.0);
            // Delay a bit before starting next loop
            _timer = Timer(const Duration(milliseconds: 800), _startScrolling);
          }
        });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// 2. TYPEWRITER (Auto-typing Text)
class TypewriterText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double speed;

  const TypewriterText({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.speed,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    final int intervalMs = (100 / widget.speed).round().clamp(10, 500);
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_charIndex];
          _charIndex++;
        });
      } else {
        _timer?.cancel();
        // Pause at completion, then restart
        _timer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _displayedText = '';
              _charIndex = 0;
            });
            _startTyping();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _displayedText,
            style: TextStyle(
              color: widget.color,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Blinking cursor
        BlinkingCursor(color: widget.color, fontSize: widget.fontSize),
      ],
    );
  }
}

class BlinkingCursor extends StatefulWidget {
  final Color color;
  final double fontSize;

  const BlinkingCursor({
    super.key,
    required this.color,
    required this.fontSize,
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        '|',
        style: TextStyle(
          color: widget.color,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 3. FADE PULSE
class FadePulseText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double speed;

  const FadePulseText({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.speed,
  });

  @override
  State<FadePulseText> createState() => _FadePulseTextState();
}

class _FadePulseTextState extends State<FadePulseText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final int durationMs = (1200 / widget.speed).round().clamp(200, 5000);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// 4. SCALE PULSE
class ScalePulseText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double speed;

  const ScalePulseText({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.speed,
  });

  @override
  State<ScalePulseText> createState() => _ScalePulseTextState();
}

class _ScalePulseTextState extends State<ScalePulseText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final int durationMs = (1000 / widget.speed).round().clamp(200, 5000);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
