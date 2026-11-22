import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import 'linked_tasks.dart';

/// ZT Tasks' app id: its key's HKDF label and `vault_items.app` value.
const tasksAppId = 'tasks';
const tasksAndroidPackage = 'dev.sagron.zerotrusttasks';

/// ZT Tasks' key for the unlocked account, derived from the account key at
/// unlock (see AppGate), the way ZT Calendar reads tasks. Zeroed when the
/// vault locks. Quests only reads with it, never writes.
final tasksKeyProvider = NotifierProvider<TasksKey, Uint8List?>(TasksKey.new);

class TasksKey extends Notifier<Uint8List?> {
  @override
  Uint8List? build() {
    ref.listen(vaultControllerProvider, (_, VaultState next) {
      if (next is VaultLocked) clear();
    });
    ref.onDispose(_zero);
    return null;
  }

  /// Derives ZT Tasks' key from [dek]. Doesn't take ownership of [dek].
  Future<void> deriveFrom(Uint8List dek) async {
    final key = await KeyHierarchy.appKey(dek, tasksAppId);
    _zero();
    state = key;
  }

  void clear() {
    _zero();
    state = null;
  }

  void _zero() {
    final key = state;
    if (key != null) key.fillRange(0, key.length, 0);
  }
}

/// Pulls ZT Tasks' items but never uploads: Quests only reads tasks.
class ReadOnlySyncBackend implements SyncBackend {
  ReadOnlySyncBackend(this.inner);
  final SyncBackend inner;

  @override
  Future<List<RemoteItem>> pull(String app, {DateTime? since}) =>
      inner.pull(app, since: since);

  @override
  Future<List<RemoteItem>> fetch(String app, Set<String> itemIds) =>
      inner.fetch(app, itemIds);

  @override
  Future<Set<String>> pushAll(String app, List<RemoteItem> items) async {
    if (items.isNotEmpty) throw StateError('Quests never writes $app items');
    return <String>{};
  }

  @override
  Future<void> Function() subscribe(
    String app,
    void Function(RemoteItem) onChange,
  ) => inner.subscribe(app, onChange);
}

/// Quests' own encrypted copy of ZT Tasks' items, opened with ZT Tasks' key
/// and kept up to date from the account. Separate from ZT Tasks' own file;
/// deleting it loses nothing.
class TasksMirror {
  TasksMirror({required this.store, required this.engine});

  final ZtLocalStore store;
  final ItemSyncEngine engine;
  AppLifecycleListener? _lifecycle;
  final _refreshed = StreamController<void>.broadcast();

  /// How the last [refresh] went: null before the first one finishes.
  bool? lastRefreshOk;

  void start() {
    refresh().ignore();
    engine.startLive();
    _lifecycle = AppLifecycleListener(onResume: () => refresh().ignore());
  }

  Future<void> refresh() async {
    try {
      await engine.sync();
      lastRefreshOk = true;
    } on Object {
      lastRefreshOk = false;
    }
    if (!_refreshed.isClosed) _refreshed.add(null);
  }

  Future<TasksSnapshot> read() async => TasksSnapshot.fromItems([
    for (final i in await store.liveItems()) (i.itemId, i.json),
  ], refreshOk: lastRefreshOk);

  Stream<TasksSnapshot> watch() async* {
    yield await read();
    final changes = StreamController<void>();
    final a = store.changes.listen((_) => changes.add(null));
    final b = _refreshed.stream.listen((_) => changes.add(null));
    try {
      await for (final _ in changes.stream) {
        yield await read();
      }
    } finally {
      await a.cancel();
      await b.cancel();
      await changes.close();
    }
  }

  Future<void> close() async {
    _lifecycle?.dispose();
    await _refreshed.close();
    await engine.close();
    await store.close();
  }
}

final tasksMirrorProvider = FutureProvider<TasksMirror>((ref) async {
  final unlocked = ref.watch(tasksKeyProvider);
  if (unlocked == null) throw const VaultIsLocked();
  final key = Uint8List.fromList(unlocked);
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    key.fillRange(0, key.length, 0);
  });
  final userId = ref.watch(accountServiceProvider).currentUserId;
  if (userId == null) throw StateError('Not signed in');
  final path = await ZtLocalStore.pathFor(
    appId: 'quests_$tasksAppId',
    userId: userId,
  );
  ZtLocalStore store;
  try {
    store = await ZtLocalStore.open(appKey: key, path: path);
  } on LocalStoreUnreadable {
    await ZtLocalStore.moveAside(path);
    store = await ZtLocalStore.open(appKey: key, path: path);
  }
  final deviceId = await ref.watch(ztDeviceIdProvider.future);
  final engine = await ItemSyncEngine.fromVault(
    appId: tasksAppId,
    appKey: key,
    deviceId: deviceId,
    store: store,
    backend: ReadOnlySyncBackend(ref.watch(ztSyncBackendProvider)),
  );
  final mirror = TasksMirror(store: store, engine: engine);
  if (disposed) {
    await mirror.close();
    throw const VaultIsLocked();
  }
  ref.onDispose(mirror.close);
  mirror.start();
  return mirror;
});

/// ZT Tasks' tasks and lists, kept up to date. Tests replace it.
final tasksSnapshotProvider = StreamProvider<TasksSnapshot>((ref) async* {
  final mirror = await ref.watch(tasksMirrorProvider.future);
  yield* mirror.watch();
});

/// Each repeating task's due day when Quests last looked, on this phone
/// only (a phone that missed a round leaves it to the one that saw it;
/// both make the same reward id).
final tasksSeenStoreProvider = Provider<TasksSeenStore>(
  (ref) => TasksSeenStore(ref.watch(ztPreferencesStoreProvider)),
);

class TasksSeenStore {
  TasksSeenStore(this._prefs);
  final PreferencesStore _prefs;
  static const _key = 'quests.tasksSeen';

  Future<Map<String, String>> read() async {
    try {
      final raw = await _prefs.read(_key);
      if (raw == null || raw.isEmpty) return {};
      final map = jsonDecode(raw);
      if (map is! Map) return {};
      return {
        for (final e in map.entries)
          if (e.value is String) '${e.key}': e.value as String,
      };
    } on Object {
      return {};
    }
  }

  Future<void> write(Map<String, String> seen) =>
      _prefs.write(_key, jsonEncode(seen));
}
