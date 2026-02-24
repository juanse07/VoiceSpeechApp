import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'session_history';

  @override
  Future<List<Session>> getAllSessions() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List;
    return list.map((e) => _sessionFromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveSession(Session session) async {
    final sessions = await getAllSessions();
    sessions.insert(0, session);
    await _saveSessions(sessions);
  }

  @override
  Future<void> deleteSession(String id) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((s) => s.id == id);
    await _saveSessions(sessions);
  }

  @override
  Future<void> clearAll() async {
    await _storage.delete(key: _key);
  }

  Future<void> _saveSessions(List<Session> sessions) async {
    final json = sessions.map(_sessionToJson).toList();
    await _storage.write(key: _key, value: jsonEncode(json));
  }

  Map<String, dynamic> _sessionToJson(Session s) => {
        'id': s.id,
        'mode': s.mode.name,
        'overallScore': s.overallScore,
        'accuracyScore': s.accuracyScore,
        'fluencyScore': s.fluencyScore,
        'completenessScore': s.completenessScore,
        'prosodyScore': s.prosodyScore,
        'referenceText': s.referenceText,
        'recognizedText': s.recognizedText,
        'audioFilePath': s.audioFilePath,
        'durationMs': s.durationMs,
        'createdAt': s.createdAt.toIso8601String(),
      };

  Session _sessionFromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        mode: SessionMode.values.byName(j['mode'] as String),
        overallScore: (j['overallScore'] as num).toDouble(),
        accuracyScore: (j['accuracyScore'] as num?)?.toDouble() ?? 0,
        fluencyScore: (j['fluencyScore'] as num?)?.toDouble() ?? 0,
        completenessScore: (j['completenessScore'] as num?)?.toDouble() ?? 0,
        prosodyScore: (j['prosodyScore'] as num?)?.toDouble() ?? 0,
        referenceText: j['referenceText'] as String,
        recognizedText: j['recognizedText'] as String,
        audioFilePath: j['audioFilePath'] as String,
        durationMs: j['durationMs'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
