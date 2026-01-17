/// 通用搜索结果模型
class SearchResult {
  /// 用户ID
  final String id;

  /// 显示名称
  final String name;

  /// 头像URL
  final String? avatar;

  /// 类型 (user, group, message)
  final String type;

  /// 匹配内容
  final String? highlight;

  /// 扩展信息
  final Map<String, dynamic>? extra;

  SearchResult({
    required this.id,
    required this.name,
    this.avatar,
    required this.type,
    this.highlight,
    this.extra,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      type: json['type']?.toString() ?? 'user',
      highlight: json['highlight']?.toString(),
      extra: json['extra'] is Map
          ? Map<String, dynamic>.from(json['extra'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'type': type,
      'highlight': highlight,
      'extra': extra,
    };
  }

  /// 是否为用户类型
  bool get isUser => type == 'user';

  /// 是否为群组类型
  bool get isGroup => type == 'group';

  /// 是否为消息类型
  bool get isMessage => type == 'message';

  @override
  String toString() => 'SearchResult(id: $id, name: $name, type: $type)';
}

/// 搜索类型枚举
enum SearchType {
  user('user', '用户'),
  group('group', '群组'),
  message('message', '消息'),
  all('all', '全部');

  final String code;
  final String description;

  const SearchType(this.code, this.description);

  static SearchType fromCode(String code) {
    return SearchType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => SearchType.user,
    );
  }
}
