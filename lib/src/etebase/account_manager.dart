import 'dart:async';

import 'package:etebase/etebase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cli/global_options.dart';
import '../config/config_loader.dart';
import '../extensions/riverpod_extensions.dart';
import 'etebase_provider.dart';

part 'account_manager.g.dart';

class NotLoggedInException implements Exception {
  @override
  String toString() => 'You are not logged in! Run etebase-fixer login first.';
}

@Riverpod(keepAlive: true)
class AccountManager extends _$AccountManager {
  @override
  Future<EtebaseAccount?> build() {
    ref.onDispose(() => state.valueOrNull?.dispose());
    return Future.value();
  }

  Future<void> restore() => updateAsync((oldAccount) async {
        if (oldAccount != null) {
          return oldAccount;
        }

        final encryptedAccountData = await ref.read(
          configLoaderProvider.selectAsync((c) => c.encryptedAccountData),
        );
        if (encryptedAccountData == null) {
          throw NotLoggedInException();
        }

        final encryptionKey = ref.read(
          globalOptionsProvider.select((o) => o.encryptionKey),
        );
        final client = await ref.read(etebaseClientProvider.future);

        return EtebaseAccount.restore(
          client,
          encryptedAccountData,
          encryptionKey,
        );
      });

  Future<void> login(String username, String password) =>
      updateAsync((oldAccount) async {
        if (oldAccount != null) {
          return oldAccount;
        }

        final client = await ref.read(etebaseClientProvider.future);
        final account = await EtebaseAccount.login(client, username, password);

        try {
          final encryptionKey = ref.read(
            globalOptionsProvider.select((o) => o.encryptionKey),
          );
          final accountData = await account.save(encryptionKey);

          await ref.read(configLoaderProvider.notifier).updateConfig(
                (c) => c.copyWith(
                  encryptedAccountData: accountData,
                ),
              );

          return account;

          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          await account.dispose();
          rethrow;
        }
      });

  Future<void> logout() => updateAsync((oldAccount) async {
        await ref.read(configLoaderProvider.notifier).updateConfig(
              (c) => c.copyWith(
                encryptedAccountData: null,
              ),
            );

        if (oldAccount != null) {
          await oldAccount.logout();
          await oldAccount.dispose();
        }

        return null;
      });
}
