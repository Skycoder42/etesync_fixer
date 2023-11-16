import 'dart:ffi';

import 'package:etebase/etebase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cli/global_options.dart';
import '../config/config_loader.dart';
import 'account_manager.dart';

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

@Riverpod(keepAlive: true)
Future<EtebaseAccount> etebaseAccount(EtebaseAccountRef ref) async {
  final account = await ref.watch(accountManagerProvider.future);
  if (account == null) {
    throw NotLoggedInException();
  }
  return account;
}

@Riverpod(keepAlive: true)
Future<EtebaseCollectionInvitationManager> etebaseInvitationManager(
  EtebaseInvitationManagerRef ref,
) async {
  final account = await ref.watch(etebaseAccountProvider.future);
  ref.onDispose(() => ref.state.valueOrNull?.dispose());
  return account.getInvitationManager();
}

@Riverpod(keepAlive: true)
Future<EtebaseCollectionManager> etebaseCollectionManager(
  EtebaseCollectionManagerRef ref,
) async {
  final account = await ref.watch(etebaseAccountProvider.future);
  ref.onDispose(() => ref.state.valueOrNull?.dispose());
  return account.getCollectionManager();
}

@riverpod
Future<EtebaseItemManager> etebaseItemManager(
  EtebaseItemManagerRef ref,
  EtebaseCollection collection,
) async {
  final collectionManager =
      await ref.watch(etebaseCollectionManagerProvider.future);
  ref.onDispose(() => ref.state.valueOrNull?.dispose());
  return collectionManager.getItemManager(collection);
}
