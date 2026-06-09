import 'package:flutter/material.dart';

import '../theme/studio_theme.dart';
import 'record_mode_overlays.dart';

/// Assistant/user message text with optional live streaming cursor.
class StreamingMessageBody extends StatelessWidget {
  const StreamingMessageBody({
    super.key,
    required this.text,
    required this.streaming,
    required this.isUser,
  });

  final String text;
  final bool streaming;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      height: 1.5,
      fontSize: 15,
      color: isUser ? Colors.white : StudioColors.textPrimary,
    );

    if (!streaming) {
      return Text(text, style: style);
    }

    if (text.isEmpty) {
      return const BlinkingStreamCursor();
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(text, style: style),
        const BlinkingStreamCursor(),
      ],
    );
  }
}
