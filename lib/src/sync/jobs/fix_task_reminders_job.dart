import 'dart:convert';
import 'dart:math';

import 'package:etebase/etebase.dart';
import 'package:icalendar/icalendar.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../extensions/icalendar_extensions.dart';
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

    final calObj =
        crawlICalendarLines(_toCalendarLines(contentString).toList());
    final calStr = _fromCalendarLines(calObj.toLines());

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

  Iterable<String> _toCalendarLines(String content) sync* {
    var previousLine = '';
    for (final currentLine in LineSplitter.split(content)) {
      if (currentLine.startsWith(RegExp(r'\s'))) {
        previousLine += currentLine.substring(1);
      } else {
        if (previousLine.isNotEmpty) {
          yield previousLine;
        }

        previousLine = currentLine;
      }
    }

    if (previousLine.isNotEmpty) {
      yield previousLine;
    }
  }

  String _fromCalendarLines(Iterable<String> lines) {
    const crLf = '\r\n';

    final buffer = StringBuffer();
    for (final line in lines) {
      var segment = line;
      while (segment.length > 75) {
        buffer
          ..write(segment.substring(0, 75))
          ..write(crLf)
          ..write(' ');
        segment = segment.substring(75);
      }

      buffer
        ..write(segment)
        ..write(crLf);
    }

    return buffer.toString();
  }
}
