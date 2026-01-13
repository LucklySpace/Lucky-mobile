import 'dart:convert';

import '../../constants/app_message.dart';
import 'group_message.dart';
import 'single_message.dart';

/// 新版 Message DTO，参考后端 IMessage 定义并扩展
class MessageVideoCallDto {
  String? fromId; // 发送者ID
  String? toId; // 接收者ID
  int? type; // 消息类型

  MessageVideoCallDto({this.fromId, this.toId, this.type});

  factory MessageVideoCallDto.fromJson(Map<String, dynamic> json) {
    return MessageVideoCallDto(
      fromId: json['fromId'],
      toId: json['toId'],
      type: (json['type'] is int)
          ? json['type']
          : (json['type'] != null ? (json['type'] as num).toInt() : null),
    );
  }
}

/// 消息接收数据传输对象
/// 对应后端 IMessage
class IMessage {
  /// 发送者ID
  String fromId;

  /// 消息临时ID（客户端生成）
  String? messageTempId;

  /// 消息唯一标识（服务端生成，可为空）
  String messageId;

  /// 消息内容类型（用于决定 messageBody 的具体类型）
  int messageContentType;

  /// 消息体，根据 messageContentType 解析
  MessageBody? messageBody;

  /// 消息时间戳（毫秒）
  int messageTime;

  /// 消息读取状态
  int readStatus;

  /// 消息序号（用于排序）
  int sequence;

  /// 额外信息（Map）
  Map<String, dynamic>? extra;

  /// 引用的消息信息（reply）
  ReplyMessageInfo? replyMessage;

  /// 被 @ 的用户 ID 列表
  List<String>? mentionedUserIds;

  /// 是否 @ 所有人
  bool? mentionAll;

  /// 单聊接收者ID（仅在单聊时使用）
  String? toId;

  /// 群组ID（仅在群聊时使用）
  String? groupId;

  /// 消息类型（单聊/群聊/系统等）
  int messageType;

  IMessage({
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
    return IMessage(
      fromId: json['fromId'],
      messageTempId: json['messageTempId'],
      messageId: json['messageId'],
      messageContentType: json['messageContentType'] is int
          ? json['messageContentType']
          : (json['messageContentType'] != null
              ? (json['messageContentType'] as num).toInt()
              : 0),
      messageBody: _parseMessageBody(
          json['messageBody'] is String
              ? _tryDecode(json['messageBody'])
              : (json['messageBody'] as Map<String, dynamic>?),
          json['messageContentType'] is int
              ? json['messageContentType']
              : (json['messageContentType'] != null
                  ? (json['messageContentType'] as num).toInt()
                  : 0)),
      messageTime: json['messageTime'] is int
          ? json['messageTime']
          : (json['messageTime'] != null
              ? (json['messageTime'] as num).toInt()
              : 0),
      readStatus: json['readStatus'] is int
          ? json['readStatus']
          : (json['readStatus'] != null
              ? (json['readStatus'] as num).toInt()
              : IMessageReadStatus.UNREAD),
      sequence: json['sequence'] is int
          ? json['sequence']
          : (json['sequence'] != null ? (json['sequence'] as num).toInt() : 0),
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
      mentionAll: json['mentionAll'] == null
          ? false
          : (json['mentionAll'] as bool? ??
              (json['mentionAll'].toString().toLowerCase() == 'true')),
      toId: (json['messageType'] is int
                  ? json['messageType']
                  : (json['messageType'] != null
                      ? (json['messageType'] as num).toInt()
                      : 0)) ==
              MessageType.singleMessage.code
          ? json['toId']
          : null,
      groupId: (json['messageType'] is int
                  ? json['messageType']
                  : (json['messageType'] != null
                      ? (json['messageType'] as num).toInt()
                      : 0)) ==
              MessageType.groupMessage.code
          ? json['groupId']
          : null,
      messageType: json['messageType'] is int
          ? json['messageType']
          : (json['messageType'] != null
              ? (json['messageType'] as num).toInt()
              : 0),
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

  /// 根据 messageContentType 解析 messageBody
  static MessageBody? _parseMessageBody(Map<String, dynamic>? json, int? type) {
    if (json == null || type == null) return null;

    final contentType = MessageContentType.fromCode(type);

    // 使用枚举匹配（新版 code）
    switch (contentType) {
      // 系统提示
      case MessageContentType.tip:
        return SystemMessageBody.fromJson(json);

      // 文本类
      case MessageContentType.text:
      case MessageContentType.markdown:
      case MessageContentType.richText:
        return TextMessageBody.fromJson(json);

      // 媒体类
      case MessageContentType.image:
      case MessageContentType.gif:
        return ImageMessageBody.fromJson(json);
      case MessageContentType.video:
        return VideoMessageBody.fromJson(json);
      case MessageContentType.audio:
        return AudioMessageBody.fromJson(json);
      case MessageContentType.sticker:
        return ImageMessageBody.fromJson(json);

      // 文件类
      case MessageContentType.file:
      case MessageContentType.archive:
      case MessageContentType.document:
        return FileMessageBody.fromJson(json);

      // 富媒体类
      case MessageContentType.location:
        return LocationMessageBody.fromJson(json);
      case MessageContentType.groupInvite:
      case MessageContentType.groupJoinApprove:
        return GroupInviteMessageBody.fromJson(json);

      // 其它
      case MessageContentType.complex:
        return ComplexMessageBody.fromJson(json);
      case MessageContentType.recall:
        return RecallMessageBody.fromJson(json);
      case MessageContentType.edit:
        return EditMessageBody.fromJson(json);

      // 未知类型 - 尝试旧版 code 兼容
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

  /// 将 MessageReceiveDto 转换为 SingleMessage
  static SingleMessage toSingleMessage(IMessage dto, String ownerId) {
    if (dto.messageType != MessageType.singleMessage.code) {
      throw Exception('Cannot convert non-private message to SingleMessage');
    }

    return SingleMessage(
      messageId: dto.messageId ?? '',
      fromId: dto.fromId ?? '',
      toId: dto.toId ?? '',
      ownerId: ownerId,
      // 将 messageBody 序列化为字符串存储（与后端一致）
      messageBody: jsonEncode(dto.messageBody?.toJson() ?? {}),
      messageContentType: dto.messageContentType,
      messageTime: dto.messageTime,
      messageType: dto.messageType,
      readStatus: dto.readStatus,
      sequence: dto.sequence,
      extra: dto.extra != null ? jsonEncode(dto.extra) : '',
    );
  }

  /// 将 MessageReceiveDto 转换为 GroupMessage
  static GroupMessage toGroupMessage(IMessage dto, String ownerId) {
    if (dto.messageType != MessageType.groupMessage.code) {
      throw Exception('Cannot convert non-group message to GroupMessage');
    }

    return GroupMessage(
      messageId: dto.messageId ?? '',
      fromId: dto.fromId ?? '',
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

  /// 将 SingleMessage 转换为 MessageReceiveDto
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
      extra: message.extra != null ? _tryDecode(message.extra) : null,
    );
  }

  /// 将 GroupMessage 转换为 MessageReceiveDto
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
      extra: message.extra != null ? _tryDecode(message.extra) : null,
    );
  }

  /// 获取消息体的文本表示
  String getMessageBodyText() {
    if (messageBody == null) {
      return '';
    }

    if (messageBody is TextMessageBody) {
      return (messageBody as TextMessageBody).text ?? '';
    } else if (messageBody is ImageMessageBody) {
      return '[图片]';
    } else if (messageBody is VideoMessageBody) {
      return '[视频]';
    } else if (messageBody is AudioMessageBody) {
      return '[语音]';
    } else if (messageBody is FileMessageBody) {
      return '[文件]';
    } else if (messageBody is LocationMessageBody) {
      return '[位置]';
    } else if (messageBody is ComplexMessageBody) {
      return '[复合消息]';
    } else if (messageBody is GroupInviteMessageBody) {
      return '[群邀请]';
    } else if (messageBody is SystemMessageBody) {
      return (messageBody as SystemMessageBody).text ?? '[系统消息]';
    } else if (messageBody is RecallMessageBody) {
      return '[撤回消息]';
    } else if (messageBody is EditMessageBody) {
      return '[编辑消息]';
    } else {
      return '[未知类型消息]';
    }
  }
}

/// 消息体基类
abstract class MessageBody {
  MessageBody() {}

  Map<String, dynamic> toJson();
}

/// Reply 引用消息信息
class ReplyMessageInfo {
  String? messageId;
  String? fromId;
  String? previewText;
  int? messageContentType;

  ReplyMessageInfo(
      {this.messageId, this.fromId, this.previewText, this.messageContentType});

  factory ReplyMessageInfo.fromJson(Map<String, dynamic> json) {
    return ReplyMessageInfo(
      messageId: json['messageId'],
      fromId: json['fromId'],
      previewText: json['previewText'],
      messageContentType: json['messageContentType'] is int
          ? json['messageContentType']
          : (json['messageContentType'] != null
              ? (json['messageContentType'] as num).toInt()
              : null),
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
  String? text;

  TextMessageBody({this.text});

  factory TextMessageBody.fromJson(Map<String, dynamic> json) {
    return TextMessageBody(
      text: json['text'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }

  static TextMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is TextMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return TextMessageBody.fromJson(json);
    } catch (e) {
      print('转换TextMessageBody失败: $e');
      return null;
    }
  }
}

/// 图片消息体
class ImageMessageBody extends MessageBody {
  String? path;
  String? name;
  int? size;

  ImageMessageBody({this.path, this.name, this.size});

  factory ImageMessageBody.fromJson(Map<String, dynamic> json) {
    return ImageMessageBody(
      path: json['path'],
      name: json['name'],
      size: json['size'] is int
          ? json['size']
          : (json['size'] != null ? (json['size'] as num).toInt() : null),
    );
  }

  static ImageMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is ImageMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return ImageMessageBody.fromJson(json);
    } catch (e) {
      print('转换ImageMessageBody失败: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'size': size,
    };
  }
}

/// 视频消息体
class VideoMessageBody extends MessageBody {
  String? path;
  String? name;
  int? duration; // seconds
  int? size;

  VideoMessageBody({this.path, this.name, this.duration, this.size});

  factory VideoMessageBody.fromJson(Map<String, dynamic> json) {
    return VideoMessageBody(
      path: json['path'],
      name: json['name'],
      duration: json['duration'] is int
          ? json['duration']
          : (json['duration'] != null
              ? (json['duration'] as num).toInt()
              : null),
      size: json['size'] is int
          ? json['size']
          : (json['size'] != null ? (json['size'] as num).toInt() : null),
    );
  }

  static VideoMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is VideoMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return VideoMessageBody.fromJson(json);
    } catch (e) {
      print('转换VideoMessageBody失败: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'duration': duration,
      'size': size,
    };
  }
}

/// 语音消息体
class AudioMessageBody extends MessageBody {
  String? path;
  int? duration;
  int? size;

  AudioMessageBody({this.path, this.duration, this.size});

  factory AudioMessageBody.fromJson(Map<String, dynamic> json) {
    return AudioMessageBody(
      path: json['path'],
      duration: json['duration'] is int
          ? json['duration']
          : (json['duration'] != null
              ? (json['duration'] as num).toInt()
              : null),
      size: json['size'] is int
          ? json['size']
          : (json['size'] != null ? (json['size'] as num).toInt() : null),
    );
  }

  static AudioMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is AudioMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return AudioMessageBody.fromJson(json);
    } catch (e) {
      print('转换AudioMessageBody失败: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'duration': duration,
      'size': size,
    };
  }
}

/// 文件消息体
class FileMessageBody extends MessageBody {
  String? path;
  String? name;
  String? suffix;
  int? size;

  FileMessageBody({this.path, this.name, this.suffix, this.size});

  factory FileMessageBody.fromJson(Map<String, dynamic> json) {
    return FileMessageBody(
      path: json['path'],
      name: json['name'],
      suffix: json['suffix'],
      size: json['size'] is int
          ? json['size']
          : (json['size'] != null ? (json['size'] as num).toInt() : null),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'suffix': suffix,
      'size': size,
    };
  }

  static FileMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is FileMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return FileMessageBody.fromJson(json);
    } catch (e) {
      print('转换FileMessageBody失败: $e');
      return null;
    }
  }
}

/// 位置消息体
class LocationMessageBody extends MessageBody {
  String? title;
  String? address;
  double? latitude;
  double? longitude;

  LocationMessageBody(
      {this.title, this.address, this.latitude, this.longitude});

  factory LocationMessageBody.fromJson(Map<String, dynamic> json) {
    return LocationMessageBody(
      title: json['title'],
      address: json['address'],
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : (json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : (json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null),
    );
  }

  static LocationMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is LocationMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return LocationMessageBody.fromJson(json);
    } catch (e) {
      print('转换LocationMessageBody失败: $e');
      return null;
    }
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
}

/// 混合消息体（Complex）
class ComplexMessageBody extends MessageBody {
  List<Part> parts;
  List<ImageMessageBody> images;
  List<VideoMessageBody> videos;

  ComplexMessageBody(
      {List<Part>? parts,
      List<ImageMessageBody>? images,
      List<VideoMessageBody>? videos})
      : parts = parts ?? [],
        images = images ?? [],
        videos = videos ?? [];

  factory ComplexMessageBody.fromJson(Map<String, dynamic> json) {
    final partsJson = (json['parts'] as List?) ?? [];
    final imagesJson = (json['images'] as List?) ?? [];
    final videosJson = (json['videos'] as List?) ?? [];

    return ComplexMessageBody(
      parts: partsJson
          .map((e) => Part.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      images: imagesJson
          .map((e) =>
              ImageMessageBody.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      videos: videosJson
          .map((e) =>
              VideoMessageBody.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
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
  String type;
  Map<String, dynamic>? content;
  Map<String, dynamic>? meta;

  Part({required this.type, this.content, this.meta});

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      type: json['type'],
      content: json['content'] is Map
          ? Map<String, dynamic>.from(json['content'])
          : null,
      meta:
          json['meta'] is Map ? Map<String, dynamic>.from(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      'meta': meta,
    };
  }
}

/// 群组邀请消息体
class GroupInviteMessageBody extends MessageBody {
  String? requestId;
  String? groupId;
  String? groupName;
  String? groupAvatar;
  String? inviterId;
  String? inviterName;
  String? userId;
  String? userName;
  int? approveStatus; // 1:待处理 2:已同意 3:已拒绝

  GroupInviteMessageBody({
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
      requestId: json['requestId'],
      groupId: json['groupId'],
      groupName: json['groupName'],
      groupAvatar: json['groupAvatar'],
      inviterId: json['inviterId'],
      inviterName: json['inviterName'],
      userId: json['userId'],
      userName: json['userName'],
      approveStatus: json['approveStatus'] is int
          ? json['approveStatus']
          : (json['approveStatus'] != null
              ? (json['approveStatus'] as num).toInt()
              : null),
    );
  }

  static GroupInviteMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is GroupInviteMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return GroupInviteMessageBody.fromJson(json);
    } catch (e) {
      print('转换GroupInviteMessageBody失败: $e');
      return null;
    }
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
}

/// 系统消息体
class SystemMessageBody extends MessageBody {
  String? text;

  SystemMessageBody({this.text});

  factory SystemMessageBody.fromJson(Map<String, dynamic> json) {
    return SystemMessageBody(
      text: json['text'],
    );
  }

  static SystemMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is SystemMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return SystemMessageBody.fromJson(json);
    } catch (e) {
      print('转换SystemMessageBody失败: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}

/// Recall 撤回消息体（messageContentType == 11）
class RecallMessageBody extends MessageBody {
  String? messageId;
  String? operatorId;
  String? reason;
  int? recallTime;
  String? chatId;
  int? chatType;

  RecallMessageBody(
      {this.messageId,
      this.operatorId,
      this.reason,
      this.recallTime,
      this.chatId,
      this.chatType});

  factory RecallMessageBody.fromJson(Map<String, dynamic> json) {
    return RecallMessageBody(
      messageId: json['messageId'],
      operatorId: json['operatorId'],
      reason: json['reason'],
      recallTime: json['recallTime'] is int
          ? json['recallTime']
          : (json['recallTime'] != null
              ? (json['recallTime'] as num).toInt()
              : null),
      chatId: json['chatId'],
      chatType: json['chatType'] is int
          ? json['chatType']
          : (json['chatType'] != null
              ? (json['chatType'] as num).toInt()
              : null),
    );
  }

  static RecallMessageBody? fromMessageBody(MessageBody? messageBody) {
    if (messageBody == null) return null;
    if (messageBody is RecallMessageBody) return messageBody;
    try {
      final json = messageBody.toJson();
      return RecallMessageBody.fromJson(json);
    } catch (e) {
      print('转换RecallMessageBody失败: $e');
      return null;
    }
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
}

/// Edit 编辑消息体（messageContentType == 12）
class EditMessageBody extends MessageBody {
  String? messageId;
  String? editorId;
  int? editTime;
  int? newMessageContentType;
  Map<String, dynamic>? newMessageBody;
  String? oldPreview;
  String? chatId;
  int? chatType;

  EditMessageBody({
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
      messageId: json['messageId'],
      editorId: json['editorId'],
      editTime: json['editTime'] is int
          ? json['editTime']
          : (json['editTime'] != null
              ? (json['editTime'] as num).toInt()
              : null),
      newMessageContentType: json['newMessageContentType'] is int
          ? json['newMessageContentType']
          : (json['newMessageContentType'] != null
              ? (json['newMessageContentType'] as num).toInt()
              : null),
      newMessageBody: json['newMessageBody'] is Map
          ? Map<String, dynamic>.from(json['newMessageBody'])
          : null,
      oldPreview: json['oldPreview'],
      chatId: json['chatId'],
      chatType: json['chatType'] is int
          ? json['chatType']
          : (json['chatType'] != null
              ? (json['chatType'] as num).toInt()
              : null),
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
}

/// 扩展方法：基于 MessageReceiveDto 判断类型
extension MessageTypeExtension on IMessage {
  bool get isSingleMessage => messageType == MessageType.singleMessage.code;

  bool get isGroupMessage => messageType == MessageType.groupMessage.code;

  bool get isVideoMessage => messageContentType == 3;

  bool get isSystemMessage => messageContentType == 10;

  /// 获取目标 ID（单聊返回 toId，群聊返回 groupId）
  String? get targetId {
    if (isSingleMessage) return toId;
    if (isGroupMessage) return groupId;
    return null;
  }
}
