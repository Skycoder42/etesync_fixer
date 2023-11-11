import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../constants/pubspec.yaml.g.dart';
import '../riverpod/riverpod_command.dart';

part 'version_command.g.dart';

@visibleForTesting
@Riverpod(keepAlive: true)
VersionCommand versionCommand(VersionCommandRef ref) => VersionCommand(ref);

class VersionCommand extends Command<int> with RiverpodCommand<int> {
  @override
  final Ref ref;

  VersionCommand(this.ref);

  @override
  String get name => 'version';

  @override
  String get description => 'Print the version of the tool.';

  @override
  bool get takesArguments => false;

  @override
  String get invocation => super.invocation.replaceAll('[arguments]', '');

  @override
  int run() {
    stdout
      ..write(runner!.executableName)
      ..write(' ')
      ..writeln(Pubspec.version.canonical);
    return 0;
  }
}