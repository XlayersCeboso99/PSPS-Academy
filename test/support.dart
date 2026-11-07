import 'package:psps/data/progress_store.dart';

class MemoryStore implements ProgressStore {
  String? raw;
  bool failSave = false;
  bool failLoad = false;
  int writes = 0;
  @override
  Future<ProgressSnapshot> load() async {
    if (failLoad) throw StateError('Simulated read failure');
    return raw == null ? ProgressSnapshot() : ProgressSnapshot.decode(raw!);
  }

  @override
  Future<void> save(ProgressSnapshot state) async {
    if (failSave) throw StateError('Simulated disk failure');
    raw = state.encode();
    writes++;
  }
}
