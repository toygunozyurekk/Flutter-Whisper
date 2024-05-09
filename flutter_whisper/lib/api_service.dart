import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:5000'; // Update with your backend URL

  static Future<String> getOpenAIResponse(String query) async {
    final url = Uri.parse('$_baseUrl/openai_response');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      throw Exception('Failed to get response from backend');
    }
  }
}
