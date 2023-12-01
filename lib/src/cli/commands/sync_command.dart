import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:meta/meta.dart';

import '../../config/config_loader.dart';
import '../../etebase/account_manager.dart';
import '../../sync/account_sync.dart';
import '../riverpod/riverpod_command_runner.dart';

part 'sync_command.g.dart';

@immutable
@CliOptions(createCommand: true)
final class SyncOptions {
  @CliOption(
    abbr: 'f',
    help: 'If enabled, resync all collections instead of '
        'just the changes since the last sync.',
  )
  final bool fullSync;

  const SyncOptions({
    required this.fullSync,
  });
}

class SyncCommand extends _$SyncOptionsCommand<int> with RiverpodCommand {
  @override
  String get name => 'sync';

  @override
  String get description => 'Run the synchronization.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    if (_options.fullSync) {
      await container.read(configLoaderProvider.notifier).updateConfig(
            (c) => c.copyWith(
              stoken: null,
              collectionStokens: const {},
            ),
          );
    }

    await container.read(accountManagerProvider.notifier).restore();

    final accountSync = await container.read(accountSyncProvider.future);
    await accountSync.sync();

    return 0;
  }
}
