import 'dart:convert';
import 'dart:math';

import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    _logger
      ..info(await item.getUid())
      ..info(await item.getMeta())
      ..info(await item.getEtag());

    final content = await item.getContent();
    final contentString = LineSplitter.split(utf8.decode(content))
        .where((element) => element.trim().isNotEmpty)
        .followedBy(['']).join('\r\n');

    final calObj = iCalCodec.decode(contentString);
    final calStr = iCalCodec.encode(calObj);

    if (calStr != contentString) {
      var firstDiffIndex = -1;
      for (var i = 0; i < min(contentString.length, calStr.length); ++i) {
        if (contentString[i] != calStr[i]) {
          if (contentString.substring(i).startsWith('X-MOZ-LASTACK:') ||
              calStr.substring(i).startsWith('X-MOZ-LASTACK:')) {
            return SyncResult.unchanged;
          }

          firstDiffIndex = i;
          break;
        }
      }

      print(contentString);
      print(calStr);

      throw Exception('''
DIFF DETECTED AT CHAR POS $firstDiffIndex
DELTA:
  contentString: ${contentString.length}
    ...${contentString.substring(max(0, firstDiffIndex - 10), min(contentString.length, firstDiffIndex + 10))}...
  calStr: ${calStr.length}
    ...${calStr.substring(max(0, firstDiffIndex - 10), min(calStr.length, firstDiffIndex + 10))}...
''');
    }

    return SyncResult.unchanged;
  }
}
