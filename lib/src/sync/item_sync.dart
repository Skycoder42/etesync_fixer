import 'package:etebase/etebase.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_sync.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
ItemSync itemSync(ItemSyncRef ref) => ItemSync();
// coverage:ignore-end

class ItemSync {
  final _logger = Logger('$ItemSync');

  Future<void> syncItem(
    EtebaseItemManager itemManager,
    EtebaseItem item,
  ) async {
    _logger.fine(await item.getUid());
  }
}
