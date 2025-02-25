import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../model/task.dart';


class geminiServices {
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
  final String apiKey;

  geminiServices() : apiKey = dotenv.env['GEMINI_API_KEY'] ?? "" {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key is empty');
    }
  }

  Future<String> generateSchedule(List<Task> tasks) async {
    _validateTasks(tasks);
    final prompt = _buildPrompt(tasks);

    try {
      print("prompt: \n $prompt");
      final response = await http.post(Uri.parse("$_baseUrl?key=$apiKey"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "role":"user",
                "parts": [
                  {"text": prompt}
                ]
              }
            ]
          }));

      return _hadleResponse(response);
    } catch (e) {
      throw ArgumentError('Failed to generate schedule: $e');
    }
  }


  String _hadleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode == 401) {
      throw ArgumentError('API key is invalid or unauthorized');
    } else if(response.statusCode == 429){
      throw ArgumentError('Rate limit exceeded');
    } else if (response.statusCode == 500) {
      throw ArgumentError('Internal server error');
    } else if (response.statusCode == 503) {
      throw ArgumentError('Service unavailable');
    }else if (response.statusCode == 200) {
      return data['candidates'][0] ['contents']['parts'][0]['text'];
    }
    else {
      throw ArgumentError('Unknown error');
    }

    return data['contents'][0]['parts'][0]['text'];
  }

  String _buildPrompt(List<Task> tasks) {
    final taskList = tasks.map((task)=>"${task.name} (Priority ${task.priority}, Duration ${task.duration}minute, Deadline ${task.deadline})" ).join("\n");
    return "Buat jadwal untuk hari ini: \n\n$taskList";

  }
  void _validateTasks(List<Task> tasks) {
    if (tasks.isEmpty) throw ArgumentError('Task cannot be empty');
  }
}
