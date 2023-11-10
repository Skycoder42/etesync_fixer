import 'dart:io';
import 'dart:typed_data';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

part 'options.g.dart';

@CliOptions()
@immutable
final class Options {
  @CliOption(
    convert: _uriFromString,
    abbr: 's',
    valueHelp: 'url',
    help:
        'Use a custom etebase server. By default, the standard server is used.',
  )
  final Uri? server;

  @CliOption(
    abbr: 'L',
    valueHelp: 'path',
    defaultsTo: '/usr/lib/libetebase.so',
    help: 'The path to the libetebase.so.',
  )
  final String libetebasePath;

  @CliOption(
    convert: _binaryDataFromPathString,
    abbr: 'k',
    valueHelp: 'path',
    help: 'The path to a binary file containing the encryption key used to '
        'secure the persisted account data.',
  )
  final Uint8List? encryptionKey;

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

  @CliOption(
    abbr: 'v',
    negatable: false,
    defaultsTo: false,
    help: 'Prints the current version of the tool.',
  )
  final bool version;

  @CliOption(
    abbr: 'h',
    negatable: false,
    defaultsTo: false,
    help: 'Prints usage information.',
  )
  final bool help;

  @visibleForTesting
  const Options({
    required this.server,
    required this.libetebasePath,
    required this.encryptionKey,
    required this.logLevel,
    this.version = false,
    this.help = false,
  });

  static ArgParser buildArgParser() => _$populateOptionsParser(
        ArgParser(
          allowTrailingOptions: false,
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        ),
      );

  static Options parseOptions(ArgResults argResults) =>
      _$parseOptionsResult(argResults);
}

Uri? _uriFromString(String? uri) => uri != null ? Uri.parse(uri) : null;

Level _logLevelFromString(String level) =>
    Level.LEVELS.singleWhere((element) => element.name == level.toUpperCase());

Uint8List? _binaryDataFromPathString(String? path) =>
    path != null ? File(path).readAsBytesSync() : null;
