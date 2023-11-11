import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

abstract class RiverpodCommand<TResult> extends Command<TResult> {
  @protected
  final Ref ref;

  RiverpodCommand(this.ref);
}
