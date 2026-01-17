import '../../config/app_config.dart';

/// 消息搜索结果模型
class SearchMessageResult {
  /// 用户/群组ID
  final String id;

  /// 用户/群组名称
  final String name;

  /// 头像URL
  final String? avatar;

  /// 类型 (user, group)
  final String type;

  /// 相关消息数量
  final int messageCount;

  /// 消息列表
  final List<dynamic> messages;

  SearchMessageResult({
    required this.id,
    required this.name,
    this.avatar,
    required this.type,
    required this.messageCount,
    required this.messages,
  });

  factory SearchMessageResult.fromJson(Map<String, dynamic> json) {
    return SearchMessageResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      type: json['type']?.toString() ?? 'user',
      messageCount: json['messageCount'] is int
          ? json['messageCount']
          : int.tryParse(json['messageCount']?.toString() ?? '0') ?? 0,
      messages: json['messages'] as List<dynamic>? ?? [],
    );
  }

  /// 获取完整头像URL
  String get fullAvatar => AppConfig.getFullUrl(avatar);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'type': type,
      'messageCount': messageCount,
      'messages': messages,
    };
  }

  /// 是否为用户类型
  bool get isUser => type == 'user';

  /// 是否为群组类型
  bool get isGroup => type == 'group';

  @override
  String toString() =>
      'SearchMessageResult(id: $id, name: $name, count: $messageCount)';
}
