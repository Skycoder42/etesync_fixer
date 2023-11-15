import 'package:args/command_runner.dart';

import '../../riverpod/riverpod_command_runner.dart';
import 'list_command.dart';

class InvitationsCommand extends Command<int> with RiverpodCommand {
  InvitationsCommand() {
    addSubcommand(ListCommand());
  }

  @override
  String get name => 'invitations';

  @override
  String get description => 'Manage incoming invitations to collections.';
}
