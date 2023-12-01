import 'package:collection/collection.dart';
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
    if (blockName.toUpperCase() == name.toUpperCase()) {
      yield this;
    }

    for (final nestedBlock in nestedBlocks) {
      yield* nestedBlock.findBlocks(name);
    }
  }

  CrawledProperty? property(String propertyName) =>
      properties.singleWhereOrNull(
        (p) => p.name.toUpperCase() == propertyName.toUpperCase(),
      );
}

extension CrawledPropertyX on CrawledProperty {
  CrawledParameter? operator [](String paramName) =>
      parameters.singleWhereOrNull(
        (p) => p.name.toUpperCase() == paramName.toUpperCase(),
      );
}
