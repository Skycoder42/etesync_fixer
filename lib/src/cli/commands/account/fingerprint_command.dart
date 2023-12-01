import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';

import '../../../etebase/account_manager.dart';
import '../../../etebase/etebase_provider.dart';
import '../../../extensions/logging_extensions.dart';
import '../../riverpod/riverpod_command_runner.dart';

class FingerprintCommand extends Command<int> with RiverpodCommand {
  final _logger = Logger('$FingerprintCommand');

  @override
  String get name => 'fingerprint';

  @override
  String get description => 'Displays the current account fingerprint.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    _logger.command(this);

    await container.read(accountManagerProvider.notifier).restore();

    final client = await container.read(etebaseClientProvider.future);
    final invitationManager = await container.read(
      etebaseInvitationManagerProvider.future,
    );

    final pubKey = await invitationManager.getPubkey();
    final prettyPubKey = await EtebaseUtils.prettyFingerprint(client, pubKey);

    stdout.writeln(prettyPubKey);

    return 0;
  }
}
