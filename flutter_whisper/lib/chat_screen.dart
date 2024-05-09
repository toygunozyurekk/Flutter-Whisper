import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart'; // Import the API service
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException("Microphone permission not granted");
      }
      await _recorder!.openRecorder();
    } catch (e) {
      print('Error initializing recorder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required to record audio')),
      );
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) {
      return; // Prevent sending empty messages
    }
    _textController.clear();
    ChatMessage userMessage = ChatMessage(
      text: text,
      isBot: false,
    );
    setState(() {
      _messages.insert(0, userMessage);
    });

    // Send user's message to the backend
    try {
      String botResponse = await ApiService.getOpenAIResponse(text);
      ChatMessage botMessage = ChatMessage(
        text: botResponse,
        isBot: true,
      );
      setState(() {
        _messages.insert(0, botMessage);
      });
    } catch (e) {
      ChatMessage errorMessage = ChatMessage(
        text: 'Error: Unable to get response',
        isBot: true,
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      var status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String appDocPath = appDocDir.path;
        String filePath = '$appDocPath/audio.wav'; // Save as .wav file
        await _recorder!.startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
        _recordingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
          setState(() {
            _recordingDuration += 100;
          });
        });
      } else if (status == PermissionStatus.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission denied')),
        );
      } else if (status == PermissionStatus.permanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission permanently denied, please enable it in settings'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _recorder!.stopRecorder();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
      if (_recordingDuration >= 1000) {
        if (path != null) {
          _sendAudioToBackend(File(path));
        }
      } else {
        print('Recording is too short.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording is too short. Please record for longer.')),
        );
      }
    } catch (e) {
      print('Error stopping recorder: $e');
    }
  }

  Future<void> _sendAudioToBackend(File audioFile) async {
    try {
      var uri = Uri.parse('http://127.0.0.1:5000/whisper');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);

        for (var result in data['results']) {
          ChatMessage userMessage = ChatMessage(
            text: result['transcript'] ?? 'Transcription failed',
            isBot: false,
          );
          ChatMessage botMessage = ChatMessage(
            text: result['openai_response'] ?? 'No response from OpenAI',
            isBot: true,
          );

          setState(() {
            _messages.insert(0, botMessage);
            _messages.insert(0, userMessage);
          });
        }
      } else {
        throw Exception('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error sending audio to backend: $e');
      ChatMessage errorMessage = ChatMessage(
        text: 'Error: Unable to transcribe audio',
        isBot: true,
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot'),
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearChat,
            color: Colors.blue,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
            ),
          ),
          Divider(height: 1.0, color: Colors.grey[400]),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.0, right: 15.0, left: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 5.0,
              spreadRadius: 0.0,
              offset: Offset(0.0, 2.0),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic_none,
                size: 24.0,
              ),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              color: _isRecording ? Colors.red : Colors.blue,
            ),
            _isRecording
                ? Text(
                    'Recording: ${(_recordingDuration / 1000).toStringAsFixed(1)}s',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  )
                : Flexible(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _handleSubmitted,
                      decoration: InputDecoration.collapsed(
                        hintText: "Send a message",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      cursorColor: Colors.blue,
                    ),
                  ),
            IconButton(
              icon: Icon(Icons.send, size: 24.0),
              onPressed: () => _handleSubmitted(_textController.text),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({required this.text, required this.isBot});

  final String text;
  final bool isBot;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: <Widget>[
          if (isBot) _buildAvatar(isBot: true),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(left: isBot ? 10.0 : 0, right: isBot ? 0 : 10.0),
              padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isBot ? Colors.grey[200] : Colors.blue[100],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                text,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
          if (!isBot) _buildAvatar(isBot: false),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isBot}) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      backgroundImage: AssetImage(isBot ? 'assets/images/artificial-intelligence.png' : 'assets/images/people.png'),
      radius: 20.0,
    );
  }
}
