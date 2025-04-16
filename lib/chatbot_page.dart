import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  // Replace with your Vertex AI API key
  final String _apiKey = 'YOUR_VERTEX_AI_API_KEY'; // Replace with your actual API key
  late final GenerativeModel model; // Declare the model as a late final variable
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the Vertex AI Generative Model
    model = GenerativeModel(apiKey: _apiKey, model: 'gemini-2.0-flash');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
      ),
      body: const Center(
        child: Text(
          'Chatbot',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}