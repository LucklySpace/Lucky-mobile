import 'package:floor/floor.dart';

import '../../config/app_config.dart';
import 'base_object.dart';
import 'message_receive.dart';

/// 会话表
@Entity(tableName: 'chats', indices: [
  Index(value: ['chatId', 'name'])
])
class Chats extends BaseObject {
  /// 聊天 ID
  @primaryKey
  String chatId;

  String id;

  /// 聊天类型
  int chatType;

  /// 群/会话拥有者
  String ownerId;

  /// 会话目标 ID
  String toId;

  /// 是否静音（0 否，1 是）
  int isMute;

  /// 是否置顶（0 否，1 是）
  int isTop;

  /// 消息序列号，用于去重/排序
  int sequence;

  /// 会话名称（如群名称或对话人昵称）
  String name;

  /// 会话头像 URL
  String avatar;

  /// 未读消息数
  int unread;

  /// 最后一条消息内容
  String? message;

  /// 最后一条消息时间戳（毫秒）
  int messageTime;

  /// 消息草稿
  String? draft;

  Chats({
    required this.id,
    required this.chatId,
    required this.chatType,
    required this.ownerId,
    required this.toId,
    required this.isMute,
    required this.isTop,
    required this.sequence,
    required this.name,
    required this.avatar,
    required this.unread,
    this.message,
    required this.messageTime,
    this.draft,
  });

  String get fullAvatar => AppConfig.getFullUrl(avatar);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'chatType': chatType,
      'ownerId': ownerId,
      'toId': toId,
      'isMute': isMute,
      'isTop': isTop,
      'sequence': sequence,
      'name': name,
      'avatar': avatar,
      'unread': unread,
      'message': message,
      'messageTime': messageTime,
      'draft': draft,
    };
  }

  factory Chats.fromJson(Map<String, dynamic> json) {
    return Chats(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      chatType: _parseIntSafely(json['chatType']),
      ownerId: json['ownerId']?.toString() ?? '',
      toId: json['toId']?.toString() ?? '',
      isMute: _parseIntSafely(json['isMute']),
      isTop: _parseIntSafely(json['isTop']),
      sequence: json['sequence'] != null ? json['sequence'] as int : 0,
      name: json['name']?.toString() ?? '',
      avatar: json['avatar'].toString(),
      unread: _parseIntSafely(json['unread']),
      message: json['message']?.toString(),
      messageTime: json['messageTime'] != null ? json['messageTime'] as int : 0,
      draft: json['draft']?.toString(),
    );
  }

  // 添加安全的整数解析方法
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String toChatMessage(IMessage dto) {
    String message = '';
    if (dto.messageBody is TextMessageBody) {
      message = (dto.messageBody as TextMessageBody).text ?? '';
    } else if (dto.messageBody is ImageMessageBody) {
      message = '[图片]';
    } else if (dto.messageBody is VideoMessageBody) {
      message = '[视频]';
    } else if (dto.messageBody is SystemMessageBody) {
      message = '[系统消息]';
    }
    return message;
  }
}
