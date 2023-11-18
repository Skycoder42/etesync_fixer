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

  Future<void> sync(
    EtebaseCollection collection,
    EtebaseItemManager itemManager,
  ) async {
    final uid = await collection.getUid();
    if (await collection.isDeleted()) {
      await delete(uid);
      return;
    }

    final oldToken = _configLoader.state.collectionStokens[uid];
    final newToken = await collection.getStoken();
    _logger
      ..info('$uid - oldToken: $oldToken')
      ..info('$uid - newToken: $newToken');

    await _processItems(itemManager, oldToken);

    await _configLoader.updateConfig(
      (c) => c.copyWith(
        collectionStokens: newToken != null
            ? c.collectionStokens.updatedWith(uid, newToken)
            : c.collectionStokens.updatedWithout(uid),
      ),
    );
  }

  Future<void> delete(String uid) async {
    await _configLoader.updateConfig(
      (c) => c.copyWith(
        collectionStokens: c.collectionStokens.updatedWithout(uid),
      ),
    );
  }

  Future<void> _processItems(
    EtebaseItemManager itemManager,
    String? oldToken,
  ) async {
    var stoken = oldToken;
    var isDone = true;
    do {
      final response = await itemManager.list(
        EtebaseFetchOptions(stoken: stoken),
      );

      try {
        for (final item in await response.getData()) {
          await _itemSync.syncItem(itemManager, item);
        }

        isDone = await response.isDone();
        stoken = isDone ? null : await response.getStoken();
      } finally {
        await response.dispose();
      }
    } while (!isDone);
  }
}
