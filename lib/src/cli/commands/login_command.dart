import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config/config_loader.dart';
import '../../etebase/account_manager.dart';

part 'login_command.g.dart';

@visibleForTesting
@Riverpod(keepAlive: true)
LoginCommand loginCommand(LoginCommandRef ref) => LoginCommand(ref);

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

class LoginCommand extends _$LoginOptionsCommand<int> {
  final LoginCommandRef ref;

  LoginCommand(this.ref);

  @override
  String get name => 'login';

  @override
  String get description => 'Log into your etebase account';

  @override
  bool get takesArguments => true;

  @override
  String get invocation => super
      .invocation
      .replaceFirst('[arguments]', '[options] <username> <password>');

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
    await ref.read(configLoaderProvider.notifier).updateConfig(
          (c) => c.copyWith(
            server: _options.server,
          ),
        );

    final accountManager = ref.read(accountManagerProvider.notifier);
    await accountManager.login(username, password);
    return 0;
  }
}

Uri? _uriFromString(String? uri) => uri != null ? Uri.parse(uri) : null;
