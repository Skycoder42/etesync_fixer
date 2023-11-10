import 'dart:io';

import 'package:etesync_fixer/src/cli/cli_options.dart';
import 'package:etesync_fixer/src/etebase/account_manager.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  Logger.root.onRecord.listen(stdout.writeln);

  final container = ProviderContainer();
  try {
    container.read(cliOptionsProvider.notifier).parse(arguments);

    final account = await container.read(accountManagerProvider.future);
    // ignore: avoid_print
    print(await account.fetchDashboardUrl());
  } finally {
    container.dispose();
  }
}
