import 'dart:io';

import 'package:etesync_fixer/src/cli/cli.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> arguments) async {
  Logger.root.onRecord.listen(stdout.writeln);

  final cli = Cli();
  exitCode = await cli.run(arguments) ?? 0;
}
