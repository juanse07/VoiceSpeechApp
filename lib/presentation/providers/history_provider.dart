import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/session.dart';

class HistoryNotifier extends StateNotifier<AsyncValue<List<Session>>> {
  HistoryNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  final _repo = HistoryRepositoryImpl();

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _repo.getAllSessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSession(String id) async {
    await _repo.deleteSession(id);
    await load();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = const AsyncValue.data([]);
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<Session>>>((ref) {
  return HistoryNotifier();
});
