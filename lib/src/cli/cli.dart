import 'dart:io';

import '../constants/pubspec.yaml.g.dart';
import 'commands/login_command.dart';
import 'commands/sync_command.dart';
import 'commands/version_command.dart';
import 'global_options.dart';
import 'riverpod/riverpod_command_runner.dart';

class Cli extends RiverpodCommandRunner<int, GlobalOptions>
    with GlobalOptionsRunnerMixin {
  Cli()
      : super(
          globalOptionsProvider,
          Platform.script.pathSegments.last,
          Pubspec.description,
        ) {
    addCommandProvider(loginCommandProvider);
    addCommandProvider(syncCommandProvider);
    addCommandProvider(versionCommandProvider);
  }

  // TODO setup logging
}
