import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _chatController = TextEditingController();
  String _responseText = '';

  @override
  Widget build(BuildContext context) {
    final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _responseText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final prompt = [Content.text(_chatController.text)];
                    final response = await model.generateContent(prompt);
                    setState(() {
                      _responseText = response.text ?? '';
                    });
                    _chatController.clear();
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}