import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_deepseek/flutter_deepseek.dart';

import '../secrets.dart';
import '../theme/studio_theme.dart';
import '../widgets/record_mode_overlays.dart';
import '../widgets/streaming_message_body.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialRecordMode = false});

  /// Turn on LinkedIn capture overlays (badge + code strip). Also via
  /// `flutter run --dart-define=RECORD_MODE=true`.
  final bool initialRecordMode;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final DeepSeekClient _client;

  String _model = DeepSeekModel.chat;
  bool _streaming = true;
  bool _webSearch = false;
  bool _busy = false;
  late bool _recordMode;

  final List<_Message> _messages = [];

  static const _suggestions = [
    'Explain Flutter widgets in 3 bullets',
    'Write a haiku about Dart streams',
    'What makes SSE streaming great for chat UIs?',
  ];

  @override
  void initState() {
    super.initState();
    _recordMode = widget.initialRecordMode;
    _client = DeepSeekClient(apiKey: kDeepSeekApiKey);
  }

  @override
  void dispose() {
    _client.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _keyReady =>
      kDeepSeekApiKey.isNotEmpty &&
      !kDeepSeekApiKey.contains('PASTE_YOUR') &&
      !kDeepSeekApiKey.contains('sk-your-deepseek');

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _input.text).trim();
    if (text.isEmpty || _busy) return;

    if (!_keyReady) {
      _snack('Add your API key in lib/secrets.dart');
      return;
    }

    setState(() {
      _messages.add(_Message.user(text));
      _input.clear();
      _busy = true;
    });
    _scrollToEnd();

    try {
      if (_model == DeepSeekModel.reasoner) {
        final result = await _client.reason(prompt: text);
        if (!mounted) return;
        setState(() {
          _messages.add(
            _Message.assistant(
              result.content,
              reasoning: result.reasoningContent,
            ),
          );
          _busy = false;
        });
      } else if (_webSearch) {
        // Tool loop is non-streaming: the model may call web_search first.
        await for (final event in _client.chatWithTools(
          messages: [ChatMessage.user(text)],
          executor: WebToolExecutor(_client),
          model: _model,
        )) {
          if (!mounted) return;
          switch (event) {
            case ToolCallRequested(:final call):
              setState(() => _messages.add(_Message.status(_describe(call))));
            case ToolCallCompleted():
              break;
            case ChatAnswer(text: final answer):
              setState(() {
                _messages.add(_Message.assistant(answer));
                _busy = false;
              });
          }
          _scrollToEnd();
        }
      } else if (_streaming) {
        setState(() => _messages.add(_Message.assistant('', streaming: true)));
        final buffer = StringBuffer();
        await for (final token in _client.chatStream(
          messages: [ChatMessage.user(text)],
          model: _model,
        )) {
          buffer.write(token);
          if (!mounted) return;
          setState(() {
            _messages[_messages.length - 1] =
                _Message.assistant(buffer.toString(), streaming: true);
          });
          _scrollToEnd();
        }
        if (!mounted) return;
        setState(() {
          _messages[_messages.length - 1] =
              _Message.assistant(buffer.toString());
          _busy = false;
        });
      } else {
        final response = await _client.chat(
          messages: [ChatMessage.user(text)],
          model: _model,
        );
        if (!mounted) return;
        setState(() {
          _messages.add(_Message.assistant(response.text));
          _busy = false;
        });
      }
    } on DeepSeekException catch (e) {
      if (!mounted) return;
      _snack(e.message);
      setState(() {
        if (_messages.isNotEmpty && _messages.last.streaming) {
          _messages.removeLast();
        }
        _busy = false;
      });
    }

    _scrollToEnd();
  }

  String _describe(ToolCall call) {
    try {
      final args = jsonDecode(call.function.arguments) as Map<String, dynamic>;
      return 'Searching the web: ${args['query']}';
    } catch (_) {
      return 'Calling ${call.function.name}…';
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: StudioColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message),
      ),
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = _recordMode;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E14),
              Color(0xFF0F1724),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  _Header(
                    model: _model,
                    streaming: _streaming,
                    webSearch: _webSearch,
                    busy: _busy,
                    recordMode: _recordMode,
                    compact: compact,
                    onModelChanged: (m) => setState(() => _model = m),
                    onStreamingChanged: (v) => setState(() => _streaming = v),
                    onWebSearchChanged: (v) => setState(() => _webSearch = v),
                    onRecordModeToggle: () =>
                        setState(() => _recordMode = !_recordMode),
                  ),
                  Expanded(
                    child: _messages.isEmpty
                        ? _EmptyState(
                            suggestions: _suggestions,
                            onTap: _send,
                            compact: compact,
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: EdgeInsets.fromLTRB(
                              20,
                              compact ? 4 : 8,
                              20,
                              _recordMode ? 100 : 24,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _MessageTile(
                              message: _messages[index],
                              emphasizeStreaming: _recordMode,
                            ),
                          ),
                  ),
                  _Composer(
                    controller: _input,
                    busy: _busy,
                    compact: compact,
                    onSend: () => _send(),
                  ),
                ],
              ),
              if (_recordMode) ...[
                const Positioned(
                  top: 8,
                  right: 16,
                  child: RecordModeBadge(),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: compact ? 76 : 84,
                  child: const RecordModeCodeStrip(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.model,
    required this.streaming,
    required this.webSearch,
    required this.busy,
    required this.recordMode,
    required this.compact,
    required this.onModelChanged,
    required this.onStreamingChanged,
    required this.onWebSearchChanged,
    required this.onRecordModeToggle,
  });

  final String model;
  final bool streaming;
  final bool webSearch;
  final bool busy;
  final bool recordMode;
  final bool compact;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<bool> onStreamingChanged;
  final ValueChanged<bool> onWebSearchChanged;
  final VoidCallback onRecordModeToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 4 : 10, 12, compact ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      StudioColors.userGradientStart,
                      StudioColors.userGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DeepSeek Studio',
                      style: theme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        fontSize: compact ? 20 : null,
                      ),
                    ),
                    if (!compact)
                      Text(
                        'flutter_deepseek · pub.dev',
                        style: theme.bodySmall?.copyWith(
                          color: StudioColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (busy) const _PulsingDot(),
              IconButton(
                tooltip: recordMode
                    ? 'Record mode on'
                    : 'Record mode (LinkedIn overlays)',
                onPressed: onRecordModeToggle,
                icon: Icon(
                  recordMode ? Icons.videocam : Icons.videocam_outlined,
                  color:
                      recordMode ? StudioColors.accent : StudioColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: _SegmentedModel(
                  value: model,
                  onChanged: busy ? null : onModelChanged,
                ),
              ),
              const SizedBox(width: 10),
              _StreamChip(
                enabled: streaming,
                glow: streaming,
                onChanged: busy || model == DeepSeekModel.reasoner || webSearch
                    ? null
                    : onStreamingChanged,
              ),
              const SizedBox(width: 8),
              _StreamChip(
                label: 'Search',
                icon: Icons.travel_explore_rounded,
                enabled: webSearch,
                glow: false,
                onChanged: busy || model == DeepSeekModel.reasoner
                    ? null
                    : onWebSearchChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedModel extends StatelessWidget {
  const _SegmentedModel({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudioColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudioColors.border),
      ),
      child: Row(
        children: [
          _seg('Chat', DeepSeekModel.chat),
          _seg('Reasoner', DeepSeekModel.reasoner),
        ],
      ),
    );
  }

  Widget _seg(String label, String modelId) {
    final selected = value == modelId;
    return Expanded(
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(modelId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? StudioColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: StudioColors.accent.withValues(alpha: 0.5))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? StudioColors.accent : StudioColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreamChip extends StatefulWidget {
  const _StreamChip({
    required this.enabled,
    required this.glow,
    required this.onChanged,
    this.label = 'Stream',
    this.icon = Icons.bolt_rounded,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool glow;
  final ValueChanged<bool>? onChanged;

  @override
  State<_StreamChip> createState() => _StreamChipState();
}

class _StreamChipState extends State<_StreamChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _StreamChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.enabled && widget.glow) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glowStrength =
            widget.enabled && widget.glow ? 0.25 + (_pulse.value * 0.35) : 0.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onChanged == null
                ? null
                : () => widget.onChanged!(!widget.enabled),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? StudioColors.accentSoft.withValues(alpha: 0.85)
                    : StudioColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.enabled
                      ? StudioColors.accent.withValues(alpha: 0.85)
                      : StudioColors.border,
                  width: widget.enabled ? 1.5 : 1,
                ),
                boxShadow: widget.enabled && widget.glow
                    ? [
                        BoxShadow(
                          color: StudioColors.accent
                              .withValues(alpha: glowStrength),
                          blurRadius: 14 + (_pulse.value * 8),
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: 18,
            color:
                widget.enabled ? StudioColors.accent : StudioColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.enabled
                  ? StudioColors.textPrimary
                  : StudioColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.suggestions,
    required this.onTap,
    required this.compact,
  });

  final List<String> suggestions;
  final void Function(String) onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 20 : 28),
      child: Column(
        children: [
          SizedBox(height: compact ? 8 : 24),
          Icon(
            Icons.forum_outlined,
            size: compact ? 44 : 56,
            color: StudioColors.accent.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Token-by-token streaming',
            style: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Record (camera) for LinkedIn overlays, then send a prompt.',
            style: theme.bodyMedium?.copyWith(color: StudioColors.textMuted),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 16 : 24),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SuggestionCard(text: s, onTap: () => onTap(s)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StudioColors.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StudioColors.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(text)),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.emphasizeStreaming,
  });

  final _Message message;
  final bool emphasizeStreaming;

  @override
  Widget build(BuildContext context) {
    if (message.isStatus) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 42),
        child: Row(
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              size: 16,
              color: StudioColors.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: StudioColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isUser = message.isUser;
    final streamingAssistant = !isUser && message.streaming;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: StudioColors.accentSoft,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: StudioColors.accent,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [
                          StudioColors.userGradientStart,
                          StudioColors.userGradientEnd,
                        ],
                      )
                    : null,
                color: isUser
                    ? null
                    : streamingAssistant
                        ? const Color(0xFF1E2A3D)
                        : StudioColors.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: streamingAssistant
                            ? StudioColors.accent.withValues(
                                alpha: emphasizeStreaming ? 0.75 : 0.45,
                              )
                            : StudioColors.border,
                        width: streamingAssistant ? 1.5 : 1,
                      ),
                boxShadow: streamingAssistant && emphasizeStreaming
                    ? [
                        BoxShadow(
                          color: StudioColors.accent.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.reasoning != null &&
                      message.reasoning!.isNotEmpty) ...[
                    const Text(
                      'Reasoning',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: StudioColors.reasoning,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message.reasoning!,
                      style: TextStyle(
                        fontSize: 13,
                        color: StudioColors.reasoning.withValues(alpha: 0.9),
                        height: 1.45,
                      ),
                    ),
                    const Divider(height: 20, color: StudioColors.border),
                    const Text(
                      'Answer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: StudioColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  StreamingMessageBody(
                    text: message.text,
                    streaming: message.streaming,
                    isUser: isUser,
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.compact,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final bool compact;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, compact ? 10 : 14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !busy,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: busy ? null : (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Message DeepSeek…',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: busy ? null : onSend,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: busy
                          ? [StudioColors.border, StudioColors.border]
                          : const [
                              StudioColors.userGradientStart,
                              StudioColors.userGradientEnd,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: StudioColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Message {
  _Message._({
    required this.text,
    required this.isUser,
    this.streaming = false,
    this.reasoning,
    this.isStatus = false,
  });

  factory _Message.status(String text) =>
      _Message._(text: text, isUser: false, isStatus: true);

  factory _Message.user(String text) => _Message._(text: text, isUser: true);

  factory _Message.assistant(
    String text, {
    bool streaming = false,
    String? reasoning,
  }) =>
      _Message._(
        text: text,
        isUser: false,
        streaming: streaming,
        reasoning: reasoning,
      );

  final String text;
  final bool isUser;
  final bool streaming;
  final String? reasoning;
  final bool isStatus;
}
