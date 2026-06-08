import 'package:flutter/material.dart';
import 'package:flutter_deepseek/flutter_deepseek.dart';

void main() {
  runApp(const DeepSeekDemoApp());
}

class DeepSeekDemoApp extends StatelessWidget {
  const DeepSeekDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_deepseek demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _apiKeyController = TextEditingController();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  DeepSeekClient? _client;
  String _selectedModel = DeepSeekModel.chat;
  bool _streaming = true;
  bool _loading = false;

  final List<_ChatBubble> _messages = [];

  @override
  void dispose() {
    _client?.dispose();
    _apiKeyController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  DeepSeekClient _getClient() {
    final key = _apiKeyController.text.trim();
    _client ??= DeepSeekClient(apiKey: key);
    return _client!;
  }

  void _resetClient() {
    _client?.dispose();
    _client = null;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _send() async {
    final key = _apiKeyController.text.trim();
    final text = _inputController.text.trim();
    if (key.isEmpty) {
      _showError('Enter your DeepSeek API key');
      return;
    }
    if (text.isEmpty || _loading) return;

    _resetClient();
    setState(() {
      _messages.add(_ChatBubble.user(text));
      _inputController.clear();
      _loading = true;
    });
    _scrollToBottom();

    try {
      final client = _getClient();

      if (_selectedModel == DeepSeekModel.reasoner) {
        final result = await client.reason(prompt: text);
        if (!mounted) return;
        setState(() {
          if (result.reasoningContent.isNotEmpty) {
            _messages.add(
              _ChatBubble.assistant(
                'Reasoning:\n${result.reasoningContent}\n\nAnswer:\n${result.content}',
                isReasoner: true,
              ),
            );
          } else {
            _messages.add(_ChatBubble.assistant(result.content));
          }
          _loading = false;
        });
      } else if (_streaming) {
        setState(() {
          _messages.add(_ChatBubble.assistant('', streaming: true));
        });
        final buffer = StringBuffer();
        await for (final token in client.chatStream(
          messages: [ChatMessage.user(text)],
          model: _selectedModel,
        )) {
          buffer.write(token);
          if (!mounted) return;
          setState(() {
            _messages.last = _ChatBubble.assistant(
              buffer.toString(),
              streaming: true,
            );
          });
          _scrollToBottom();
        }
        if (!mounted) return;
        setState(() {
          _messages.last = _ChatBubble.assistant(buffer.toString());
          _loading = false;
        });
      } else {
        final response = await client.chat(
          messages: [ChatMessage.user(text)],
          model: _selectedModel,
        );
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatBubble.assistant(response.text));
          _loading = false;
        });
      }
    } on DeepSeekAuthException catch (e) {
      _showError('Auth error: ${e.message}');
      setState(() => _loading = false);
    } on DeepSeekRateLimitException catch (e) {
      _showError('Rate limit: ${e.message}');
      setState(() => _loading = false);
    } on DeepSeekException catch (e) {
      _showError(e.message);
      setState(() => _loading = false);
    } catch (e) {
      _showError(e);
      setState(() => _loading = false);
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_deepseek'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API key (memory only)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  obscureText: true,
                  onChanged: (_) => _resetClient(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedModel,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DeepSeekModel.chat,
                            child: Text('deepseek-chat'),
                          ),
                          DropdownMenuItem(
                            value: DeepSeekModel.reasoner,
                            child: Text('deepseek-reasoner'),
                          ),
                        ],
                        onChanged: _loading
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _selectedModel = value);
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Stream'),
                        Switch(
                          value: _streaming,
                          onChanged: _loading || _selectedModel == DeepSeekModel.reasoner
                              ? null
                              : (v) => setState(() => _streaming = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final bubble = _messages[index];
                return Align(
                  alignment: bubble.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: bubble.isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : bubble.isReasoner
                              ? Colors.amber.shade50
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bubble.text.isEmpty && bubble.streaming
                              ? '…'
                              : bubble.text,
                        ),
                        if (bubble.streaming && _loading)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                      enabled: !_loading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _send,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble {
  _ChatBubble._({
    required this.text,
    required this.isUser,
    this.streaming = false,
    this.isReasoner = false,
  });

  factory _ChatBubble.user(String text) =>
      _ChatBubble._(text: text, isUser: true);

  factory _ChatBubble.assistant(
    String text, {
    bool streaming = false,
    bool isReasoner = false,
  }) =>
      _ChatBubble._(
        text: text,
        isUser: false,
        streaming: streaming,
        isReasoner: isReasoner,
      );

  final String text;
  final bool isUser;
  final bool streaming;
  final bool isReasoner;
}
