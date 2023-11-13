import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:meta/meta.dart';

import '../../../config/config_loader.dart';
import '../../../etebase/account_manager.dart';
import '../../riverpod/riverpod_command_runner.dart';

part 'login_command.g.dart';

@immutable
@CliOptions(createCommand: true)
final class LoginOptions {
  @CliOption(
    convert: _uriFromString,
    abbr: 's',
    valueHelp: 'url',
    help:
        'Use a custom etebase server. By default, the standard server is used.',
  )
  final Uri? server;

  const LoginOptions({
    required this.server,
  });
}

class LoginCommand extends _$LoginOptionsCommand<int>
    with RiverpodCommand<int> {
  @override
  String get name => 'login';

  @override
  String get description => 'Log into your etebase account';

  @override
  bool get takesArguments => true;

  @override
  String get invocation => '${super.invocation} <username> <password>';

  @override
  Future<int> run() {
    switch (argResults!.rest) {
      case []:
        usageException('Missing required positional parameter <username>');
      case [_]:
        usageException('Missing required positional parameter <password>');
      case [final username, final password]:
        return _run(username, password);
      default:
        usageException('Too many arguments');
    }
  }

  Future<int> _run(String username, String password) async {
    await container.read(configLoaderProvider.notifier).updateConfig(
          (c) => c.copyWith(
            server: _options.server,
          ),
        );

    final accountManager = container.read(accountManagerProvider.notifier);
    await accountManager.login(username, password);
    return 0;
  }
}

Uri? _uriFromString(String? uri) => uri != null ? Uri.parse(uri) : null;
