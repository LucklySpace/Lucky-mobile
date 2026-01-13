import 'package:floor/floor.dart';

/// 群聊消息表
@Entity(tableName: 'group_message')
class GroupMessage {
  /// 消息 ID（主键）
  @primaryKey
  String messageId;

  /// 发送者用户 ID
  String fromId;

  /// 原始消息所属者 ID（比如群主/机器人）
  String ownerId;

  /// 群组 ID
  String groupId;

  /// 消息内容体（JSON 或纯文本）
  String messageBody;

  /// 内容类型（例如 "text"、"image"）
  int messageContentType;

  /// 消息发送时间戳（毫秒）
  int messageTime;

  /// 消息类型（业务侧分类，如 "chat"、"notification_service.dart"）
  int messageType;

  /// 阅读状态（0 未读，1 已读）
  int readStatus;

  /// 序列号，用于消息排序或去重
  int sequence;

  /// 扩展字段，可存放附加 JSON 信息
  String? extra;

  GroupMessage({
    required this.messageId,
    required this.fromId,
    required this.ownerId,
    required this.groupId,
    required this.messageBody,
    required this.messageContentType,
    required this.messageTime,
    required this.messageType, // MessageType.GROUP_MESSAGE.code
    required this.readStatus,
    required this.sequence,
    this.extra,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'fromId': fromId,
      'ownerId': ownerId,
      'groupId': groupId,
      'messageBody': messageBody,
      'messageContentType': messageContentType,
      'messageTime': messageTime,
      'messageType': messageType,
      'readStatus': readStatus,
      'sequence': sequence,
      'extra': extra,
    };
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      messageId: json['messageId'] as String,
      fromId: json['fromId'] as String,
      ownerId: json['ownerId'] as String,
      groupId: json['groupId'] as String,
      messageBody: json['messageBody'] as String,
      messageContentType: json['messageContentType'] as int,
      messageTime: json['messageTime'] as int,
      messageType: json['messageType'] as int,
      // MessageType.GROUP_MESSAGE.code
      readStatus: json['readStatus'] as int,
      sequence: json['sequence'] as int,
      extra: json['extra'] as String?,
    );
  }
}
