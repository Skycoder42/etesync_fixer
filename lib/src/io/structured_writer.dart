import 'dart:async';

import 'package:meta/meta.dart';

typedef ConverterCb<TReturn, TValue> = TReturn Function(TValue value);

abstract base class StructuredWriter<TConvert extends Object> {
  final _converters = <Type, Function>{};

  FutureOr<void> addRow(Map<String, dynamic> entry);

  FutureOr<void> writeTo(StringSink sink);

  @protected
  void addConverter<T>(ConverterCb<TConvert, T> convert) =>
      // ignore: discarded_futures
      _converters[T] = convert;

  @protected
  TConvert? maybeConvert(dynamic value) {
    for (final converter in _converters.values) {
      try {
        // ignore: avoid_dynamic_calls
        return converter.call(value) as TConvert?;
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        // ignore
      }
    }

    return null;
  }
}
