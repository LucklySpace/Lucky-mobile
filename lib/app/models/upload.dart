/// 文件上传响应模型
class UploadResponse {
  /// 文件URL
  final String url;

  /// 文件名称
  final String? fileName;

  /// 文件大小（字节）
  final int? fileSize;

  /// 文件类型 (MIME类型)
  final String? fileType;

  /// 文件MD5
  final String? md5;

  /// 文件宽度（图片/视频）
  final int? width;

  /// 文件高度（图片/视频）
  final int? height;

  /// 视频时长（秒）
  final int? duration;

  UploadResponse({
    required this.url,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.md5,
    this.width,
    this.height,
    this.duration,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      url: json['url']?.toString() ?? '',
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize'] is int
          ? json['fileSize']
          : (json['fileSize'] != null
              ? int.tryParse(json['fileSize'].toString())
              : null),
      fileType: json['fileType']?.toString(),
      md5: json['md5']?.toString(),
      width: json['width'] is int
          ? json['width']
          : (json['width'] != null
              ? int.tryParse(json['width'].toString())
              : null),
      height: json['height'] is int
          ? json['height']
          : (json['height'] != null
              ? int.tryParse(json['height'].toString())
              : null),
      duration: json['duration'] is int
          ? json['duration']
          : (json['duration'] != null
              ? int.tryParse(json['duration'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      'md5': md5,
      'width': width,
      'height': height,
      'duration': duration,
    };
  }

  /// 是否为图片文件
  bool get isImage => fileType?.startsWith('image/') ?? false;

  /// 是否为视频文件
  bool get isVideo => fileType?.startsWith('video/') ?? false;

  /// 是否为音频文件
  bool get isAudio => fileType?.startsWith('audio/') ?? false;

  @override
  String toString() => 'UploadResponse(url: $url, fileName: $fileName)';
}

/// 文件上传进度回调
typedef UploadProgressCallback = void Function(int sent, int total);

/// 图片上传响应（扩展）
class ImageUploadResponse extends UploadResponse {
  /// 图片缩略图URL
  final String? thumbnailUrl;

  /// 图片格式 (jpg, png, gif等)
  final String? format;

  ImageUploadResponse({
    required super.url,
    super.fileName,
    super.fileSize,
    super.fileType,
    super.md5,
    super.width,
    super.height,
    this.thumbnailUrl,
    this.format,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      url: json['url']?.toString() ?? '',
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize'] is int
          ? json['fileSize']
          : (json['fileSize'] != null
              ? int.tryParse(json['fileSize'].toString())
              : null),
      fileType: json['fileType']?.toString(),
      md5: json['md5']?.toString(),
      width: json['width'] is int
          ? json['width']
          : (json['width'] != null
              ? int.tryParse(json['width'].toString())
              : null),
      height: json['height'] is int
          ? json['height']
          : (json['height'] != null
              ? int.tryParse(json['height'].toString())
              : null),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      format: json['format']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['thumbnailUrl'] = thumbnailUrl;
    json['format'] = format;
    return json;
  }
}
