import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

mixin RiverpodCommand<TResult> on Command<TResult> {
  @override
  RiverpodCommandRunner<TResult, Object>? get runner =>
      super.runner as RiverpodCommandRunner<TResult, Object>?;

  @protected
  late final ProviderContainer container = runner!._container;

  @override
  void addSubcommand(covariant RiverpodCommand<TResult> command) =>
      super.addSubcommand(command);
}

abstract class RiverpodCommandRunner<TResult, TGlobalOptions extends Object>
    extends CommandRunner<TResult> {
  final ProviderContainer? containerParent;
  final List<Override> containerOverrides;
  final List<ProviderObserver>? containerObservers;

  late final ProviderContainer _container;

  RiverpodCommandRunner(
    super.executableName,
    super.description, {
    this.containerParent,
    this.containerOverrides = const [],
    this.containerObservers,
  }) {
    configureGlobalOptions(argParser);
  }

  @override
  @mustCallSuper
  Future<TResult?> runCommand(ArgResults topLevelResults) async {
    _createProviderContainer(topLevelResults);
    try {
      return await super.runCommand(topLevelResults);
    } finally {
      _container.dispose();
    }
  }

  @protected
  void configureGlobalOptions(ArgParser argParser);

  @protected
  Override parseGlobalOptions(ArgResults argResults);

  void _createProviderContainer(ArgResults topLevelResults) =>
      _container = ProviderContainer(
        parent: containerParent,
        overrides: [
          ...containerOverrides,
          parseGlobalOptions(topLevelResults),
        ],
        observers: containerObservers,
      );
}
