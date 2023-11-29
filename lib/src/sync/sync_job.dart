import 'dart:async';

import 'package:etebase/etebase.dart';

enum SyncResult {
  unchanged(false, false),
  modifiedItem(false, true),
  modifiedCollection(true, false),
  modifiedAll(true, true);

  final bool collectionModified;
  final bool itemModified;

  const SyncResult(this.collectionModified, this.itemModified);

  SyncResult merge(SyncResult other) {
    final collectionModified =
        this.collectionModified || other.collectionModified;
    final itemModified = this.itemModified || other.itemModified;

    return switch ((collectionModified, itemModified)) {
      (false, false) => SyncResult.unchanged,
      (false, true) => SyncResult.modifiedItem,
      (true, false) => SyncResult.modifiedCollection,
      (true, true) => SyncResult.modifiedAll,
    };
  }
}

abstract interface class SyncJob {
  String? get collectionType;

  String? get itemType;

  FutureOr<SyncResult> call(
    EtebaseCollection collection,
    EtebaseItem item,
  );
}
