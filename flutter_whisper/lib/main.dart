import 'package:flutter/material.dart';
import 'chat_screen.dart';

void main() => runApp(ChatApp());

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatBot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blueAccent, // previously known as accentColor
        ),
      ),
      home: ChatScreen(),
    );
  }
}
