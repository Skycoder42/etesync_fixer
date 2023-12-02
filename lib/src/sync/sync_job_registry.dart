import 'package:collection/collection.dart';
import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'jobs/fix_task_reminders_job.dart';
import 'sync_job.dart';

part 'sync_job_registry.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
SyncJobRegistry syncJobRegistry(SyncJobRegistryRef ref) => SyncJobRegistry({
      ref.watch(fixTaskRemindersJobProvider),
    });
// coverage:ignore-end

class SyncJobRegistry {
  final Set<SyncJob> _syncJobs;

  final _logger = Logger('$SyncJobRegistry');

  SyncJobRegistry(this._syncJobs);

  Set<String> get allCollectionTypes =>
      _syncJobs.map((j) => j.collectionType).whereNotNull().toSet();

  Future<SyncResult> sync(
    EtebaseCollection collection,
    EtebaseItem item,
  ) async {
    final uid = await item.getUid();
    final collectionType = await collection.getCollectionType();
    final itemType = (await item.getMeta()).itemType;
    if (itemType != null) {
      _logger.finest(
        'Detected custom item type for $uid as: $itemType',
      );
    }

    var result = SyncResult.unchanged;
    for (final syncJob in _syncJobs) {
      if (syncJob.collectionType != null &&
          syncJob.collectionType != collectionType) {
        _logger.finest(
          'Skipping sync job ${syncJob.runtimeType} for item $uid '
          'because collection type does not match',
        );
        continue;
      }

      if (syncJob.itemType != null && syncJob.itemType != itemType) {
        _logger.finest(
          'Skipping sync job ${syncJob.runtimeType} for item $uid '
          'because item type does not match',
        );
        continue;
      }

      _logger.finer('Applying sync job ${syncJob.runtimeType} to item $uid');
      result = result.merge(await syncJob(collection, item));
    }

    return result;
  }
}
