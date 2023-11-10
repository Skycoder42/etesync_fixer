import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/pubspec.yaml.g.dart';
import 'commands/login_command.dart';
import 'commands/sync_command.dart';
import 'commands/version_command.dart';
import 'global_options.dart' as go;

part 'cli.g.dart';

@visibleForTesting
@Riverpod(keepAlive: true)
Cli cli(CliRef ref) => Cli(ref);

class Cli extends CommandRunner<int> {
  final CliRef ref;

  Cli(this.ref)
      : super(
          Platform.script.pathSegments.last,
          Pubspec.description,
        ) {
    go.GlobalOptions.configureArgParser(argParser);

    addCommand(ref.watch(loginCommandProvider));
    addCommand(ref.watch(syncCommandProvider));
    addCommand(ref.watch(versionCommandProvider));
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) {
    final options = go.GlobalOptions.parseOptions(topLevelResults);
    Logger.root.level = options.logLevel;
    ref.read(globalOptionsProvider.notifier)._setOptions(options);

    return super.runCommand(topLevelResults);
  }
}

@visibleForTesting
@Riverpod(keepAlive: true)
class GlobalOptions extends _$GlobalOptions {
  @override
  go.GlobalOptions build() => throw StateError('Not initialized');

  // ignore: use_setters_to_change_properties
  void _setOptions(go.GlobalOptions options) => state = options;
}
