import 'package:get/get.dart';

/// 国际化工具类
///
/// 提供简洁的API来访问翻译文本
///
/// 使用示例:
/// ```dart
/// I18n.t('login.title')  // 欢迎登录 / Welcome
/// I18n.confirm  // 确认 / Confirm
/// I18n.error('error.network')  // 网络连接失败 / Network connection failed
/// ```
class I18n {
  // 私有构造函数
  I18n._();

  // ==================== 通用方法 ====================

  /// 获取翻译文本
  ///
  /// [key] 翻译键
  /// [args] 格式化参数（可选）
  static String t(String key, {List<String>? args}) {
    String text = key.tr;

    // 如果有参数，进行格式化
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        text = text.replaceFirst('%d', args[i]);
      }
    }

    return text;
  }

  /// 检查是否存在指定的翻译键
  static bool has(String key) {
    return key.tr != key;
  }

  // ==================== 通用文本 ====================

  static String get appName => 'app_name'.tr;

  static String get confirm => 'confirm'.tr;

  static String get cancel => 'cancel'.tr;

  static String get ok => 'ok'.tr;

  static String get save => 'save'.tr;

  static String get delete => 'delete'.tr;

  static String get edit => 'edit'.tr;

  static String get send => 'send'.tr;

  static String get back => 'back'.tr;

  static String get next => 'next'.tr;

  static String get done => 'done'.tr;

  static String get loading => 'loading'.tr;

  static String get error => 'error'.tr;

  static String get success => 'success'.tr;

  static String get warning => 'warning'.tr;

  static String get info => 'info'.tr;

  static String get retry => 'retry'.tr;

  static String get refresh => 'refresh'.tr;

  static String get search => 'search'.tr;

  static String get more => 'more'.tr;

  static String get settings => 'settings'.tr;

  static String get logout => 'logout'.tr;

  static String get yes => 'yes'.tr;

  static String get no => 'no'.tr;

  static String get all => 'all'.tr;

  static String get none => 'none'.tr;

  static String get submit => 'submit'.tr;

  static String get close => 'close'.tr;

  // ==================== 错误消息 ====================

  /// 根据错误类型获取错误消息
  static String errorMessage(String errorType) => 'error.$errorType'.tr;

  static String get errorNetwork => 'error.network'.tr;

  static String get errorTimeout => 'error.timeout'.tr;

  static String get errorServer => 'error.server'.tr;

  static String get errorUnknown => 'error.unknown'.tr;

  static String get errorPermissionDenied => 'error.permission_denied'.tr;

  static String get errorUnauthorized => 'error.unauthorized'.tr;

  static String get errorNotFound => 'error.not_found'.tr;

  static String get errorBadRequest => 'error.bad_request'.tr;

  static String get errorTokenExpired => 'error.token_expired'.tr;

  // ==================== 登录 ====================

  static String get login => 'login'.tr;

  static String get loginTitle => 'login.title'.tr;

  static String get loginUsername => 'login.username'.tr;

  static String get loginPhone => 'login.phone'.tr;

  static String get loginPassword => 'login.password'.tr;

  static String get loginVerifyCode => 'login.verify_code'.tr;

  static String get loginRememberPassword => 'login.remember_password'.tr;

  static String get loginForgotPassword => 'login.forgot_password'.tr;

  static String get loginRegister => 'login.register'.tr;

  static String get loginPasswordLogin => 'login.password_login'.tr;

  static String get loginSmsLogin => 'login.sms_login'.tr;

  static String get loginSendCode => 'login.send_code'.tr;

  static String get loginResendCode => 'login.resend_code'.tr;

  static String get loginCodeSent => 'login.code_sent'.tr;

  static String get loginSuccess => 'login.success'.tr;

  static String get loginFailed => 'login.failed'.tr;

  static String get loginLoggingIn => 'login.logging_in'.tr;

  static String get loginInputUsername => 'login.input_username'.tr;

  static String get loginInputPassword => 'login.input_password'.tr;

  static String get loginInputPhone => 'login.input_phone'.tr;

  static String get loginInputVerifyCode => 'login.input_verify_code'.tr;

  static String get loginInvalidPhone => 'login.invalid_phone'.tr;

  static String get loginInvalidPassword => 'login.invalid_password'.tr;

  static String get loginInvalidVerifyCode => 'login.invalid_verify_code'.tr;

  // ==================== 导航 ====================

  static String get navHome => 'nav.home'.tr;

  static String get navContacts => 'nav.contacts'.tr;

  static String get navDiscover => 'nav.discover'.tr;

  static String get navMe => 'nav.me'.tr;

  // ==================== 聊天 ====================

  static String get chat => 'chat'.tr;

  static String get chatInputMessage => 'chat.input_message'.tr;

  static String get chatSend => 'chat.send'.tr;

  static String get chatEmpty => 'chat.empty'.tr;

  static String get chatLoading => 'chat.loading'.tr;

  static String get chatLoadMore => 'chat.load_more'.tr;

  static String get chatNoMore => 'chat.no_more'.tr;

  static String get chatSending => 'chat.sending'.tr;

  static String get chatSendFailed => 'chat.send_failed'.tr;

  static String get chatRecall => 'chat.recall'.tr;

  static String get chatCopy => 'chat.copy'.tr;

  static String get chatDelete => 'chat.delete'.tr;

  static String get chatForward => 'chat.forward'.tr;

  static String get chatQuote => 'chat.quote'.tr;

  static String get chatRecalled => 'chat.recalled'.tr;

  static String get chatVideoCall => 'chat.video_call'.tr;

  static String get chatVoiceCall => 'chat.voice_call'.tr;

  static String get chatTakePhoto => 'chat.take_photo'.tr;

  static String get chatChoosePhoto => 'chat.choose_photo'.tr;

  static String get chatChooseFile => 'chat.choose_file'.tr;

  static String get chatLocation => 'chat.location'.tr;

  static String get chatContactCard => 'chat.contact_card'.tr;

  static String get chatVideoCallIncoming => 'chat.video_call_incoming'.tr;

  static String get chatAccept => 'chat.accept'.tr;

  static String get chatReject => 'chat.reject'.tr;

  static String get chatCallEnded => 'chat.call_ended'.tr;

  static String get chatCallRejected => 'chat.call_rejected'.tr;

  static String get chatCallCancelled => 'chat.call_cancelled'.tr;

  static String get chatCallBusy => 'chat.call_busy'.tr;

  static String get chatMessageTooLong => 'chat.message_too_long'.tr;

  static String get chatSelectChat => 'chat.select_chat'.tr;

  // ==================== 会话 ====================

  static String get conversationTitle => 'conversation.title'.tr;

  static String get conversationEmpty => 'conversation.empty'.tr;

  static String get conversationDeleteConfirm =>
      'conversation.delete_confirm'.tr;

  static String get conversationMarkRead => 'conversation.mark_read'.tr;

  static String get conversationMarkUnread => 'conversation.mark_unread'.tr;

  static String get conversationPin => 'conversation.pin'.tr;

  static String get conversationUnpin => 'conversation.unpin'.tr;

  static String get conversationMute => 'conversation.mute'.tr;

  static String get conversationUnmute => 'conversation.unmute'.tr;

  // ==================== 联系人 ====================

  static String get contacts => 'contacts'.tr;

  static String get contactsEmpty => 'contacts.empty'.tr;

  static String get contactsSearch => 'contacts.search'.tr;

  static String get contactsNewFriends => 'contacts.new_friends'.tr;

  static String get contactsGroupChats => 'contacts.group_chats'.tr;

  static String get contactsTags => 'contacts.tags'.tr;

  static String get contactsAddFriend => 'contacts.add_friend'.tr;

  static String get contactsAddFriendTitle => 'contacts.add_friend_title'.tr;

  static String get contactsSearchUser => 'contacts.search_user'.tr;

  static String get contactsInputUserId => 'contacts.input_user_id'.tr;

  static String get contactsSendRequest => 'contacts.send_request'.tr;

  static String get contactsRequestSent => 'contacts.request_sent'.tr;

  static String get contactsRequestMessage => 'contacts.request_message'.tr;

  static String get contactsAcceptRequest => 'contacts.accept_request'.tr;

  static String get contactsRejectRequest => 'contacts.reject_request'.tr;

  static String get contactsRequestAccepted => 'contacts.request_accepted'.tr;

  static String get contactsRequestRejected => 'contacts.request_rejected'.tr;

  static String get contactsDeleteFriend => 'contacts.delete_friend'.tr;

  static String get contactsDeleteConfirm => 'contacts.delete_confirm'.tr;

  static String get contactsBlock => 'contacts.block'.tr;

  static String get contactsUnblock => 'contacts.unblock'.tr;

  static String get contactsRemark => 'contacts.remark'.tr;

  static String get contactsPhone => 'contacts.phone'.tr;

  // ==================== 个人资料 ====================

  static String get profileTitle => 'profile.title'.tr;

  static String get profileAvatar => 'profile.avatar'.tr;

  static String get profileNickname => 'profile.nickname'.tr;

  static String get profileId => 'profile.id'.tr;

  static String get profileGender => 'profile.gender'.tr;

  static String get profileBirthday => 'profile.birthday'.tr;

  static String get profileRegion => 'profile.region'.tr;

  static String get profileSignature => 'profile.signature'.tr;

  static String get profileQrCode => 'profile.qr_code'.tr;

  static String get profileSendMessage => 'profile.send_message'.tr;

  static String get profileVideoCall => 'profile.video_call'.tr;

  static String get profileMale => 'profile.male'.tr;

  static String get profileFemale => 'profile.female'.tr;

  static String get profileUnknown => 'profile.unknown'.tr;

  static String get profileEdit => 'profile.edit'.tr;

  static String get profileSave => 'profile.save'.tr;

  static String get profileSaved => 'profile.saved'.tr;

  // ==================== 搜索 ====================

  static String get searchTitle => 'search.title'.tr;

  static String get searchPlaceholder => 'search.placeholder'.tr;

  static String get searchHistory => 'search.history'.tr;

  static String get searchClearHistory => 'search.clear_history'.tr;

  static String get searchNoResult => 'search.no_result'.tr;

  static String get searchSearching => 'search.searching'.tr;

  static String get searchMessages => 'search.messages'.tr;

  static String get searchContacts => 'search.contacts'.tr;

  static String get searchGroups => 'search.groups'.tr;

  // ==================== 设置 ====================

  static String get settingsTitle => 'settings.title'.tr;

  static String get settingsAccount => 'settings.account'.tr;

  static String get settingsPrivacy => 'settings.privacy'.tr;

  static String get settingsNotification => 'settings.notification'.tr;

  static String get settingsGeneral => 'settings.general'.tr;

  static String get settingsAbout => 'settings.about'.tr;

  static String get settingsLanguage => 'settings.language'.tr;

  static String get settingsTheme => 'settings.theme'.tr;

  static String get settingsFontSize => 'settings.font_size'.tr;

  static String get settingsClearCache => 'settings.clear_cache'.tr;

  static String get settingsCacheCleared => 'settings.cache_cleared'.tr;

  static String get settingsVersion => 'settings.version'.tr;

  static String get settingsCheckUpdate => 'settings.check_update'.tr;

  static String get settingsLogoutConfirm => 'settings.logout_confirm'.tr;

  // ==================== 钱包 ====================

  static String get walletTitle => 'wallet.title'.tr;

  static String get walletBalance => 'wallet.balance'.tr;

  static String get walletTransfer => 'wallet.transfer'.tr;

  static String get walletReceive => 'wallet.receive'.tr;

  static String get walletTransactions => 'wallet.transactions'.tr;

  static String get walletCreate => 'wallet.create'.tr;

  static String get walletCreating => 'wallet.creating'.tr;

  static String get walletCreated => 'wallet.created'.tr;

  static String get walletAddress => 'wallet.address'.tr;

  static String get walletCopyAddress => 'wallet.copy_address'.tr;

  static String get walletCopied => 'wallet.copied'.tr;

  static String get walletToAddress => 'wallet.to_address'.tr;

  static String get walletAmount => 'wallet.amount'.tr;

  static String get walletFee => 'wallet.fee'.tr;

  static String get walletTotal => 'wallet.total'.tr;

  static String get walletInputAmount => 'wallet.input_amount'.tr;

  static String get walletInputAddress => 'wallet.input_address'.tr;

  static String get walletInvalidAmount => 'wallet.invalid_amount'.tr;

  static String get walletInvalidAddress => 'wallet.invalid_address'.tr;

  static String get walletInsufficientBalance =>
      'wallet.insufficient_balance'.tr;

  static String get walletTransferSuccess => 'wallet.transfer_success'.tr;

  static String get walletTransferFailed => 'wallet.transfer_failed'.tr;

  static String get walletPaymentSuccess => 'wallet.payment_success'.tr;

  static String get walletPaymentFailed => 'wallet.payment_failed'.tr;

  static String get walletConfirmTransfer => 'wallet.confirm_transfer'.tr;

  static String get walletConfirmPayment => 'wallet.confirm_payment'.tr;

  // ==================== 扫描 ====================

  static String get scanTitle => 'scan.title'.tr;

  static String get scanQrCode => 'scan.qr_code'.tr;

  static String get scanAlbum => 'scan.album'.tr;

  static String get scanFlash => 'scan.flash'.tr;

  static String get scanMyQr => 'scan.my_qr'.tr;

  // ==================== 时间相关 ====================

  static String get timeJustNow => 'time.just_now'.tr;

  static String timeMinutesAgo(int minutes) =>
      t('time.minutes_ago', args: [minutes.toString()]);

  static String timeHoursAgo(int hours) =>
      t('time.hours_ago', args: [hours.toString()]);

  static String get timeYesterday => 'time.yesterday'.tr;

  static String timeDaysAgo(int days) =>
      t('time.days_ago', args: [days.toString()]);

  static String timeWeeksAgo(int weeks) =>
      t('time.weeks_ago', args: [weeks.toString()]);

  static String timeMonthsAgo(int months) =>
      t('time.months_ago', args: [months.toString()]);

  static String timeYearsAgo(int years) =>
      t('time.years_ago', args: [years.toString()]);

  // ==================== 文件相关 ====================

  static String get fileImage => 'file.image'.tr;

  static String get fileVideo => 'file.video'.tr;

  static String get fileAudio => 'file.audio'.tr;

  static String get fileDocument => 'file.document'.tr;

  static String get fileTooLarge => 'file.too_large'.tr;

  static String get fileUpload => 'file.upload'.tr;

  static String get fileUploading => 'file.uploading'.tr;

  static String get fileUploadSuccess => 'file.upload_success'.tr;

  static String get fileUploadFailed => 'file.upload_failed'.tr;

  static String get fileDownload => 'file.download'.tr;

  static String get fileDownloading => 'file.downloading'.tr;

  static String get fileDownloadSuccess => 'file.download_success'.tr;

  static String get fileDownloadFailed => 'file.download_failed'.tr;

  // ==================== 权限相关 ====================

  static String get permissionCamera => 'permission.camera'.tr;

  static String get permissionCameraDesc => 'permission.camera_desc'.tr;

  static String get permissionPhoto => 'permission.photo'.tr;

  static String get permissionPhotoDesc => 'permission.photo_desc'.tr;

  static String get permissionMicrophone => 'permission.microphone'.tr;

  static String get permissionMicrophoneDesc => 'permission.microphone_desc'.tr;

  static String get permissionStorage => 'permission.storage'.tr;

  static String get permissionStorageDesc => 'permission.storage_desc'.tr;

  static String get permissionDenied => 'permission.denied'.tr;

  static String get permissionGoSettings => 'permission.go_settings'.tr;

  // ==================== 验证消息 ====================

  static String get validationRequired => 'validation.required'.tr;

  static String validationMinLength(int length) =>
      t('validation.min_length', args: [length.toString()]);

  static String validationMaxLength(int length) =>
      t('validation.max_length', args: [length.toString()]);

  static String get validationInvalidFormat => 'validation.invalid_format'.tr;

  static String get validationInvalidEmail => 'validation.invalid_email'.tr;

  static String get validationInvalidPhone => 'validation.invalid_phone'.tr;

  static String get validationInvalidUrl => 'validation.invalid_url'.tr;
}
