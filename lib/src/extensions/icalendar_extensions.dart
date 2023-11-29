import 'package:icalendar/icalendar.dart';

extension CrawledBlockIterableX on Iterable<CrawledBlock> {
  Iterable<String> toLines() => expand((block) => block.toLines());
}

extension on CrawledBlock {
  Iterable<String> toLines() sync* {
    yield 'BEGIN:$blockName';

    for (final property in properties) {
      yield property.toLine();
    }

    for (final nestedBlock in nestedBlocks) {
      yield* nestedBlock.toLines();
    }

    yield 'END:$blockName';
  }
}

extension on CrawledProperty {
  String toLine() {
    final buffer = StringBuffer(name);

    for (final parameter in parameters) {
      buffer.write(';');
      parameter.writeLineSegment(buffer);
    }

    buffer
      ..write(':')
      ..write(value);

    return buffer.toString();
  }
}

extension on CrawledParameter {
  void writeLineSegment(StringBuffer buffer) {
    buffer
      ..write(name)
      ..write('=')
      ..write(value.iCalEscaped());
  }
}

extension on String {
  static final unsafeCharRegex = RegExp('[,;:]');

  String iCalEscaped() {
    if (contains(unsafeCharRegex)) {
      return '"$this"';
    } else {
      return this;
    }
  }
}
