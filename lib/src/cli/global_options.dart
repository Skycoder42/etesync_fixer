import 'dart:io';
import 'dart:typed_data';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'riverpod/riverpod_command_runner.dart';

part 'global_options.g.dart';

@Riverpod(keepAlive: true)
GlobalOptions globalOptions(GlobalOptionsRef ref) =>
    throw StateError('globalOptionsProvider must be overridden');

@immutable
@CliOptions()
final class GlobalOptions {
  @CliOption(
    abbr: 'L',
    valueHelp: 'path',
    defaultsTo: '/usr/lib/libetebase.so',
    help: 'The path to the libetebase.so.',
  )
  final String libetebase;

  @CliOption(
    convert: _binaryDataFromPathString,
    abbr: 'k',
    valueHelp: 'path',
    help: 'The path to a binary file containing the encryption key used to '
        'secure the persisted account data.',
  )
  final Uint8List? encryptionKey;

  @CliOption(
    abbr: 'c',
    valueHelp: 'path',
    defaultsTo: '/etc/etesync-fixer.json',
    help: 'The path to the configuration file where app specific settings '
        'should be persisted to.',
  )
  final String config;

  @CliOption(
    convert: _logLevelFromString,
    abbr: 'l',
    allowed: [
      'all',
      'finest',
      'finer',
      'fine',
      'config',
      'info',
      'warning',
      'severe',
      'shout',
      'off',
    ],
    defaultsTo: 'info',
    valueHelp: 'level',
    help: 'Customize the logging level. '
        'Listed from most verbose (all) to least verbose (off).',
  )
  final Level logLevel;

  @visibleForTesting
  const GlobalOptions({
    required this.libetebase,
    required this.encryptionKey,
    required this.config,
    required this.logLevel,
  });

  static ArgParser configureArgParser(ArgParser argParser) =>
      _$populateGlobalOptionsParser(argParser);

  static GlobalOptions parseOptions(ArgResults argResults) =>
      _$parseGlobalOptionsResult(argResults);
}

mixin GlobalOptionsRunnerMixin<TReturn>
    on RiverpodCommandRunner<TReturn, GlobalOptions> {
  @override
  @protected
  void configureGlobalOptions(ArgParser argParser) =>
      _$populateGlobalOptionsParser(argParser);

  @override
  @protected
  Override parseGlobalOptions(ArgResults argResults) =>
      globalOptionsProvider.overrideWithValue(
        _$parseGlobalOptionsResult(argResults),
      );
}

Level _logLevelFromString(String level) =>
    Level.LEVELS.singleWhere((element) => element.name == level.toUpperCase());

Uint8List? _binaryDataFromPathString(String? path) =>
    path != null ? File(path).readAsBytesSync() : null;
