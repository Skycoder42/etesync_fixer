import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'config.dart';

part 'config_loader.g.dart';

@Riverpod(keepAlive: true)
class ConfigLoader extends _$ConfigLoader {
  @override
  Future<Config> build() async {
    final stringContent = await File(_configPath).readAsString();
    return Config.fromJson(json.decode(stringContent) as Map<String, dynamic>);
  }

  Future<void> updateConfig(Config Function(Config c) updateCb) async {
    try {
      final updatedConfig = await update(updateCb);
      await File(_configPath).writeAsString(json.encode(updatedConfig));
    } on Exception catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // TODO clean / config?
  String get _configPath => '/etc/etesync-fixer.json';
}
