import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_whisper/buttons/record_button.dart';
import 'package:flutter_whisper/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiService _apiService = ApiService('http://192.168.43.27:5000'); // Adresi buraya güncelledik

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String userMessage = _controller.text;
      setState(() {
        _messages.add({'user': userMessage});
        _controller.clear();
      });

      try {
        String botResponse = await _apiService.getResponse(userMessage);
        setState(() {
          _messages.add({'bot': botResponse});
        });
      } catch (e) {
        print('Failed to get response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get response: $e')),
        );
      }
    }
  }

  void _handleRecordedVoice(String path) async {
    print('Ses dosyası yolu: $path');
    try {
      Map<String, String> response = await _apiService.uploadVoiceFile(path);
      String transcription = response['transcription'] ?? 'Transcription not found';
      String openaiResponse = response['response'] ?? 'Response not found';
      print('Transcription: $transcription');
      print('OpenAI Response: $openaiResponse');
      setState(() {
        _messages.add({'user': transcription, 'bot': openaiResponse});
      });
    } catch (e) {
      print('Failed to send voice file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send voice file: $e')),
      );
    }
  }

  void _playRecordedVoice(String path) async {
    File file = File(path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording not found')),
      );
      return;
    }
    Source audioSource = UrlSource(file.path);
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.stop();
    }
    await _audioPlayer.play(audioSource);

    if (_audioPlayer.state == PlayerState.playing) {
      // success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play recording')),
      );
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) CircleAvatar(child: Icon(Icons.rocket)),
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isUser ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
        ),
        if (isUser) CircleAvatar(child: Icon(Icons.person)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Column(
                  children: [
                    if (message.containsKey('user'))
                      _buildMessageBubble(message['user']!, true),
                    if (message.containsKey('bot'))
                      _buildMessageBubble(message['bot']!, false),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                RecordButton(onRecordComplete: _handleRecordedVoice),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
