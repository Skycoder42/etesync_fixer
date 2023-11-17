import 'package:freezed_annotation/freezed_annotation.dart';

part 'config.freezed.dart';
part 'config.g.dart';

@freezed
class Config with _$Config {
  static const empty = Config();

  const factory Config({
    Uri? server,
    String? encryptedAccountData,
    String? stoken,
    @Default({}) Map<String, String> collectionStokens,
  }) = _Config;

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
}

extension MapX<TKey, TValue> on Map<TKey, TValue> {
  Map<TKey, TValue> updatedWith(TKey key, TValue value) => {
        ...this,
        key: value,
      };

  Map<TKey, TValue> updatedWithout(TKey keyToRemove) => {
        for (final MapEntry(key: key, value: value) in entries)
          if (key != keyToRemove) key: value,
      };
}
