import 'dart:io';

import 'package:args/command_runner.dart';

// ignore: no_self_package_imports
import '../../../gen/pubspec.yaml.g.dart';
import '../riverpod/riverpod_command_runner.dart';

class VersionCommand extends Command<int> with RiverpodCommand {
  @override
  String get name => 'version';

  @override
  String get description => 'Print the version of the tool.';

  @override
  bool get takesArguments => false;

  @override
  bool get hidden => true;

  @override
  int run() {
    stdout
      ..write(runner!.executableName)
      ..write(' ')
      ..writeln(Pubspec.version.canonical);
    return 0;
  }
}
