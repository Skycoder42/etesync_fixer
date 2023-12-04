import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sync_job.dart';
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

  final _logger = Logger('$ItemSync');

  ItemSync(this._syncJobRegistry);

  Future<SyncResult> syncItem(
    EtebaseItemManager itemManager,
    EtebaseCollection collection,
    EtebaseItem item,
  ) async {
    final result = await _syncJobRegistry.sync(collection, item);
    final now = DateTime.now();

    if (result.itemModified) {
      final uid = await item.getUid();
      _logger.finest('Settings last modified timestamp of item $uid to $now');
      final meta = await item.getMeta();
      await item.setMeta(meta.copyWith(mtime: now));
    }

    if (result.collectionModified) {
      final uid = await collection.getUid();
      _logger.finest(
        'Settings last modified timestamp of collection $uid to $now',
      );
      final meta = await collection.getMeta();
      await collection.setMeta(meta.copyWith(mtime: now));
    }

    return result;
  }
}
