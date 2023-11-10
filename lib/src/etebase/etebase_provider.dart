import 'dart:ffi';

import 'package:etebase/etebase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cli/cli_options.dart';

part 'etebase_provider.g.dart';

@Riverpod(keepAlive: true)
void etebaseInitializer(EtebaseInitializerRef ref) {
  final options = ref.watch(cliOptionsProvider);
  Etebase.ensureInitialized(
    () => DynamicLibrary.open(options.libetebasePath),
    logLevel: options.logLevel.value,
    overwrite: true,
  );
}

@Riverpod(keepAlive: true)
Future<EtebaseClient> etebaseClient(EtebaseClientRef ref) {
  ref
    ..watch(etebaseInitializerProvider)
    ..onDispose(() => ref.state.valueOrNull?.dispose());
  return EtebaseClient.create(
    'etesync-fixer',
    ref.watch(cliOptionsProvider).server,
  );
}
