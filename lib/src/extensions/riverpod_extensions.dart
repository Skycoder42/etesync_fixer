// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:riverpod/riverpod.dart';

extension AsyncNotifierX<T> on AsyncNotifier<T> {
  Future<void> updateAsync(FutureOr<T> Function(T) cb) async {
    final oldState = await future;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => cb(oldState));
  }
}
