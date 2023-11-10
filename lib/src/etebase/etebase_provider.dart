import 'dart:ffi';

import 'package:etebase/etebase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cli/cli.dart';
import '../config/config_loader.dart';

part 'etebase_provider.g.dart';

@Riverpod(keepAlive: true)
void _etebaseInitializer(_EtebaseInitializerRef ref) {
  final options = ref.watch(globalOptionsProvider);
  Etebase.ensureInitialized(
    () => DynamicLibrary.open(options.libetebase),
    logLevel: options.logLevel.value,
    overwrite: true,
  );
}

@Riverpod(keepAlive: true)
Future<EtebaseClient> etebaseClient(EtebaseClientRef ref) async {
  ref
    ..watch(_etebaseInitializerProvider)
    ..onDispose(() => ref.state.valueOrNull?.dispose());

  final config = await ref.watch(configLoaderProvider.future);
  return EtebaseClient.create('etesync-fixer', config.server);
}
