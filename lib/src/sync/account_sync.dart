import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/config_loader.dart';
import '../etebase/etebase_provider.dart';
import 'collection_sync.dart';
import 'sync_job_registry.dart';

part 'account_sync.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
Future<AccountSync> accountSync(AccountSyncRef ref) async => AccountSync(
      await ref.watch(etebaseCollectionManagerProvider.future),
      ref.watch(configLoaderProvider.notifier),
      ref.watch(collectionSyncProvider),
      ref.watch(syncJobRegistryProvider),
    );
// coverage:ignore-end

class AccountSync {
  final EtebaseCollectionManager _collectionManager;
  final ConfigLoader _configLoader;
  final CollectionSync _collectionSync;
  final SyncJobRegistry _syncJobRegistry;

  final _logger = Logger('$AccountSync');

  AccountSync(
    this._collectionManager,
    this._configLoader,
    this._collectionSync,
    this._syncJobRegistry,
  );

  Future<void> sync() async {
    _logger.fine('Syncing collections');
    var stoken = _configLoader.state.stoken;
    _logger.finest('Restored stoken: $stoken');
    var isDone = true;
    do {
      final allCollectionTypes = _syncJobRegistry.allCollectionTypes;
      _logger.finer('Fetching collections for types: $allCollectionTypes');

      final response = await _collectionManager.listMulti(
        allCollectionTypes.toList(),
        EtebaseFetchOptions(stoken: stoken),
      );

      try {
        for (final collection in await response.getData()) {
          final uid = await collection.getUid();
          final collectionType = await collection.getCollectionType();
          _logger.fine(
            'Processing updated collection $uid (type: $collectionType)',
          );
          final itemManager =
              await _collectionManager.getItemManager(collection);
          try {
            await _collectionSync.sync(collection, itemManager);
          } finally {
            await itemManager.dispose();
          }
        }

        for (final collection in await response.getRemovedMemberships()) {
          final uid = await collection.getUid();
          _logger.fine('Processing removed shared collection $uid');
          await _collectionSync.delete(uid);
        }

        stoken = await response.getStoken();
        isDone = await response.isDone();
        _logger.finest('Next stoken: $stoken (isDone: $isDone)');
      } finally {
        await response.dispose();
      }
    } while (!isDone);

    await _configLoader.updateConfig(
      (c) => c.copyWith(
        stoken: stoken,
      ),
    );
  }
}
