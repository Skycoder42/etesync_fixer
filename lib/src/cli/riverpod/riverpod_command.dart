import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

mixin RiverpodCommand<TResult> on Command<TResult> {
  @protected
  Ref get ref;
}
