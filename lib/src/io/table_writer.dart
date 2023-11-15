import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:etebase/etebase.dart';

import 'structured_writer.dart';

final class TableWriter extends StructuredWriter<FutureOr<String>> {
  final _header = <String>[];
  final _table = <List<String>>[];

  TableWriter(EtebaseClient client) {
    addConverter<Uint8List>(
      (value) async => EtebaseUtils.prettyFingerprint(client, value),
    );
  }

  void addHeader(String key) => _header.add(key);

  void addHeaders(Iterable<String> keys) => _header.addAll(keys);

  @override
  Future<void> addRow(Map<String, dynamic> entry) async {
    final rows = <List<String>>[];
    for (final MapEntry(key: key, value: value) in entry.entries) {
      final column = _header.indexOf(key);
      if (column == -1) {
        throw StateError('No header for $key - user addHeader to declare it.');
      }

      final stringValue = await maybeConvert(value) ?? value.toString();
      final cellLines = const LineSplitter().convert(stringValue);
      for (final (index, cellLine) in cellLines.indexed) {
        _getRow(rows, index)[column] = cellLine;
      }
    }
    _table.addAll(rows);
  }

  @override
  void writeTo(StringSink sink) {
    final columnWidths = <int>[];
    for (final (column, header) in _header.indexed) {
      final columnWidth = _table
          .map((row) => row[column])
          .followedBy([header])
          .map((cell) => cell.length)
          .reduce(max);
      columnWidths.add(columnWidth);
    }

    for (final row in [_header].followedBy(_table)) {
      var writeSpace = false;
      for (final (column, cell) in row.indexed) {
        if (writeSpace) {
          sink.write('  ');
        } else {
          writeSpace = true;
        }

        sink
          ..write(cell)
          ..write(' ' * (columnWidths[column] - cell.length));
      }
      sink.writeln();
    }
  }

  List<String> _getRow(List<List<String>> rows, int offset) {
    while (rows.length <= offset) {
      rows.add(List.filled(_header.length, ''));
    }
    return rows[offset];
  }
}
