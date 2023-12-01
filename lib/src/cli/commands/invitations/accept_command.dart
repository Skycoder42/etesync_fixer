import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../../../etebase/account_manager.dart';
import '../../../etebase/etebase_provider.dart';
import '../../../extensions/etebase_extensions.dart';
import '../../../extensions/logging_extensions.dart';
import '../../riverpod/riverpod_command_runner.dart';

class AcceptCommand extends Command<int> with RiverpodCommand {
  final _logger = Logger('$AcceptCommand');

  @override
  String get name => 'accept';

  @override
  String get description => 'Accept an invitation to a collection.';

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

    var didAccept = false;
    await invitationManager.processIncoming(
      (invitation) async {
        final uid = await invitation.getUid();
        if (uid == invitationUid) {
          await invitationManager.accept(invitation);
          _logger.info('Invitation accepted!');
          didAccept = true;
          return true;
        } else {
          return false;
        }
      },
    );

    if (!didAccept) {
      _logger.severe('No invitation with id $invitationUid was found!');
      return 1;
    }

    return 0;
  }
}
