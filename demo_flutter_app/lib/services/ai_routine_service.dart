import 'dart:convert';
import 'dart:async';

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
  static bool get isConfigured => AppConfig.hasAiBackend;

  static Future<AiRoutinePlan?> generateRoutine({
    required String skinType,
    required String concern,
    required String goal,
    required String routineDepth,
  }) async {
    if (!isConfigured) return null;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/ai/routine');
    http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'skinType': skinType,
              'concern': concern,
              'goal': goal,
              'routineDepth': routineDepth,
            }),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final morningRaw = body['morning'] as List<dynamic>?;
    final eveningRaw = body['evening'] as List<dynamic>?;
    if (morningRaw == null || eveningRaw == null) return null;

    final morning =
        morningRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    final evening =
        eveningRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();

    if (morning.isEmpty || evening.isEmpty) return null;

    return AiRoutinePlan(morning: morning, evening: evening);
  }
}
