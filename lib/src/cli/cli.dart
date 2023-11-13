import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../constants/pubspec.yaml.g.dart';
import 'commands/account/account_command.dart';
import 'commands/sync_command.dart';
import 'commands/version_command.dart';
import 'global_options.dart';
import 'riverpod/riverpod_command_runner.dart';

class Cli extends RiverpodCommandRunner<int> with GlobalOptionsRunnerMixin {
  Cli()
      : super(
          Platform.script.pathSegments.last,
          Pubspec.description,
        ) {
    addCommand(AccountCommand());
    addCommand(SyncCommand());
    addCommand(VersionCommand());
  }

  @override
  FutureOr<int?> beforeRunCommand(ProviderContainer container) {
    final globalOptions = container.read(globalOptionsProvider);

    Logger.root.onRecord.listen(stdout.writeln);
    Logger.root.level = globalOptions.logLevel;

    if (globalOptions.version) {
      final versionCommand = commands['version'];
      return versionCommand!.run()!;
    }

    return null;
  }
}
