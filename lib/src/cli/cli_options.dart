import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/pubspec.yaml.g.dart';
import 'options.dart';

part 'cli_options.g.dart';

@Riverpod(keepAlive: true)
class CliOptions extends _$CliOptions {
  final _logger = Logger('$CliOptions');

  @override
  Options build() => throw StateError('CliParser was not initialized!');

  void parse(List<String> arguments) {
    final argParser = Options.buildArgParser();

    try {
      final argResults = argParser.parse(arguments);
      final options = Options.parseOptions(argResults);

      Logger.root.level = options.logLevel;
      _logger.finest('Parsed arguments: $arguments');

      if (options.help) {
        stdout
          ..writeln('Usage:')
          ..writeln(argParser.usage);
        exit(0);
      }

      if (options.version) {
        stdout
          ..write(Platform.script.pathSegments.last)
          ..write(' ')
          ..writeln(Pubspec.version.canonical);
        exit(0);
      }

      _logger.config('server: ${options.server}');

      state = options;
    } on ArgParserException catch (e) {
      stderr
        ..writeln(e)
        ..writeln()
        ..writeln('Usage:')
        ..writeln(argParser.usage);
      exit(127);
    }
  }
}
