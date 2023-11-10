import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cli/cli.dart';
import 'config.dart';

part 'config_loader.g.dart';

@Riverpod(keepAlive: true)
class ConfigLoader extends _$ConfigLoader {
  @override
  Future<Config> build() async {
    final configFile = File(ref.watch(globalOptionsProvider).config);
    if (!configFile.existsSync()) {
      return Config.empty;
    }

    final stringContent = await configFile.readAsString();
    return Config.fromJson(json.decode(stringContent) as Map<String, dynamic>);
  }

  Future<void> updateConfig(Config Function(Config c) updateCb) async {
    try {
      final updatedConfig = await update(updateCb);
      final configFile = File(ref.read(globalOptionsProvider).config);
      await configFile.writeAsString(json.encode(updatedConfig));
    } on Exception catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
