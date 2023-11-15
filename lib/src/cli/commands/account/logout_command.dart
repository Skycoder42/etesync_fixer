import 'dart:async';

import 'package:args/command_runner.dart';

import '../../../etebase/account_manager.dart';
import '../../riverpod/riverpod_command_runner.dart';

class LogoutCommand extends Command<int> with RiverpodCommand {
  @override
  String get name => 'logout';

  @override
  String get description => 'Logs you out and deletes persisted account data.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    await container.read(accountManagerProvider.notifier).logout();
    return 0;
  }
}
