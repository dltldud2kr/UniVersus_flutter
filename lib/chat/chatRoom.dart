import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universus/class/user/user.dart';
import 'package:web_socket_channel/io.dart';

class ChatScreen extends StatefulWidget {
  final int chatRoomId;
  final int chatRoomType;
  final String? customChatRoomName;

  ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.chatRoomType,
    this.customChatRoomName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late IOWebSocketChannel _channel;
  List<ChatMessage> _messages = [];
  String? _currentMemberIdx;

  @override
  void initState() {
    super.initState();
    _initWebSocketConnection();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _initWebSocketConnection() async {
    _currentMemberIdx = await UserData.getMemberIdx();
    setState(() {});

    _channel = IOWebSocketChannel.connect(
      Uri.parse(
        'ws://moyoapi.lunaweb.dev/ws/chat/${widget.chatRoomType}/${widget.chatRoomId}',
      ),
      headers: {'memberIdx': _currentMemberIdx ?? ''},
    );

    _channel.stream.listen((data) {
      _processMessage(data);
      _scrollToBottom();
    });
  }

  void _processMessage(String data) {
    setState(() {
      try {
        var decoded = jsonDecode(data);

        if (decoded is Map<String, dynamic>) {
          _messages.insert(
              0,
              ChatMessage.fromJson(
                  decoded)); // Insert at the beginning for reversed order
        } else if (decoded is Iterable<dynamic>) {
          _messages.insertAll(
              0,
              decoded.map((m) =>
                  ChatMessage.fromJson(m))); // Insert all at the beginning
        }
      } catch (e) {
        _messages.insert(
          0,
          ChatMessage(
            nickname: '',
            content: '상대방이 채팅방을 나갔습니다',
            memberIdx: 0,
            profileImg: '',
            regDt: DateTime.now().toIso8601String(),
            type: 'system',
          ),
        );
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  String _formatTimestamp(String regDt) {
    DateTime messageTime = DateTime.parse(regDt);
    DateTime now = DateTime.now();

    if (messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day) {
      return DateFormat('HH:mm').format(messageTime);
    } else if (messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day - 1) {
      return '어제 ${DateFormat('').format(messageTime)}';
    } else if (messageTime.year == now.year) {
      return DateFormat('MM월 dd일 ').format(messageTime);
    } else {
      return DateFormat('yyyy.MM.dd').format(messageTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customChatRoomName ?? '채팅방'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true, // Reverse the ListView
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: '메시지 보내기',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  tooltip: '메시지 보내기',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isSystemMessage = message.profileImg == 'system';
    bool isMine = int.parse(_currentMemberIdx ?? '0') == message.memberIdx;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(message.profileImg),
              backgroundColor: Colors.transparent,
              onBackgroundImageError: (_, __) => Icon(Icons.account_circle),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.nickname,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _messageContentBubble(message, isMine),
              ],
            ),
          ] else ...[
            _messageContentBubble(message, isMine),
          ]
        ],
      ),
    );
  }

  Widget _messageContentBubble(ChatMessage message, bool isMine) {
    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isMine)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  _formatTimestamp(message.regDt),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              decoration: BoxDecoration(
                color: isMine ? Color(0xFF7465F6) : Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(12),
                border: isMine
                    ? Border.all(color: Color(0xFF7465F6), width: 2)
                    : null,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                message.content,
                softWrap: true,
                style: TextStyle(
                  color: isMine ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  _formatTimestamp(message.regDt),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class ChatMessage {
  final String nickname;
  final String content;
  final int memberIdx;
  final String profileImg;
  final String regDt;
  final String type;

  ChatMessage({
    required this.nickname,
    required this.content,
    required this.memberIdx,
    required this.profileImg,
    required this.regDt,
    this.type = 'message',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      nickname: json['nickname'],
      content: json['content'],
      memberIdx: json['memberIdx'],
      profileImg: json['profileImg'],
      regDt: json['regDt'],
      type: json.containsKey('type') ? json['type'] : 'message',
    );
  }
}
