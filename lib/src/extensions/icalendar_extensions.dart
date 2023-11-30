import 'package:icalendar/icalendar.dart';

extension CrawledBlockIterableX on Iterable<CrawledBlock> {
  Iterable<CrawledBlock> findBlocks(String name) sync* {
    for (final nestedBlock in this) {
      yield* nestedBlock.findBlocks(name);
    }
  }
}

extension CrawledBlockX on CrawledBlock {
  Iterable<CrawledBlock> findBlocks(String name) sync* {
    if (blockName.toLowerCase() == name.toLowerCase()) {
      yield this;
    }

    for (final nestedBlock in nestedBlocks) {
      yield* nestedBlock.findBlocks(name);
    }
  }
}
