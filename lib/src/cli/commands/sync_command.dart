// ignore_for_file: avoid_print

import 'package:args/command_runner.dart';
import 'package:etebase/etebase.dart';

import '../../config/config_loader.dart';
import '../../etebase/account_manager.dart';
import '../../etebase/etebase_provider.dart';
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
    final config = await container.read(configLoaderProvider.future);

    await container.read(accountManagerProvider.notifier).restore();
    final account = await container.read(etebaseAccountProvider.future);

    final collectionManager = await account.getCollectionManager();

    var stoken = config.collectionStoken;
    var isDone = true;
    do {
      final response = await collectionManager.list(
        'etebase.vtodo',
        EtebaseFetchOptions(stoken: stoken),
      );

      try {
        for (final collection in await response.getData()) {
          final itemManager =
              await collectionManager.getItemManager(collection);
          try {
            await _processModified(itemManager, collection);
          } finally {
            await collectionManager.dispose();
          }
        }

        for (final collection in await response.getRemovedMemberships()) {
          await _processUnshared(collection);
        }

        stoken = await response.getStoken();
        isDone = await response.isDone();
      } finally {
        await response.dispose();
      }
    } while (!isDone);

    // await container.read(configLoaderProvider.notifier).updateConfig(
    //       (c) => c.copyWith(
    //         collectionStoken: stoken,
    //       ),
    //     );

    return 0;
  }

  Future<void> _processModified(
    EtebaseItemManager itemManager,
    EtebaseCollection collection,
  ) async {
    print('verify: ${await collection.verify()}');
    print('getUid: ${await collection.getUid()}');
    print('getCollectionType: ${await collection.getCollectionType()}');
    print('getAccessLevel: ${await collection.getAccessLevel()}');
    print('getEtag: ${await collection.getEtag()}');
    print('getStoken: ${await collection.getStoken()}');
    print('getMeta: ${await collection.getMeta()}');
    print('isDeleted: ${await collection.isDeleted()}');
    print('getContent: ${await collection.getContent()}');
  }

  Future<void> _processUnshared(EtebaseRemovedCollection collection) async {
    print('verify: ${await collection.getUid()}');
  }
}
