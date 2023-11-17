import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cli/global_options.dart';
import 'config.dart';

part 'config_loader.g.dart';

@Riverpod(keepAlive: true)
class ConfigLoader extends _$ConfigLoader {
  // ignore: avoid_public_notifier_properties
  @override
  Config get state => super.state;

  @override
  Config build() {
    final configFile = File(ref.watch(globalOptionsProvider).config);
    if (!configFile.existsSync()) {
      return Config.empty;
    }

    final stringContent = configFile.readAsStringSync();
    return Config.fromJson(json.decode(stringContent) as Map<String, dynamic>);
  }

  Future<void> updateConfig(Config Function(Config c) updateCb) async {
    state = updateCb(state);
    final configFile = File(ref.read(globalOptionsProvider).config);
    await configFile.writeAsString(json.encode(state));
  }
}
