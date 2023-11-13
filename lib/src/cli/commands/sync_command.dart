import 'package:args/command_runner.dart';

import '../../etebase/account_manager.dart';
import '../riverpod/riverpod_command_runner.dart';

class SyncCommand extends Command<int> with RiverpodCommand<int> {
  @override
  String get name => 'sync';

  @override
  String get description => 'Run the synchronization.';

  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    await container.read(accountManagerProvider.notifier).restore();
    final account = await container.read(etebaseAccountProvider.future);
    final url = await account.fetchDashboardUrl();
    return url.toString().length;
  }
}
