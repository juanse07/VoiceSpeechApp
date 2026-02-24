import '../entities/session.dart';

abstract class HistoryRepository {
  Future<List<Session>> getAllSessions();
  Future<void> saveSession(Session session);
  Future<void> deleteSession(String id);
  Future<void> clearAll();
}
