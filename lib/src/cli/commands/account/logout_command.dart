import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../../../etebase/account_manager.dart';
import '../../../extensions/logging_extensions.dart';
import '../../riverpod/riverpod_command_runner.dart';

class LogoutCommand extends Command<int> with RiverpodCommand {
  final _logger = Logger('$LogoutCommand');

  @override
  String get name => 'logout';

  @override
  String get description => 'Logs you out and deletes persisted account data.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    _logger.command(this);

    await container.read(accountManagerProvider.notifier).logout();

    _logger.info('Logout successful!');

    return 0;
  }
}
