import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../../../etebase/account_manager.dart';
import '../../../etebase/etebase_provider.dart';
import '../../../extensions/etebase_extensions.dart';
import '../../../extensions/logging_extensions.dart';
import '../../../io/json_writer.dart';
import '../../../io/structured_writer.dart';
import '../../../io/table_writer.dart';
import '../../riverpod/riverpod_command_runner.dart';

part 'list_command.g.dart';

enum ListFormat {
  table,
  json,
}

@immutable
@CliOptions(createCommand: true)
final class ListOptions {
  @CliOption(
    abbr: 'f',
    defaultsTo: ListFormat.table,
    allowedHelp: {
      ListFormat.table: 'A human readable table.',
      ListFormat.json: 'Machine readable JSON.',
    },
    valueHelp: 'format',
    help: 'Select the format you want the output to have.',
  )
  final ListFormat format;

  const ListOptions({
    required this.format,
  });
}

class ListCommand extends _$ListOptionsCommand<int> with RiverpodCommand {
  final _logger = Logger('$ListCommand');

  @override
  String get name => 'list';

  @override
  String get description =>
      'Lists all incoming collection invitations, if any.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    _logger
      ..command(this)
      ..config('format=${_options.format}');

    await container.read(accountManagerProvider.notifier).restore();

    final writer = await _createWriter();

    final invitationManager = await container.read(
      etebaseInvitationManagerProvider.future,
    );

    await invitationManager.processIncoming(
      (invitation) => _processInvitation(writer, invitation),
    );
    writer.writeTo(stdout);

    return 0;
  }

  Future<StructuredWriter> _createWriter() async {
    switch (_options.format) {
      case ListFormat.json:
        return JsonWriter();
      case ListFormat.table:
        final client = await container.read(etebaseClientProvider.future);
        return TableWriter(client)
          ..addHeaders([
            'uid',
            'username',
            'collection',
            'accessLevel',
            'fromUsername',
            'fromPubkey',
          ]);
    }
  }

  Future<bool> _processInvitation(
    StructuredWriter writer,
    EtebaseSignedInvitation invitation,
  ) async {
    writer.addRow({
      'uid': await invitation.getUid(),
      'username': await invitation.getUsername(),
      'collection': await invitation.getCollection(),
      'accessLevel': (await invitation.getAccessLevel()).name,
      'fromUsername': await invitation.getFromUsername(),
      'fromPubkey': await invitation.getFromPubkey(),
    });
    return false;
  }
}
