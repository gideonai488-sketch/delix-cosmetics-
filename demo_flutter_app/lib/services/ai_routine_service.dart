import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AiRoutinePlan {
  final List<String> morning;
  final List<String> evening;

  const AiRoutinePlan({
    required this.morning,
    required this.evening,
  });
}

class AiRoutineService {
  static bool get isConfigured => AppConfig.hasOpenAiKey;

  static Future<AiRoutinePlan?> generateRoutine({
    required String skinType,
    required String concern,
    required String goal,
    required String routineDepth,
  }) async {
    if (!isConfigured) return null;

    final prompt = '''
You are a skincare expert. Generate one AM routine and one PM routine.
Return strict JSON only with keys morning and evening.
Each key must be an array of short step strings.
No markdown.

User profile:
- Skin type: $skinType
- Main concern: $concern
- Goal: $goal
- Depth: $routineDepth
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.openAiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConfig.openAiModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'Return only valid minified JSON with morning and evening string arrays.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.4,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return null;

    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content']?.toString().trim();
    if (content == null || content.isEmpty) return null;

    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final morningRaw = decoded['morning'] as List<dynamic>?;
    final eveningRaw = decoded['evening'] as List<dynamic>?;
    if (morningRaw == null || eveningRaw == null) return null;

    final morning =
        morningRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    final evening =
        eveningRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();

    if (morning.isEmpty || evening.isEmpty) return null;

    return AiRoutinePlan(morning: morning, evening: evening);
  }
}
