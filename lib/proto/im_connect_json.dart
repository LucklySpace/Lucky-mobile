import 'dart:convert';

// 根据你的项目实际包名调整下面两个导入路径：
import 'package:fixnum/fixnum.dart' show Int64;
import 'package:flutter/foundation.dart'; // for debugPrint

import 'google/protobuf/any.pb.dart';
import 'google/protobuf/struct.pb.dart';
import 'im_connect.pb.dart';

/// 优化后的序列化扩展
extension IMConnectMessageJson on IMConnectMessage {
  /// 将 IMConnectMessage 实例转换为 JSON Map。
  /// - [includeEmpty] 若为 true 会把空字段也输出（便于调试）。
  Map<String, dynamic> toJson({bool includeEmpty = false}) {
    final Map<String, dynamic> json = {};

    void writeIf(String key, dynamic value) {
      if (value == null) return;
      if (!includeEmpty) {
        if (value is String && value.isEmpty) return;
        if (value is Iterable && value.isEmpty) return;
        if (value is Map && value.isEmpty) return;
      }
      json[key] = value;
    }

    // 基本字段（使用 hasX() 保证只序列化存在的字段）
    if (hasCode()) writeIf('code', code);
    if (hasToken()) writeIf('token', token);
    if (hasMessage()) writeIf('message', message);
    if (hasRequestId()) writeIf('requestId', requestId);
    if (hasClientIp()) writeIf('clientIp', clientIp);
    if (hasUserAgent()) writeIf('userAgent', userAgent);
    if (hasDeviceName()) writeIf('deviceName', deviceName);
    if (hasDeviceType()) writeIf('deviceType', deviceType);

    // timestamp (Int64 等) 特别处理为字符串
    if (hasTimestamp()) {
      writeIf('timestamp', _int64ToString(timestamp));
    }

    // metadata：确保输出为 Map<String, dynamic>
    if (metadata != null && metadata.isNotEmpty) {
      writeIf('metadata', _safeMap(metadata));
    }

    // data: google.protobuf.Any 的稳健处理
    if (hasData()) {
      writeIf('data', _anyToJson(data));
    }

    return json;
  }
}

/// 将 Int64 / int / BigInt 等统一转换为字符串（保护精度）
/// - 若传入为 null 返回 null
String? _int64ToString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Int64) return value.toString();
  if (value is int) return value.toString();
  if (value is BigInt) return value.toString();
  try {
    return value.toString();
  } catch (_) {
    return null;
  }
}

/// 把任意 Map-like 转为 Map<String, dynamic>（浅拷贝），防止类型问题
Map<String, dynamic> _safeMap(dynamic maybeMap) {
  if (maybeMap == null) return <String, dynamic>{};
  if (maybeMap is Map) {
    return Map<String, dynamic>.from(maybeMap);
  }
  return <String, dynamic>{};
}

/// 把 google.protobuf.Any 转为 JSON 可序列化的 Map
Map<String, dynamic> _anyToJson(Any any) {
  // 首选使用 toProto3Json（若生成的 Any 提供该方法）
  try {
    final dynamic proto3 = any.toProto3Json();
    // toProto3Json 可能返回 Map / List / primitive
    if (proto3 is Map<String, dynamic>) return proto3;
    return {'@type': any.typeUrl, 'value': proto3};
  } catch (e) {
    debugPrint('Any.toProto3Json failed: $e — try Struct fallback');
  }

  // 尝试解析 google.protobuf.Struct（常见于后端返回的 JSON 对象）
  try {
    if (any.typeUrl.endsWith('google.protobuf.Struct') ||
        any.typeUrl.endsWith('/Struct')) {
      final Struct s = Struct.fromBuffer(any.value);
      // Struct 提供 toProto3Json() 或者 fields 转换
      try {
        final dynamic structJson = s.toProto3Json();
        if (structJson is Map<String, dynamic>) return structJson;
      } catch (_) {
        // 退到手动转换 fields
        final Map<String, dynamic> converted = {};
        s.fields.forEach((k, v) {
          // protobuf Value -> dynamic，使用 toProto3Json 如果可用
          try {
            converted[k] = v.toProto3Json();
          } catch (_) {
            converted[k] = v.toString();
          }
        });
        return converted;
      }
    }
  } catch (e) {
    debugPrint('Struct parsing failed: $e');
  }

  // 最后兜底：返回 typeUrl 与 base64 编码的原始 bytes（能保留信息）
  try {
    return {
      '@type': any.typeUrl,
      'value': base64Encode(any.value),
    };
  } catch (e) {
    debugPrint('Any fallback base64Encode failed: $e');
    return {'@type': any.typeUrl};
  }
}
