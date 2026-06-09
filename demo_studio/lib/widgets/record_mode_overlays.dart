import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/studio_theme.dart';

/// Marketing overlays for LinkedIn / demo screen recordings.
class RecordModeBadge extends StatelessWidget {
  const RecordModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            StudioColors.accent.withValues(alpha: 0.95),
            StudioColors.userGradientEnd.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: StudioColors.accent.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 6),
            Text(
              'REAL-TIME SSE STREAMING',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordModeCodeStrip extends StatelessWidget {
  const RecordModeCodeStrip({super.key});

  static const _snippet =
      "await for (final token in client.chatStream(...)) { ... }";

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: StudioColors.accent.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _snippet,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                height: 1.35,
                color: const Color(0xFF7DD3FC),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Blinking block cursor shown while tokens are streaming in.
class BlinkingStreamCursor extends StatefulWidget {
  const BlinkingStreamCursor({super.key, this.color = StudioColors.accent});

  final Color color;

  @override
  State<BlinkingStreamCursor> createState() => _BlinkingStreamCursorState();
}

class _BlinkingStreamCursorState extends State<BlinkingStreamCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
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
      opacity: Tween(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Text(
        '▍',
        style: TextStyle(
          color: widget.color,
          fontWeight: FontWeight.w300,
          height: 1.5,
        ),
      ),
    );
  }
}
