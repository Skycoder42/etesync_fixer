import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:etebase/etebase.dart';
import 'package:meta/meta.dart';

import '../../../etebase/account_manager.dart';
import '../../../etebase/etebase_provider.dart';
import '../../riverpod/riverpod_command_runner.dart';

part 'list_command.g.dart';

enum ListFormat {
  table,
  json,
}

@immutable
@CliOptions(createCommand: true)
final class ListOptions {
  final ListFormat format;

  const ListOptions({
    required this.format,
  });
}

class ListCommand extends _$ListOptionsCommand<int> with RiverpodCommand {
  @override
  String get name => 'list';

  @override
  String get description =>
      'Lists all incoming collection invitations, if any.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    await container.read(accountManagerProvider.notifier).restore();

    final invitationManager = await container.read(
      etebaseInvitationManagerProvider.future,
    );

    String? iterator;
    var isDone = true;
    do {
      final response = await invitationManager.listIncoming(
        EtebaseFetchOptions(iterator: iterator),
      );

      try {
        final invitations = await response.getData();

        for (final invitation in invitations) {
          await _processInvitation(invitation);
        }

        iterator = await response.getIterator();
        isDone = await response.isDone();
      } finally {
        await response.dispose();
      }
    } while (!isDone);

    return 0;
  }

  Future<void> _processInvitation(EtebaseSignedInvitation invitation) {
    invitation.getAccessLevel();
    invitation.getCollection();
    invitation.getFromPubkey();
    invitation.getFromUsername();
    invitation.getUid();
    invitation.getUsername();
  }
}
