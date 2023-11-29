import 'package:etebase/etebase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sync_job_registry.dart';

part 'item_sync.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
ItemSync itemSync(ItemSyncRef ref) => ItemSync(
      ref.watch(syncJobRegistryProvider),
    );
// coverage:ignore-end

class ItemSync {
  final SyncJobRegistry _syncJobRegistry;

  ItemSync(this._syncJobRegistry);

  Future<void> syncItem(
    EtebaseItemManager itemManager,
    EtebaseCollection collection,
    EtebaseItem item,
  ) async {
    await _syncJobRegistry.sync(collection, item);
  }
}
