import 'package:args/command_runner.dart';

import '../../riverpod/riverpod_command_runner.dart';
import 'fingerprint_command.dart';
import 'login_command.dart';
import 'logout_command.dart';

class AccountCommand extends Command<int> with RiverpodCommand {
  AccountCommand() {
    addSubcommand(LoginCommand());
    addSubcommand(LogoutCommand());
    addSubcommand(FingerprintCommand());
  }

  @override
  String get name => 'account';

  @override
  String get description => 'Account related operations.';
}
