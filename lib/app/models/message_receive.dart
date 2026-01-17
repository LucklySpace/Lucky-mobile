import 'dart:convert';

import '../../constants/app_message.dart';
import 'group_message.dart';
import 'single_message.dart';

/// 新版 Message DTO，参考后端 IMessage 定义并扩展
class MessageVideoCallDto {
  final String fromId; // 发送者ID
  final String toId; // 接收者ID
  final int? type; // 消息类型

  MessageVideoCallDto({required this.fromId, required this.toId, this.type});

  factory MessageVideoCallDto.fromJson(Map<String, dynamic> json) {
    return MessageVideoCallDto(
      fromId: json['fromId']?.toString() ?? '',
      toId: json['toId']?.toString() ?? '',
      type: _parseIntSafely(json['type']),
    );
  }

  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// 消息接收数据传输对象
/// 对应后端 IMessage
class IMessage {
  /// 发送者ID
  final String fromId;

  /// 消息临时ID（客户端生成）
  final String? messageTempId;

  /// 消息唯一标识（服务端生成，可为空）
  final String messageId;

  /// 消息内容类型（用于决定 messageBody 的具体类型）
  final int messageContentType;

  /// 消息体，根据 messageContentType 解析
  final MessageBody? messageBody;

  /// 消息时间戳（毫秒）
  final int messageTime;

  /// 消息读取状态
  final int readStatus;

  /// 消息序号（用于排序）
  final int sequence;

  /// 额外信息（Map）
  final Map<String, dynamic>? extra;

  /// 引用的消息信息（reply）
  final ReplyMessageInfo? replyMessage;

  /// 被 @ 的用户 ID 列表
  final List<String>? mentionedUserIds;

  /// 是否 @ 所有人
  final bool? mentionAll;

  /// 单聊接收者ID（仅在单聊时使用）
  final String? toId;

  /// 群组ID（仅在群聊时使用）
  final String? groupId;

  /// 消息类型（单聊/群聊/系统等）
  final int messageType;

  const IMessage({
    required this.fromId,
    this.messageTempId,
    required this.messageId,
    required this.messageContentType,
    this.messageBody,
    required this.messageTime,
    required this.readStatus,
    required this.sequence,
    this.replyMessage,
    this.mentionedUserIds,
    this.mentionAll,
    this.toId,
    this.groupId,
    required this.messageType,
    this.extra,
  });

  /// 从 JSON 映射创建 MessageReceiveDto
  factory IMessage.fromJson(Map<String, dynamic> json) {
    final int contentType = _parseIntSafely(json['messageContentType']);
    final int mType = _parseIntSafely(json['messageType']);

    return IMessage(
      fromId: json['fromId']?.toString() ?? '',
      messageTempId: json['messageTempId']?.toString(),
      messageId: json['messageId']?.toString() ?? '',
      messageContentType: contentType,
      messageBody: _parseMessageBody(
        json['messageBody'] is String
            ? _tryDecode(json['messageBody'])
            : (json['messageBody'] as Map<String, dynamic>?),
        contentType,
      ),
      messageTime: _parseIntSafely(json['messageTime']),
      readStatus: _parseIntSafely(json['readStatus'],
          defaultValue: IMessageReadStatus.UNREAD.code),
      sequence: _parseIntSafely(json['sequence']),
      extra: json['extra'] is Map
          ? Map<String, dynamic>.from(json['extra'])
          : (json['extra'] != null ? _tryDecode(json['extra']) : null),
      replyMessage: json['replyMessage'] != null
          ? ReplyMessageInfo.fromJson(
              Map<String, dynamic>.from(json['replyMessage']))
          : null,
      mentionedUserIds: json['mentionedUserIds'] != null
          ? List<String>.from(json['mentionedUserIds'])
          : null,
      mentionAll: json['mentionAll'] is bool
          ? json['mentionAll']
          : json['mentionAll']?.toString().toLowerCase() == 'true',
      toId: mType == MessageType.singleMessage.code
          ? json['toId']?.toString()
          : null,
      groupId: mType == MessageType.groupMessage.code
          ? json['groupId']?.toString()
          : null,
      messageType: mType,
    );
  }

  /// 将对象转换为 JSON 映射
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fromId': fromId,
      'messageTempId': messageTempId,
      'messageId': messageId,
      'messageContentType': messageContentType,
      'messageBody': messageBody?.toJson(),
      'messageTime': messageTime,
      'readStatus': readStatus,
      'sequence': sequence,
      'extra': extra,
      'replyMessage': replyMessage?.toJson(),
      'mentionedUserIds': mentionedUserIds,
      'mentionAll': mentionAll,
      'messageType': messageType,
    };

    if (messageType == MessageType.singleMessage.code) {
      data['toId'] = toId;
    } else if (messageType == MessageType.groupMessage.code) {
      data['groupId'] = groupId;
    }

    return data;
  }

  /// 辅助方法：安全解析整数
  static int _parseIntSafely(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 根据 messageContentType 解析 messageBody
  static MessageBody? _parseMessageBody(Map<String, dynamic>? json, int? type) {
    if (json == null || type == null) return null;

    final contentType = MessageContentType.fromCode(type);

    switch (contentType) {
      case MessageContentType.tip:
        return SystemMessageBody.fromJson(json);
      case MessageContentType.text:
      case MessageContentType.markdown:
      case MessageContentType.richText:
        return TextMessageBody.fromJson(json);
      case MessageContentType.image:
      case MessageContentType.gif:
      case MessageContentType.sticker:
        return ImageMessageBody.fromJson(json);
      case MessageContentType.video:
        return VideoMessageBody.fromJson(json);
      case MessageContentType.audio:
        return AudioMessageBody.fromJson(json);
      case MessageContentType.file:
      case MessageContentType.archive:
      case MessageContentType.document:
        return FileMessageBody.fromJson(json);
      case MessageContentType.location:
        return LocationMessageBody.fromJson(json);
      case MessageContentType.groupInvite:
      case MessageContentType.groupJoinApprove:
        return GroupInviteMessageBody.fromJson(json);
      case MessageContentType.complex:
        return ComplexMessageBody.fromJson(json);
      case MessageContentType.recall:
        return RecallMessageBody.fromJson(json);
      case MessageContentType.edit:
        return EditMessageBody.fromJson(json);
      case MessageContentType.unknown:
      default:
        return null;
    }
  }

  static Map<String, dynamic>? _tryDecode(dynamic val) {
    try {
      if (val == null) return null;
      if (val is Map<String, dynamic>) return val;
      if (val is String) {
        final decoded = jsonDecode(val);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 将 Message DTO 转换为 SingleMessage (本地存储用)
  static SingleMessage toSingleMessage(IMessage dto, String ownerId) {
    return SingleMessage(
      messageId: dto.messageId,
      fromId: dto.fromId,
      toId: dto.toId ?? '',
      ownerId: ownerId,
      messageBody: jsonEncode(dto.messageBody?.toJson() ?? {}),
      messageContentType: dto.messageContentType,
      messageTime: dto.messageTime,
      messageType: dto.messageType,
      readStatus: dto.readStatus,
      sequence: dto.sequence,
      extra: dto.extra != null ? jsonEncode(dto.extra) : '',
    );
  }

  /// 将 Message DTO 转换为 GroupMessage (本地存储用)
  static GroupMessage toGroupMessage(IMessage dto, String ownerId) {
    return GroupMessage(
      messageId: dto.messageId,
      fromId: dto.fromId,
      ownerId: ownerId,
      groupId: dto.groupId ?? '',
      messageBody: jsonEncode(dto.messageBody?.toJson() ?? {}),
      messageContentType: dto.messageContentType,
      messageTime: dto.messageTime,
      messageType: dto.messageType,
      readStatus: dto.readStatus,
      sequence: dto.sequence,
      extra: dto.extra != null ? jsonEncode(dto.extra) : '',
    );
  }

  /// 从本地 SingleMessage 转换为 Message DTO
  static IMessage fromSingleMessage(SingleMessage message) {
    final Map<String, dynamic>? bodyMap = _tryDecode(message.messageBody);
    return IMessage(
      messageId: message.messageId,
      fromId: message.fromId,
      toId: message.toId,
      messageType: message.messageType,
      messageContentType: message.messageContentType,
      messageBody: _parseMessageBody(bodyMap, message.messageContentType),
      messageTime: message.messageTime,
      readStatus: message.readStatus,
      sequence: message.sequence,
      extra:
          message.extra?.isNotEmpty == true ? _tryDecode(message.extra) : null,
    );
  }

  /// 从本地 GroupMessage 转换为 Message DTO
  static IMessage fromGroupMessage(GroupMessage message) {
    final Map<String, dynamic>? bodyMap = _tryDecode(message.messageBody);
    return IMessage(
      messageId: message.messageId,
      fromId: message.fromId,
      groupId: message.groupId,
      messageType: message.messageType,
      messageContentType: message.messageContentType,
      messageBody: _parseMessageBody(bodyMap, message.messageContentType),
      messageTime: message.messageTime,
      readStatus: message.readStatus,
      sequence: message.sequence,
      extra:
          message.extra?.isNotEmpty == true ? _tryDecode(message.extra) : null,
    );
  }

  /// 获取消息体的文本预览
  String getMessageBodyText() {
    final body = messageBody;
    if (body == null) return '';

    if (body is TextMessageBody) return body.text ?? '';
    if (body is ImageMessageBody) return '[图片]';
    if (body is VideoMessageBody) return '[视频]';
    if (body is AudioMessageBody) return '[语音]';
    if (body is FileMessageBody) return '[文件]';
    if (body is LocationMessageBody) return '[位置]';
    if (body is ComplexMessageBody) return '[复合消息]';
    if (body is GroupInviteMessageBody) return '[群邀请]';
    if (body is SystemMessageBody) return body.text ?? '[系统消息]';
    if (body is RecallMessageBody) return '[撤回消息]';
    if (body is EditMessageBody) return '[编辑消息]';
    return '[未知类型消息]';
  }

  /// 构建消息请求参数
  static Map<String, dynamic> buildRequest({
    required String fromId,
    required String targetId,
    required int messageType,
    required MessageBody body,
    required int contentType,
  }) {
    final isGroup = messageType == MessageType.groupMessage.code;
    return {
      'fromId': fromId,
      if (isGroup) 'groupId': targetId else 'toId': targetId,
      'messageType': messageType,
      'messageContentType': contentType,
      'messageBody': body.toJson(),
      'messageTime': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

/// 消息体基类
abstract class MessageBody {
  const MessageBody();

  Map<String, dynamic> toJson();
}

/// Reply 引用消息信息
class ReplyMessageInfo {
  final String? messageId;
  final String? fromId;
  final String? previewText;
  final int? messageContentType;

  const ReplyMessageInfo({
    this.messageId,
    this.fromId,
    this.previewText,
    this.messageContentType,
  });

  factory ReplyMessageInfo.fromJson(Map<String, dynamic> json) {
    return ReplyMessageInfo(
      messageId: json['messageId']?.toString(),
      fromId: json['fromId']?.toString(),
      previewText: json['previewText']?.toString(),
      messageContentType: IMessage._parseIntSafely(json['messageContentType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'fromId': fromId,
      'previewText': previewText,
      'messageContentType': messageContentType,
    };
  }
}

/// 文本消息体
class TextMessageBody extends MessageBody {
  final String? text;

  const TextMessageBody({this.text});

  factory TextMessageBody.fromJson(Map<String, dynamic> json) {
    return TextMessageBody(text: json['text']?.toString());
  }

  @override
  Map<String, dynamic> toJson() => {'text': text};

  static TextMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is TextMessageBody) return messageBody;
    return null;
  }
}

/// 图片消息体
class ImageMessageBody extends MessageBody {
  final String? path;
  final String? name;
  final int? size;

  const ImageMessageBody({this.path, this.name, this.size});

  factory ImageMessageBody.fromJson(Map<String, dynamic> json) {
    return ImageMessageBody(
      path: json['path']?.toString(),
      name: json['name']?.toString(),
      size: IMessage._parseIntSafely(json['size']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'path': path, 'name': name, 'size': size};

  static ImageMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is ImageMessageBody) return messageBody;
    return null;
  }
}

/// 视频消息体
class VideoMessageBody extends MessageBody {
  final String? path;
  final String? name;
  final int? duration; // seconds
  final int? size;

  const VideoMessageBody({this.path, this.name, this.duration, this.size});

  factory VideoMessageBody.fromJson(Map<String, dynamic> json) {
    return VideoMessageBody(
      path: json['path']?.toString(),
      name: json['name']?.toString(),
      duration: IMessage._parseIntSafely(json['duration']),
      size: IMessage._parseIntSafely(json['size']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'path': path, 'name': name, 'duration': duration, 'size': size};
  }

  static VideoMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is VideoMessageBody) return messageBody;
    return null;
  }
}

/// 语音消息体
class AudioMessageBody extends MessageBody {
  final String? path;
  final int? duration;
  final int? size;

  const AudioMessageBody({this.path, this.duration, this.size});

  factory AudioMessageBody.fromJson(Map<String, dynamic> json) {
    return AudioMessageBody(
      path: json['path']?.toString(),
      duration: IMessage._parseIntSafely(json['duration']),
      size: IMessage._parseIntSafely(json['size']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'path': path, 'duration': duration, 'size': size};
  }

  static AudioMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is AudioMessageBody) return messageBody;
    return null;
  }
}

/// 文件消息体
class FileMessageBody extends MessageBody {
  final String? path;
  final String? name;
  final String? suffix;
  final int? size;

  const FileMessageBody({this.path, this.name, this.suffix, this.size});

  factory FileMessageBody.fromJson(Map<String, dynamic> json) {
    return FileMessageBody(
      path: json['path']?.toString(),
      name: json['name']?.toString(),
      suffix: json['suffix']?.toString(),
      size: IMessage._parseIntSafely(json['size']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'path': path, 'name': name, 'suffix': suffix, 'size': size};
  }

  static FileMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is FileMessageBody) return messageBody;
    return null;
  }
}

/// 位置消息体
class LocationMessageBody extends MessageBody {
  final String? title;
  final String? address;
  final double? latitude;
  final double? longitude;

  const LocationMessageBody({
    this.title,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory LocationMessageBody.fromJson(Map<String, dynamic> json) {
    return LocationMessageBody(
      title: json['title']?.toString(),
      address: json['address']?.toString(),
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static LocationMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is LocationMessageBody) return messageBody;
    return null;
  }
}

/// 混合消息体（Complex）
class ComplexMessageBody extends MessageBody {
  final List<Part> parts;
  final List<ImageMessageBody> images;
  final List<VideoMessageBody> videos;

  const ComplexMessageBody({
    this.parts = const [],
    this.images = const [],
    this.videos = const [],
  });

  factory ComplexMessageBody.fromJson(Map<String, dynamic> json) {
    return ComplexMessageBody(
      parts: (json['parts'] as List?)
              ?.map((e) => Part.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      images: (json['images'] as List?)
              ?.map((e) =>
                  ImageMessageBody.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      videos: (json['videos'] as List?)
              ?.map((e) =>
                  VideoMessageBody.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'parts': parts.map((p) => p.toJson()).toList(),
      'images': images.map((i) => i.toJson()).toList(),
      'videos': videos.map((v) => v.toJson()).toList(),
    };
  }
}

/// Part 嵌套类
class Part {
  final String type;
  final Map<String, dynamic>? content;
  final Map<String, dynamic>? meta;

  const Part({required this.type, this.content, this.meta});

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      type: json['type']?.toString() ?? '',
      content: json['content'] as Map<String, dynamic>?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'content': content, 'meta': meta};
  }
}

/// 群组邀请消息体
class GroupInviteMessageBody extends MessageBody {
  final String? requestId;
  final String? groupId;
  final String? groupName;
  final String? groupAvatar;
  final String? inviterId;
  final String? inviterName;
  final String? userId;
  final String? userName;
  final int? approveStatus; // 1:待处理 2:已同意 3:已拒绝

  const GroupInviteMessageBody({
    this.requestId,
    this.groupId,
    this.groupName,
    this.groupAvatar,
    this.inviterId,
    this.inviterName,
    this.userId,
    this.userName,
    this.approveStatus,
  });

  factory GroupInviteMessageBody.fromJson(Map<String, dynamic> json) {
    return GroupInviteMessageBody(
      requestId: json['requestId']?.toString(),
      groupId: json['groupId']?.toString(),
      groupName: json['groupName']?.toString(),
      groupAvatar: json['groupAvatar']?.toString(),
      inviterId: json['inviterId']?.toString(),
      inviterName: json['inviterName']?.toString(),
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
      approveStatus: IMessage._parseIntSafely(json['approveStatus']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'groupId': groupId,
      'groupName': groupName,
      'groupAvatar': groupAvatar,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'userId': userId,
      'userName': userName,
      'approveStatus': approveStatus,
    };
  }

  static GroupInviteMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is GroupInviteMessageBody) return messageBody;
    return null;
  }
}

/// 系统消息体
class SystemMessageBody extends MessageBody {
  final String? text;

  const SystemMessageBody({this.text});

  factory SystemMessageBody.fromJson(Map<String, dynamic> json) {
    return SystemMessageBody(text: json['text']?.toString());
  }

  @override
  Map<String, dynamic> toJson() => {'text': text};

  static SystemMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is SystemMessageBody) return messageBody;
    return null;
  }
}

/// Recall 撤回消息体
class RecallMessageBody extends MessageBody {
  final String? messageId;
  final String? operatorId;
  final String? reason;
  final int? recallTime;
  final String? chatId;
  final int? chatType;

  const RecallMessageBody({
    this.messageId,
    this.operatorId,
    this.reason,
    this.recallTime,
    this.chatId,
    this.chatType,
  });

  factory RecallMessageBody.fromJson(Map<String, dynamic> json) {
    return RecallMessageBody(
      messageId: json['messageId']?.toString(),
      operatorId: json['operatorId']?.toString(),
      reason: json['reason']?.toString(),
      recallTime: IMessage._parseIntSafely(json['recallTime']),
      chatId: json['chatId']?.toString(),
      chatType: IMessage._parseIntSafely(json['chatType']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'operatorId': operatorId,
      'reason': reason,
      'recallTime': recallTime,
      'chatId': chatId,
      'chatType': chatType,
    };
  }

  static RecallMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is RecallMessageBody) return messageBody;
    return null;
  }
}

/// Edit 编辑消息体
class EditMessageBody extends MessageBody {
  final String? messageId;
  final String? editorId;
  final int? editTime;
  final int? newMessageContentType;
  final Map<String, dynamic>? newMessageBody;
  final String? oldPreview;
  final String? chatId;
  final int? chatType;

  const EditMessageBody({
    this.messageId,
    this.editorId,
    this.editTime,
    this.newMessageContentType,
    this.newMessageBody,
    this.oldPreview,
    this.chatId,
    this.chatType,
  });

  factory EditMessageBody.fromJson(Map<String, dynamic> json) {
    return EditMessageBody(
      messageId: json['messageId']?.toString(),
      editorId: json['editorId']?.toString(),
      editTime: IMessage._parseIntSafely(json['editTime']),
      newMessageContentType:
          IMessage._parseIntSafely(json['newMessageContentType']),
      newMessageBody: json['newMessageBody'] as Map<String, dynamic>?,
      oldPreview: json['oldPreview']?.toString(),
      chatId: json['chatId']?.toString(),
      chatType: IMessage._parseIntSafely(json['chatType']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'editorId': editorId,
      'editTime': editTime,
      'newMessageContentType': newMessageContentType,
      'newMessageBody': newMessageBody,
      'oldPreview': oldPreview,
      'chatId': chatId,
      'chatType': chatType,
    };
  }

  static EditMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody is EditMessageBody) return messageBody;
    return null;
  }
}

/// 扩展方法：基于 IMessage 判断类型
extension MessageTypeExtension on IMessage {
  bool get isSingleMessage => messageType == MessageType.singleMessage.code;

  bool get isGroupMessage => messageType == MessageType.groupMessage.code;

  bool get isVideoMessage =>
      messageContentType == MessageContentType.video.code;

  bool get isSystemMessage => messageContentType == MessageContentType.tip.code;

  /// 获取目标 ID（单聊返回 toId，群聊返回 groupId）
  String? get targetId {
    if (isSingleMessage) return toId;
    if (isGroupMessage) return groupId;
    return null;
  }
}
