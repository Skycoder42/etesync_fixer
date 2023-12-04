import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/config.dart';
import '../config/config_loader.dart';
import 'item_sync.dart';

part 'collection_sync.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
CollectionSync collectionSync(CollectionSyncRef ref) => CollectionSync(
      ref.watch(configLoaderProvider.notifier),
      ref.watch(itemSyncProvider),
    );
// coverage:ignore-end

class CollectionSync {
  final ConfigLoader _configLoader;
  final ItemSync _itemSync;

  final _logger = Logger('$CollectionSync');

  CollectionSync(
    this._configLoader,
    this._itemSync,
  );

  Future<bool> sync(
    EtebaseCollection collection,
    EtebaseItemManager itemManager,
  ) async {
    final uid = await collection.getUid();
    if (await collection.isDeleted()) {
      await delete(uid);
      return false;
    }

    final oldToken = _configLoader.state.collectionStokens[uid];
    final newToken = await collection.getStoken();
    _logger
      ..finest('Restored stoken: $oldToken')
      ..finest('New stoken: $newToken');
    if (newToken == oldToken) {
      _logger.finer(
        'Skipping collection $uid, was not modified since the last sync',
      );
      return false;
    }

    final updatedCollection = await _processItems(
      uid,
      collection,
      itemManager,
      oldToken,
    );

    await _configLoader.updateConfig(
      (c) => c.copyWith(
        collectionStokens: newToken != null
            ? c.collectionStokens.updatedWith(uid, newToken)
            : c.collectionStokens.updatedWithout(uid),
      ),
    );

    return updatedCollection;
  }

  Future<void> delete(String uid) async {
    _logger.info('Removing deleted collection $uid');
    await _configLoader.updateConfig(
      (c) => c.copyWith(
        collectionStokens: c.collectionStokens.updatedWithout(uid),
      ),
    );
  }

  Future<bool> _processItems(
    String uid,
    EtebaseCollection collection,
    EtebaseItemManager itemManager,
    String? oldToken,
  ) async {
    _logger.finer('Processing updated items of collection $uid');

    var updatedCollection = false;

    var stoken = oldToken;
    var isDone = true;
    do {
      final response = await itemManager.list(
        EtebaseFetchOptions(stoken: stoken),
      );

      try {
        final updatedItems = <EtebaseItem>[];

        for (final item in await response.getData()) {
          final result = await _itemSync.syncItem(
            itemManager,
            collection,
            item,
          );

          if (result.itemModified) {
            updatedItems.add(item);
          }
          if (result.collectionModified) {
            updatedCollection = true;
          }
        }

        if (updatedItems.isNotEmpty) {
          _logger.fine(
            'Uploading ${updatedItems.length} modified items '
            'for collection $uid',
          );
          await itemManager.transaction(updatedItems);
        }

        isDone = await response.isDone();
        stoken = isDone ? null : await response.getStoken();
        _logger.finest(
          'Next stoken for collection $uid: $stoken (isDone: $isDone)',
        );
      } finally {
        await response.dispose();
      }
    } while (!isDone);

    return updatedCollection;
  }
}
