import 'package:args/command_runner.dart';
import 'package:etebase/etebase.dart';

import '../../config/config_loader.dart';
import '../../etebase/account_manager.dart';
import '../../etebase/etebase_provider.dart';
import '../../sync/collection_sync.dart';
import '../riverpod/riverpod_command_runner.dart';

class SyncCommand extends Command<int> with RiverpodCommand {
  @override
  String get name => 'sync';

  @override
  String get description => 'Run the synchronization.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    await container.read(accountManagerProvider.notifier).restore();

    final collectionManager =
        await container.read(etebaseCollectionManagerProvider.future);
    final collectionSync = container.read(collectionSyncProvider);

    var stoken = container.read(configLoaderProvider.select((c) => c.stoken));
    var isDone = true;
    do {
      final response = await collectionManager.list(
        'etebase.vtodo',
        EtebaseFetchOptions(stoken: stoken),
      );

      try {
        for (final collection in await response.getData()) {
          final itemManagerProvider = etebaseItemManagerProvider(collection);
          final itemManager = await container.read(itemManagerProvider.future);
          try {
            await collectionSync.updateCollection(collection, itemManager);
          } finally {
            container.invalidate(itemManagerProvider);
          }
        }

        for (final collection in await response.getRemovedMemberships()) {
          await collectionSync.deleteCollection(await collection.getUid());
        }

        stoken = await response.getStoken();
        isDone = await response.isDone();
      } finally {
        await response.dispose();
      }
    } while (!isDone);

    await container.read(configLoaderProvider.notifier).updateConfig(
          (c) => c.copyWith(
            stoken: stoken,
          ),
        );

    return 0;
  }
}
