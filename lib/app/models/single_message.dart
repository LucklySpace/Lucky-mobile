import 'package:floor/floor.dart';

/// single_message
@Entity(tableName: 'single_message')
class SingleMessage {
  /// 消息 ID（主键）
  @primaryKey
  String messageId;

  /// 发送者用户 ID
  String fromId;

  /// 接收者用户 ID
  String toId;

  /// 消息所有者 ID（一般与 fromId 相同）
  String ownerId;

  /// 消息正文内容
  String messageBody;

  /// 消息内容类型（如 text/image/video）
  int messageContentType;

  /// 消息发送时间戳（毫秒）
  int messageTime;

  /// 应用层消息类型（如 chat/notification_service.dart）
  int messageType;

  /// 阅读状态：0 未读，1 已读
  int readStatus;

  /// 消息序列号，用于排序、去重
  int sequence;

  /// 扩展字段，存放额外 JSON 信息
  String? extra;

  SingleMessage({
    required this.messageId,
    required this.fromId,
    required this.toId,
    required this.ownerId,
    required this.messageBody,
    required this.messageContentType,
    required this.messageTime,
    required this.messageType, // MessageType.SINGLE_MESSAGE.code
    required this.readStatus,
    required this.sequence,
    this.extra,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'fromId': fromId,
      'toId': toId,
      'ownerId': ownerId,
      'messageBody': messageBody,
      'messageContentType': messageContentType,
      'messageTime': messageTime,
      'messageType': messageType,
      'readStatus': readStatus,
      'sequence': sequence,
      'extra': extra,
    };
  }

  factory SingleMessage.fromJson(Map<String, dynamic> json) {
    return SingleMessage(
      messageId: json['messageId'] as String,
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
      ownerId: json['ownerId'] as String,
      messageBody: json['messageBody'] as String,
      messageContentType: json['messageContentType'] as int,
      messageTime: json['messageTime'] as int,
      messageType: json['messageType'] as int? ?? 1,
      // MessageType.SINGLE_MESSAGE.code
      readStatus: json['readStatus'] as int,
      sequence: json['sequence'] as int,
      extra: json['extra'] as String?,
    );
  }
}
