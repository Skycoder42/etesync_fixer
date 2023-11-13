import 'dart:io';

import 'package:etesync_fixer/src/cli/cli.dart';

Future<void> main(List<String> arguments) async {
  final cli = Cli();
  exitCode = await cli.run(arguments) ?? 0;
}
