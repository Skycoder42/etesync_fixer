import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ical/ical_codec.dart';
import '../../ical/ical_component.dart';
import '../sync_job.dart';

part 'fix_task_reminders_job.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
FixTaskRemindersJob fixTaskRemindersJob(FixTaskRemindersJobRef ref) =>
    FixTaskRemindersJob();
// coverage:ignore-end

class FixTaskRemindersJob implements SyncJob {
  final _logger = Logger('$FixTaskRemindersJob');

  @override
  String get collectionType => 'etebase.vtodo';

  @override
  Null get itemType => null;

  @override
  Future<SyncResult> call(
    EtebaseCollection collection,
    EtebaseItem item,
  ) async {
    var result = SyncResult.unchanged;
    final content = await item.getContent();
    final calendar = iCalBinaryCodec.decode(content);

    final todos = calendar.findBlocks('VTODO');
    for (final todo in todos) {
      final alarms = todo.findBlocks('VALARM');
      if (alarms.isNotEmpty) {
        continue;
      }

      final relatedTo = todo.getProperty('RELATED-TO');
      if (relatedTo != null &&
          relatedTo.getParameter('RELTYPE')?.value == 'PARENT') {
        continue;
      }

      // create the alarm
      todo.add(_createDefaultAlarm());
      result = result.merge(SyncResult.modifiedItem);
    }

    if (result != SyncResult.unchanged) {
      await item.setContent(iCalBinaryCodec.encode(calendar));
      _logger.finest(_debugDumpBlocks(calendar));
    }

    return result;
  }

  ICalBlock _createDefaultAlarm() => ICalBlock(
        'VALARM',
        properties: [
          ICalProperty(
            'TRIGGER',
            'PT0S',
            parameters: [ICalParameter('RELATED', 'END')],
          ),
          ICalProperty(
            'ACTION',
            'DISPLAY',
          ),
          ICalProperty(
            'DESCRIPTION',
            'Default etesync-fixer description',
          ),
        ],
      );

  StringBuffer _debugDumpBlocks(
    Iterable<ICalBlock> blocks, [
    StringBuffer? buffer,
    int indent = 0,
  ]) {
    buffer ??= StringBuffer();
    for (final block in blocks) {
      buffer
        ..writeStartTag(indent, block.name)
        ..writeln();

      _debugDumpProps(block.whereType<ICalProperty>(), buffer, indent + 1);
      _debugDumpBlocks(block.whereType<ICalBlock>(), buffer, indent + 1);

      buffer
        ..writeEndTag(indent, block.name)
        ..writeln();
    }
    return buffer;
  }

  void _debugDumpProps(
    Iterable<ICalProperty> properties,
    StringBuffer buffer, [
    int indent = 0,
  ]) {
    for (final property in properties) {
      buffer
        ..writeStartTag(
          indent,
          property.name,
          writeAttributes: (buffer) {
            for (final param in property) {
              buffer
                ..write(' ')
                ..write(param.name)
                ..write('="')
                ..write(param.value)
                ..write('"');
            }
          },
        )
        ..write(property.value)
        ..writeEndTag(0, property.name)
        ..writeln();
    }
  }
}

extension on StringBuffer {
  void writeStartTag(
    int indent,
    String content, {
    void Function(StringBuffer buffer)? writeAttributes,
    bool autoClose = false,
  }) {
    write('  ' * indent);
    write('<');
    write(content);
    if (writeAttributes != null) {
      writeAttributes(this);
    }
    write(autoClose ? '/>' : '>');
  }

  void writeEndTag(
    int indent,
    String content,
  ) {
    write('  ' * indent);
    write('</');
    write(content);
    write('>');
  }
}
