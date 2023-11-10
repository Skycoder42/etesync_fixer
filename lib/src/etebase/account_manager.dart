import 'dart:async';

import 'package:etebase/etebase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cli/cli.dart';
import '../config/config_loader.dart';
import 'etebase_provider.dart';

part 'account_manager.g.dart';

class NotLoggedInException implements Exception {
  @override
  String toString() => 'You are not logged in! Run etebase-fixer login first.';
}

@Riverpod(keepAlive: true)
class AccountManager extends _$AccountManager {
  @override
  Future<EtebaseAccount> build() async {
    final config = await ref.watch(configLoaderProvider.future);
    if (config.encryptedAccountData == null) {
      throw NotLoggedInException();
    }

    ref.onDispose(() => state.valueOrNull?.dispose());

    final options = ref.watch(globalOptionsProvider);
    final client = await ref.watch(etebaseClientProvider.future);
    return EtebaseAccount.restore(
      client,
      config.encryptedAccountData!,
      options.encryptionKey,
    );
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();

    ref.onDispose(() => state.valueOrNull?.dispose());

    EtebaseAccount? account;
    try {
      final config = ref.read(globalOptionsProvider);
      final client = await ref.read(etebaseClientProvider.future);
      account = await EtebaseAccount.login(client, username, password);
      final accountData = await account.save(config.encryptionKey);
      await ref.read(configLoaderProvider.notifier).updateConfig(
            (c) => c.copyWith(
              encryptedAccountData: accountData,
            ),
          );
      state = AsyncValue.data(account);
    } on Exception catch (e, s) {
      state = AsyncValue.error(e, s);
      unawaited(account?.dispose());
      rethrow;
    }
  }
}
