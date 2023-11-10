import 'dart:io';

import 'package:etesync_fixer/src/cli/cli.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  Logger.root.onRecord.listen(stdout.writeln);

  final container = ProviderContainer();
  try {
    final cli = container.read(cliProvider);
    exitCode = await cli.run(arguments) ?? 0;
  } finally {
    container.dispose();
  }
}
