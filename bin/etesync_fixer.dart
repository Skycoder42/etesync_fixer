import 'dart:io';

import 'package:etesync_fixer/src/cli/cli_options.dart';
import 'package:etesync_fixer/src/etebase/etebase_provider.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  Logger.root.onRecord.listen(stdout.writeln);

  final container = ProviderContainer();
  try {
    container.read(cliOptionsProvider.notifier).parse(arguments);

    final client = await container.read(etebaseClientProvider.future);
    // ignore: avoid_print
    print(await client.checkEtebaseServer());
  } finally {
    container.dispose();
  }
}
