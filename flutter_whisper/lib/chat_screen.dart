import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) {
      return; // Prevent sending empty messages
    }
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isBot: false, // Set to false initially, change as needed
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot'),
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
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
    padding: EdgeInsets.only(bottom: 20.0, right: 15.0, left: 15.0), // Add bottom padding
    child: Container(
      decoration: BoxDecoration( // Container decoration
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(25.0), // Rounded corners for elliptical shape
        boxShadow: [ // Subtle shadow
          BoxShadow(
            color: Colors.grey,
            blurRadius: 5.0,
            spreadRadius: 0.0,
            offset: Offset(0.0, 2.0), // Slight bottom shadow
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration.collapsed(
                hintText: "Send a message",
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              cursorColor: Colors.blue, // Cursor color
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, size: 24.0), // Icon size
            onPressed: () => _handleSubmitted(_textController.text),
            color: Colors.blue, // Button color
          ),
          // Corrected path to your local asset
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
    if (isBot) {
      // If the message is from the bot, use a grey avatar
      return CircleAvatar(
        backgroundColor: Colors.grey,
        child: Text(
          "Bot",
          style: TextStyle(fontSize: 12.0),
        ),
      );
    } else {
      // If the message is from the user, use the people.png image
      return CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage(isBot ? 'assets/images/artificial-intelligence.png' : 'assets/images/people.png'),
      );
    }
  }
}



