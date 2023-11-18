import 'package:etebase/etebase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/config_loader.dart';
import '../etebase/etebase_provider.dart';
import 'collection_sync.dart';

part 'account_sync.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
Future<AccountSync> accountSync(AccountSyncRef ref) async => AccountSync(
      await ref.watch(etebaseCollectionManagerProvider.future),
      ref.watch(configLoaderProvider.notifier),
      ref.watch(collectionSyncProvider),
    );
// coverage:ignore-end

class AccountSync {
  final EtebaseCollectionManager _collectionManager;
  final ConfigLoader _configLoader;
  final CollectionSync _collectionSync;

  AccountSync(
    this._collectionManager,
    this._configLoader,
    this._collectionSync,
  );

  Future<void> sync() async {
    var stoken = _configLoader.state.stoken;
    var isDone = true;
    do {
      final response = await _collectionManager.list(
        'etebase.vtodo',
        EtebaseFetchOptions(stoken: stoken),
      );

      try {
        for (final collection in await response.getData()) {
          final itemManager =
              await _collectionManager.getItemManager(collection);
          try {
            await _collectionSync.sync(collection, itemManager);
          } finally {
            await itemManager.dispose();
          }
        }

        for (final collection in await response.getRemovedMemberships()) {
          await _collectionSync.delete(await collection.getUid());
        }

        stoken = await response.getStoken();
        isDone = await response.isDone();
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
