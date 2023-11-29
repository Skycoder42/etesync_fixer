import 'package:etebase/etebase.dart';
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

  SyncJobRegistry(this._syncJobs);

  Future<SyncResult> sync(
    EtebaseCollection collection,
    EtebaseItem item,
  ) async {
    final collectionType = await collection.getCollectionType();
    final itemType = (await item.getMeta()).itemType;

    var result = SyncResult.unchanged;
    for (final syncJob in _syncJobs) {
      if (syncJob.collectionType != null &&
          syncJob.collectionType != collectionType) {
        continue;
      }

      if (syncJob.itemType != null && syncJob.itemType != itemType) {
        continue;
      }

      result = result.merge(await syncJob(collection, item));
    }

    return result;
  }
}
