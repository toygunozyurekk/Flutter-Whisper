import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';

class ApiService {
  final String _baseUrl;

  ApiService(this._baseUrl);

  Future<Map<String, String>> uploadVoiceFile(String filePath) async {
    // Remove 'file://' prefix if present
    if (filePath.startsWith('file://')) {
      filePath = filePath.replaceFirst('file://', '');
    }

    if (!await File(filePath).exists()) {
      print('File does not exist at path: $filePath');
      return {'transcription': 'File does not exist', 'response': ''};
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/whisper'),
    );
    request.files.add(await http.MultipartFile.fromPath(
      'voice',
      filePath,
      filename: basename(filePath),
    ));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await http.Response.fromStream(response);
        print('Response body: ${responseBody.body}'); // Print the response body
        final dynamic responseData = json.decode(responseBody.body);

        if (responseData is List && responseData.isNotEmpty) {
          final transcript = responseData[0]['transcript'] ?? 'Transcription not found';
          final openaiResponse = responseData[0]['openai_response'] != null
              ? responseData[0]['openai_response']['response'] ?? 'Response not found'
              : 'Response not found';
          return {'transcription': transcript, 'response': openaiResponse};
        } else {
          return {'transcription': 'Unexpected response format', 'response': ''};
        }
      } else {
        print('Failed to upload voice file: ${response.statusCode}');
        return {'transcription': 'Failed to upload voice file', 'response': ''};
      }
    } catch (e) {
      print('Failed to send voice file: $e');
      return {'transcription': 'Failed to send voice file', 'response': e.toString()};
    }
  }

  Future<String> getResponse(String message) async {
    var url = Uri.parse('$_baseUrl/get_response');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return responseBody['response'] ?? 'No response';
      } else {
        print('Failed to get response: ${response.statusCode}');
        return 'Failed to get response';
      }
    } catch (e) {
      print('Failed to get response: $e');
      return 'Failed to get response';
    }
  }
}
