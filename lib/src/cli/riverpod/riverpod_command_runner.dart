import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

abstract class RiverpodCommandRunner<TResult, TGlobalOptions extends Object>
    extends CommandRunner<TResult> {
  final Provider<TGlobalOptions> _globalOptionsProvider;

  final _commandProviders = <Provider<Command<TResult>>>{};

  final ProviderContainer? containerParent;
  final List<Override> containerOverrides;
  final List<ProviderObserver>? containerObservers;
  late final ProviderContainer _container;

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

  bool addCommandProvider<TCommand extends Command<TResult>>(
    Provider<TCommand> provider,
  ) =>
      _commandProviders.add(provider);

  @override
  Future<TResult?> runCommand(ArgResults topLevelResults) {
    _container = ProviderContainer(
      parent: containerParent,
      overrides: [
        ...containerOverrides,
        _globalOptionsProvider.overrideWithValue(
          parseGlobalOptions(topLevelResults),
        ),
      ],
      observers: containerObservers,
    );

    for (final commandProvider in _commandProviders) {
      addCommand(_container.read(commandProvider));
    }

    return super.runCommand(topLevelResults);
  }

  @protected
  void configureGlobalOptions(ArgParser argParser);

  @protected
  TGlobalOptions parseGlobalOptions(ArgResults argResults);

  @override
  @visibleForTesting
  void addCommand(Command<TResult> command) => super.addCommand(command);
}
