import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

extension LoggerX on Logger {
  void command(Command command) {
    final commandChain = <String>[];
    Command? currentCommand = command;
    while (currentCommand != null) {
      commandChain.add(currentCommand.name);
      currentCommand = currentCommand.parent;
    }

    config('command=${commandChain.reversed.join(' ')}');
  }
}
