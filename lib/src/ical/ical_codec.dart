import 'dart:convert';
import 'dart:typed_data';

import 'package:icalendar/icalendar.dart'
    show CrawledBlock, CrawledParameter, CrawledProperty, crawlICalendarLines;

import 'ical_component.dart';

const iCalCodec = ICalCodec();

final iCalBinaryCodec = iCalCodec.fuse(utf8).fuse(const _TypedByteArrayCodec());

final class ICalCodec with Codec<ICalendar, String> {
  const ICalCodec();

  @override
  ICalDecoder get decoder => const ICalDecoder();

  @override
  ICalEncoder get encoder => const ICalEncoder();
}

final class ICalDecoder with Converter<String, ICalendar> {
  const ICalDecoder();

  @override
  ICalendar convert(String input) {
    final calendarLines = _toCalendarLines(input).toList();
    final crawledBlocks = crawlICalendarLines(calendarLines);
    return _toCalendar(crawledBlocks);
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

  ICalendar _toCalendar(Iterable<CrawledBlock> blocks) => ICalendar(
        blocks.map(_toBlock),
      );

  ICalBlock _toBlock(CrawledBlock block) => ICalBlock(
        block.blockName,
        properties: block.properties.map(_toProperty),
        blocks: block.nestedBlocks.map(_toBlock),
      );

  ICalProperty _toProperty(CrawledProperty property) => ICalProperty(
        property.name,
        property.value,
        parameters: property.parameters.map(_toParameter),
      );

  ICalParameter _toParameter(CrawledParameter parameter) =>
      ICalParameter(parameter.name, parameter.value);
}

final class ICalEncoder with Converter<ICalendar, String> {
  static const _crLf = '\r\n';
  static final _unsafeCharRegex = RegExp('[,;:]');

  const ICalEncoder();

  @override
  String convert(ICalendar input) {
    final buffer = StringBuffer();
    for (final line in _calendarToLines(input)) {
      var maxLineLength = 75;
      var segment = line;
      while (segment.length > maxLineLength) {
        buffer
          ..write(segment.substring(0, maxLineLength))
          ..write(_crLf)
          ..write(' ');
        segment = segment.substring(maxLineLength);
        maxLineLength = 74;
      }

      buffer
        ..write(segment)
        ..write(_crLf);
    }

    return buffer.toString();
  }

  Iterable<String> _calendarToLines(ICalendar calendar) =>
      calendar.expand(_blockToLines);

  Iterable<String> _blockToLines(ICalBlock block) sync* {
    yield 'BEGIN:${block.name}';

    for (final component in block) {
      switch (component) {
        case final ICalProperty property:
          yield _propertyToLine(property);
        case final ICalBlock block:
          yield* _blockToLines(block);
      }
    }

    yield 'END:${block.name}';
  }

  String _propertyToLine(ICalProperty property) {
    final buffer = StringBuffer(property.name);

    for (final parameter in property) {
      buffer.write(';');
      _writeLineSegment(buffer, parameter);
    }

    buffer
      ..write(':')
      ..write(property.value);

    return buffer.toString();
  }

  void _writeLineSegment(StringBuffer buffer, ICalParameter parameter) {
    buffer
      ..write(parameter.name)
      ..write('=')
      ..write(_iCalEscape(parameter.value));
  }

  String _iCalEscape(String value) =>
      value.contains(_unsafeCharRegex) ? '"$value"' : value;
}

final class _TypedByteArrayCodec extends Codec<List<int>, Uint8List> {
  const _TypedByteArrayCodec();

  @override
  Converter<Uint8List, List<int>> get decoder => const _TypedByteArrayDecoder();

  @override
  Converter<List<int>, Uint8List> get encoder => const _TypedByteArrayEncoder();
}

final class _TypedByteArrayEncoder with Converter<List<int>, Uint8List> {
  const _TypedByteArrayEncoder();

  @override
  Uint8List convert(List<int> input) =>
      input is Uint8List ? input : Uint8List.fromList(input);
}

final class _TypedByteArrayDecoder with Converter<Uint8List, List<int>> {
  const _TypedByteArrayDecoder();

  @override
  List<int> convert(Uint8List input) => input;
}
