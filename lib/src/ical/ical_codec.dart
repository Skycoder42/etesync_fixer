import 'dart:convert';

import 'package:icalendar/icalendar.dart';

const iCalCodec = ICalCodec();

final iCalBinaryCodec = iCalCodec.fuse(utf8);

final class ICalCodec with Codec<List<CrawledBlock>, String> {
  const ICalCodec();

  @override
  ICalDecoder get decoder => const ICalDecoder();

  @override
  ICalEncoder get encoder => const ICalEncoder();
}

final class ICalDecoder with Converter<String, List<CrawledBlock>> {
  const ICalDecoder();

  @override
  List<CrawledBlock> convert(String input) =>
      crawlICalendarLines(_toCalendarLines(input).toList());

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
}

final class ICalEncoder with Converter<List<CrawledBlock>, String> {
  static const _crLf = '\r\n';
  static final _unsafeCharRegex = RegExp('[,;:]');

  const ICalEncoder();

  @override
  String convert(List<CrawledBlock> input) {
    final buffer = StringBuffer();
    for (final line in input.expand(_blockToLines)) {
      var segment = line;
      while (segment.length > 75) {
        buffer
          ..write(segment.substring(0, 75))
          ..write(_crLf)
          ..write(' ');
        segment = segment.substring(75);
      }

      buffer
        ..write(segment)
        ..write(_crLf);
    }

    return buffer.toString();
  }

  Iterable<String> _blockToLines(CrawledBlock block) sync* {
    yield 'BEGIN:${block.blockName}';

    for (final property in block.properties) {
      yield _propertyToLine(property);
    }

    for (final nestedBlock in block.nestedBlocks) {
      yield* _blockToLines(nestedBlock);
    }

    yield 'END:${block.blockName}';
  }

  String _propertyToLine(CrawledProperty property) {
    final buffer = StringBuffer(property.name);

    for (final parameter in property.parameters) {
      buffer.write(';');
      _writeLineSegment(buffer, parameter);
    }

    buffer
      ..write(':')
      ..write(property.value);

    return buffer.toString();
  }

  void _writeLineSegment(StringBuffer buffer, CrawledParameter parameter) {
    buffer
      ..write(parameter.name)
      ..write('=')
      ..write(_iCalEscape(parameter.value));
  }

  String _iCalEscape(String value) =>
      value.contains(_unsafeCharRegex) ? '"$value"' : value;
}
