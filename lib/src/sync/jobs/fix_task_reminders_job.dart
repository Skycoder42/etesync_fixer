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

    final todos = calendar.findBlocks('vtodo');

    return SyncResult.unchanged;
  }

  void _debugDumpBlocks(
    StringBuffer buffer,
    int indent,
    Iterable<CrawledBlock> blocks,
  ) {
    for (final block in blocks) {
      final hasChildren =
          block.properties.isNotEmpty || block.nestedBlocks.isNotEmpty;

      buffer
        ..writeStartTag(indent, block.blockName, autoClose: !hasChildren)
        ..writeln();

      if (!hasChildren) {
        continue;
      }

      _debugDumpProps(buffer, indent + 1, block.properties);
      _debugDumpBlocks(buffer, indent + 1, block.nestedBlocks);

      buffer
        ..writeEndTag(indent, block.blockName)
        ..writeln();
    }
  }

  void _debugDumpProps(
    StringBuffer buffer,
    int indent,
    Iterable<CrawledProperty> properties,
  ) {
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
