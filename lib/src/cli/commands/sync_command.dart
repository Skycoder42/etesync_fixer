import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../etebase/account_manager.dart';

part 'sync_command.g.dart';

@visibleForTesting
@Riverpod(keepAlive: true)
SyncCommand syncCommand(SyncCommandRef ref) => SyncCommand(ref);

class SyncCommand extends Command<int> {
  final SyncCommandRef ref;

  SyncCommand(this.ref);

  @override
  String get name => 'sync';

  @override
  String get description => 'Run the synchronization.';

  @override
  bool get takesArguments => false;

  @override
  String get invocation =>
      super.invocation.replaceAll('[arguments]', '[options]');

  @override
  Future<int> run() async {
    final account = await ref.read(accountManagerProvider.future);
    final url = await account.fetchDashboardUrl();
    return url.toString().length;
  }
}
