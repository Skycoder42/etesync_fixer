import 'package:etebase/etebase.dart';
import 'package:icalendar/icalendar.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../extensions/icalendar_extensions.dart';
import '../../ical/ical_codec.dart';
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
    final content = await item.getContent();
    final calendar = iCalBinaryCodec.decode(content);

    final todos = calendar.findBlocks('VTODO');
    for (final todo in todos) {
      final alarms = todo.findBlocks('VALARM');
      if (alarms.isNotEmpty) {
        continue;
      }

      final relatedTo = todo.property('RELATED-TO');
      if (relatedTo != null && relatedTo['RELTYPE']?.value == 'PARENT') {
        continue;
      }

      // create the alarm
      const alarm = CrawledBlock(
        blockName: 'VALARM',
        properties: [
          CrawledProperty(
            name: 'TRIGGER',
            value: 'PT0S',
            parameters: [CrawledParameter('RELATED', 'END')],
          ),
          CrawledProperty(
            name: 'ACTION',
            value: 'DISPLAY',
            parameters: [],
          ),
          CrawledProperty(
            name: 'DESCRIPTION',
            value: 'Default etesync-fixer description',
            parameters: [],
          ),
        ],
        nestedBlocks: [],
      );
      todo.nestedBlocks.add(alarm);

      final buffer = StringBuffer();
      _debugDumpBlocks(buffer, [todo]);
      _logger.finest(buffer);
    }

    return SyncResult.unchanged;
  }

  void _debugDumpBlocks(
    StringBuffer buffer,
    Iterable<CrawledBlock> blocks, [
    int indent = 0,
  ]) {
    for (final block in blocks) {
      buffer
        ..writeStartTag(indent, block.blockName)
        ..writeln();

      _debugDumpProps(buffer, block.properties, indent + 1);
      _debugDumpBlocks(buffer, block.nestedBlocks, indent + 1);

      buffer
        ..writeEndTag(indent, block.blockName)
        ..writeln();
    }
  }

  void _debugDumpProps(
    StringBuffer buffer,
    Iterable<CrawledProperty> properties, [
    int indent = 0,
  ]) {
    for (final property in properties) {
      buffer
        ..writeStartTag(
          indent,
          property.name,
          writeAttributes: (buffer) {
            for (final param in property.parameters) {
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
