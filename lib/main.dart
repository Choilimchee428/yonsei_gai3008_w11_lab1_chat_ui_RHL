import 'package:flutter/material.dart';

void main() => runApp(const ChatLabApp());

class ChatLabApp extends StatelessWidget {
  const ChatLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat — 실습 1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

/// 대화 한 줄. 서버 없이 화면만 만들기 위한 최소 모델.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  String? _error;
  String? _lastFailedMessage;
  bool _sending = false;
  int _retryCount = 0;
 Future<void> _send({String? retryText}) async {
  final text = retryText ?? _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
    _sending = true;
    _retryCount = retryText == null ? 0 : _retryCount + 1;
    _error = null;
      if (retryText == null) {
  _messages.add(ChatMessage(text: text, isUser: true));
}
    });
    if (retryText == null) {
  _controller.clear();
}
    try {
  final waitSeconds = text == '429' && retryText != null
    ? (_retryCount == 1 ? 1 : 2)
    : 1;

await Future<void>.delayed(Duration(seconds: waitSeconds));
if (!mounted) return;

const mockErrors = {
  '401': '401: 인증에 실패했습니다. (모의 오류)',
  '429': '429: 요청이 너무 많습니다. (모의 오류)',
  '500': '500: 서버 오류가 발생했습니다. (모의 오류)',
  'timeout': 'Timeout: 응답 시간이 초과되었습니다. (모의 오류)',
};

// For 429, the first retry fails and the second retry succeeds.
// Other simulated errors recover on the first retry.
if (mockErrors.containsKey(text) &&
    (retryText == null || (text == '429' && _retryCount < 2))) {
  throw Exception(mockErrors[text]!);
}

  setState(() {
    _messages.add(
      const ChatMessage(
        text: '메시지를 받았습니다. (로컬 모의 응답)',
        isUser: false,
      ),
    );
  });
} catch (e) {
  if (!mounted) return;

  setState(() {
    _error = e.toString();
    _lastFailedMessage = text;
  });
} finally {
  if (mounted) {
    setState(() {
      _sending = false;
    });
  }
}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 실습용 가짜 대화 — API를 붙이기 전까지 이 목록으로 화면을 만든다.
  final List<ChatMessage> _messages = [
    // ChatMessage(text: '오늘 뭐 배워?', isUser: true),
    // ChatMessage(text: 'AI 챗봇에 움직이는 응답을 붙입니다.', isUser: false),
    // ChatMessage(text: '타이핑 점은 왜 필요해요?', isUser: true),
    // ChatMessage(text: '응답이 1초를 넘으면 앱이 멈춘 것처럼 보이기 때문입니다.', isUser: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 할 일 5 — 키보드가 입력창을 가리지 않게
      //    resizeToAvoidBottomInset(기본값 true)이 키보드 높이만큼 body를 줄인다.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('AI Chat — 실습 1')),
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────
            // ✅ 할 일 1 — 완료된 부분
            //    ListView.builder + reverse: true
            //    · reverse:true면 index 0이 화면 맨 아래(최신)다.
            //    · 그래서 _messages[length - 1 - i]로 거꾸로 꺼낸다.
            // ─────────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        return _Bubble(message: message);
                      },
                    ),
                  ),
                  // ✅ 할 일 4 — 빈 상태
                  if (_messages.isEmpty)
                    const Center(child: Text('무엇이든 물어보세요')),
                ],
              ),
            ),

            // ─────────────────────────────────────────────────────────
            // ✅ 할 일 3 — 입력창 (TextField + 전송 버튼)
            // ─────────────────────────────────────────────────────────
            AnimatedSwitcher(
  duration: const Duration(milliseconds: 250),
  child: _error == null
      ? const SizedBox.shrink(key: ValueKey('no-error'))
      : Container(
          key: ValueKey(_error),
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('$_error\n실패한 메시지: ${_lastFailedMessage ?? ''}'),
    const SizedBox(height: 8),
    TextButton.icon(
      onPressed: _sending || _lastFailedMessage == null
          ? null
          : () => _send(retryText: _lastFailedMessage),
      icon: const Icon(Icons.refresh),
      label: const Text('다시 시도'),
    ),
  ],
),
        ),
),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '무엇이든 물어보세요',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ───────────────────────────────────────────────────────────────
/// ✅ 할 일 2 — 말풍선 2종 (사용자 오른쪽 / AI 왼쪽)
/// ───────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
