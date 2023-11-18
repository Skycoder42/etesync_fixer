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
}

abstract interface class SyncJob {
  String? get collectionType;

  String? get itemType;

  FutureOr<SyncResult> process(
    EtebaseCollection collection,
    EtebaseItem item,
  );
}
