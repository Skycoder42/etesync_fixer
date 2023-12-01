import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../../../etebase/account_manager.dart';
import '../../../etebase/etebase_provider.dart';
import '../../../extensions/etebase_extensions.dart';
import '../../../extensions/logging_extensions.dart';
import '../../riverpod/riverpod_command_runner.dart';

class RejectCommand extends Command<int> with RiverpodCommand {
  final _logger = Logger('$RejectCommand');

  @override
  String get name => 'reject';

  @override
  String get description => 'Reject an invitation to a collection.';

  @override
  bool get takesArguments => true;

  @override
  String get invocation => '${super.invocation} <invitation-uid>';

  @override
  Future<int> run() => switch (argResults!.rest) {
        [] => usageException(
            'Missing required positional parameter <invitation-uid>',
          ),
        [final invitationUid] => _run(invitationUid),
        _ => usageException('Too many arguments'),
      };

  Future<int> _run(String invitationUid) async {
    _logger.command(this);

    await container.read(accountManagerProvider.notifier).restore();

    final invitationManager = await container.read(
      etebaseInvitationManagerProvider.future,
    );

    var didReject = false;
    await invitationManager.processIncoming(
      (invitation) async {
        final uid = await invitation.getUid();
        if (uid == invitationUid) {
          await invitationManager.reject(invitation);
          _logger.info('Invitation rejected!');
          didReject = true;
          return true;
        } else {
          return false;
        }
      },
    );

    if (!didReject) {
      _logger.severe('No invitation with id $invitationUid was found!');
      return 1;
    }

    return 0;
  }
}
