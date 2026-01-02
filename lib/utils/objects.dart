// file: lib/objects.dart

typedef JsonLike = Map<String, dynamic>;

class Objects {
  Objects._();

  /// 安全获取 Map 值，如果为 null 或类型不匹配返回默认值
  static T? safeGet<T>(Map? map, Object? key, [T? defaultValue]) {
    if (map == null || !map.containsKey(key)) return defaultValue;
    final value = map[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// 安全获取 List 元素，防止越界
  static T? safeElementAt<T>(List<T>? list, int index, [T? defaultValue]) {
    if (list == null || index < 0 || index >= list.length) return defaultValue;
    return list[index];
  }

  /// 通用判空：支持 String / Iterable / Map / null / num / bool / 自定义对象 (尝试 toJson/toMap)
  /// [deep] = true 时会递归检查 Map/Iterable 内部元素是否都为空（常用于判断“所有字段都为空”的场景）
  static bool isEmpty(Object? value, {bool deep = false}) {
    // null 一律为空
    if (value == null) return true;

    // String：trim 后空字符串视为空
    if (value is String) return value.trim().isEmpty;

    // Iterable (List, Set, ...)
    if (value is Iterable) {
      if (!deep) return value.isEmpty;
      // deep: 若任一元素非空则整体非空
      for (final e in value) {
        if (!isEmpty(e, deep: true)) return false;
      }
      return true;
    }

    // Map
    if (value is Map) {
      if (!deep) return value.isEmpty;
      // deep: 若任一 key/value 非空则整体非空
      if (value.isEmpty) return true;
      for (final entry in value.entries) {
        if (!isEmpty(entry.value, deep: true)) return false;
      }
      return true;
    }

    // 基础类型：数字 / 布尔 不视为空
    if (value is num) return false;
    if (value is bool) return false;

    // 尝试调用 toJson 或 toMap（常见 pattern）
    try {
      // 避免直接 dynamic 调用，先反射或检查方法是否存在会更安全，但在 Dart 中 dynamic 是常用妥协
      // 这里保持原有逻辑，但增加 catch 范围
      final dynamic dyn = value;
      try {
        final dynamic json = dyn.toJson();
        return isEmpty(json, deep: deep);
      } catch (_) {
        try {
          final dynamic map = dyn.toMap();
          return isEmpty(map, deep: deep);
        } catch (_) {
          // ignore
        }
      }
    } catch (_) {
      // ignore
    }

    // fallback: 若对象的 toString() 明显为空或 'null'，视作空；否则认为非空
    final s = value.toString();
    if (s == 'null' || s.trim().isEmpty) return true;
    
    return false;
  }

  static bool isNotEmpty(Object? value, {bool deep = false}) =>
      !isEmpty(value, deep: deep);

  /// 判断字符串是否为 null / 空 / 全空白
  static bool isBlank(String? s) => s == null || s.trim().isEmpty;

  static bool isNotBlank(String? s) => !isBlank(s);
}

/// 常用的扩展方法，方便写法：
///   myString.isNullOrEmpty  或  myList.isNullOrEmpty
extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}

extension NullableIterableExtensions<E> on Iterable<E>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension NullableMapExtensions<K, V> on Map<K, V>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
