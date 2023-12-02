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
    final uid = await item.getUid();
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
      _logger.info('Adding default alarm to ${todo.name} $uid');
      todo.add(_createDefaultAlarm());
      result = result.merge(SyncResult.modifiedItem);
    }

    if (result != SyncResult.unchanged) {
      await item.setContent(iCalBinaryCodec.encode(calendar));
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
}
