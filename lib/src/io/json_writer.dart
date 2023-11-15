import 'dart:convert';
import 'dart:typed_data';

import 'structured_writer.dart';

final class JsonWriter extends StructuredWriter<String> {
  final _jsonArray = <Map<String, dynamic>>[];

  JsonWriter() {
    addConverter<Uint8List>((value) => base64.encode(value));
  }

  @override
  void addRow(Map<String, dynamic> entry) => _jsonArray.add(
        entry.map((key, value) => MapEntry(key, maybeConvert(value) ?? value)),
      );

  @override
  void writeTo(StringSink sink) {
    const jsonEncoder = JsonEncoder.withIndent('  ');
    sink.write(jsonEncoder.convert(_jsonArray));
  }
}
