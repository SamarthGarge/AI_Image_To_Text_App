import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; // Load API key  
final String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

  Future<String> analyzeImage(File image) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key is missing! Please check your .env file.');
    }

    // Convert image to base64
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Detect media type
    final String mediaType;
    if (image.path.toLowerCase().endsWith('.png')) {
      mediaType = 'image/png';
    } else if (image.path.toLowerCase().endsWith('.jpg') || image.path.toLowerCase().endsWith('.jpeg')) {
      mediaType = 'image/jpeg';
    } else {
      throw Exception('Unsupported image format');
    }

    // Send request to Gemini API
    final response = await http.post(
      Uri.parse("$_baseUrl?key=$_apiKey"),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {
                  "mimeType": mediaType,
                  "data": base64Image,
                }
              },
              {
                "text": "Describe this image in a detailed, structured, and visually appealing way using bullet points, sections, and emojis where appropriate."
              }
            ]
          }
        ]
      }),
    );

    // Handle response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception("Failed to analyze image: ${errorData['error']['message']}");
    }
  }
}
