import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

import 'riverpod_command.dart';

abstract class RiverpodCommandRunner<TResult, TGlobalOptions extends Object>
    extends CommandRunner<TResult> {
  final Provider<TGlobalOptions> _globalOptionsProvider;

  final _commandProviders = <Provider<RiverpodCommand<TResult>>>{};

  final ProviderContainer? containerParent;
  final List<Override> containerOverrides;
  final List<ProviderObserver>? containerObservers;

  RiverpodCommandRunner(
    this._globalOptionsProvider,
    super.executableName,
    super.description, {
    this.containerParent,
    this.containerOverrides = const [],
    this.containerObservers,
  }) {
    configureGlobalOptions(argParser);
  }

  bool addCommandProvider<TCommand extends RiverpodCommand<TResult>>(
    Provider<TCommand> provider,
  ) =>
      _commandProviders.add(provider);

  @override
  @nonVirtual
  Future<TResult?> run(Iterable<String> args) async {
    final container = _createProviderContainer();
    try {
      for (final commandProvider in _commandProviders) {
        addCommand(container.read(commandProvider));
      }

      final topLevelResults = parse(args);

      container.updateOverrides([
        ...containerOverrides,
        _globalOptionsProvider.overrideWithValue(
          parseGlobalOptions(topLevelResults),
        ),
      ]);

      return await runCommand(topLevelResults);
    } finally {
      container.dispose();
    }
  }

  @protected
  void configureGlobalOptions(ArgParser argParser);

  @protected
  TGlobalOptions parseGlobalOptions(ArgResults argResults);

  @override
  @nonVirtual
  @visibleForTesting
  void addCommand(Command<TResult> command) => super.addCommand(command);

  ProviderContainer _createProviderContainer() => ProviderContainer(
        parent: containerParent,
        overrides: [
          ...containerOverrides,
          _globalOptionsProvider.overrideWith(
            (ref) => throw StateError(
              'You cannot access the global options before run is called!',
            ),
          ),
        ],
        observers: containerObservers,
      );
}
