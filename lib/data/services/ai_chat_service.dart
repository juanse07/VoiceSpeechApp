import 'dart:convert';
import 'package:dio/dio.dart';
// ignore: implementation_imports
export 'package:dio/dio.dart' show DioException;

class AiChatService {
  AiChatService({
    required this.endpoint,
    required this.apiKey,
    required this.model,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final String endpoint;
  final String apiKey;
  final String model;
  final Dio _dio;

  Future<String> chat(List<Map<String, String>> messages) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: {
          'model': model,
          'messages': messages,
          'max_tokens': 512,
          'response_format': {'type': 'json_object'},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      final content = response.data?['choices']?[0]?['message']?['content'];
      if (content == null) {
        throw Exception('No content in response: ${response.data}');
      }
      return content as String;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode != null) {
        final body = e.response?.data;
        final msg = body is Map
            ? (body['error']?['message'] ?? body.toString())
            : (body?.toString() ?? 'no body');
        throw Exception('AI API $statusCode: $msg');
      }
      // No response — network/connection error
      final detail = e.message?.isNotEmpty == true ? e.message : e.type.name;
      throw Exception('AI connection failed (${e.type.name}): $detail\n'
          'Check that the endpoint URL is reachable and the API key is valid.');
    }
  }
}

/// Parses structured JSON AI feedback from assessment data.
/// Used by AiRepositoryImpl to convert raw chat output into AiFeedback fields.
Map<String, dynamic> parseAiFeedbackJson(String raw) {
  var text = raw.trim();

  // Strip markdown code fences if present
  if (text.startsWith('```')) {
    final firstNewline = text.indexOf('\n');
    final lastFence = text.lastIndexOf('```');
    if (firstNewline != -1 && lastFence > firstNewline) {
      text = text.substring(firstNewline + 1, lastFence).trim();
    }
  }

  // Try direct parse first
  try {
    return jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {}

  // Fall back: find the first { ... } block in the response
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start != -1 && end > start) {
    try {
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {}
  }

  throw FormatException('No valid JSON found in AI response: ${text.length > 120 ? text.substring(0, 120) : text}');
}
