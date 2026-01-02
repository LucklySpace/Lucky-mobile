import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../app/ui/pages/contacts/add_friend_page.dart';
import '../app/ui/pages/contacts/friend_requests_page.dart';
import '../app/ui/pages/friend/friend_profile_page.dart';
import '../app/ui/pages/home/home_page.dart';
import '../app/ui/pages/login/login_page.dart';
import '../app/ui/pages/message/chat_info_page.dart';
import '../app/ui/pages/message/message_page.dart';
import '../app/ui/pages/my/my_qr_code_page.dart';
import '../app/ui/pages/scan/scan_page.dart';
import '../app/ui/pages/search/search_page.dart';
import '../app/ui/pages/my/user_profile_page.dart';
import '../app/ui/pages/unknow/unknown_page.dart';
import '../app/ui/pages/video/video_call_page.dart';
import '../app/ui/pages/wallet/wallet_payment_page.dart';
import '../app/ui/pages/wallet/wallet_transfer_page.dart';
import '../app/ui/pages/wallet/wallet_transaction_detail_page.dart';
import '../app/ui/pages/wallet/wallet_result_page.dart';
import '../app/ui/pages/wallet/wallet_receive_page.dart';
import '../app/ui/pages/webview/webview_page.dart';
import '../app/ui/pages/wallet/wallet_page.dart';
import 'app_route_auth.dart';
import 'app_routes.dart';

/// 应用路由配置，定义所有页面路由及其子路由
/// 特性：
/// - 配置根路由（如登录、首页、WebView）和首页子路由（如消息、聊天信息）。
/// - 支持登录验证中间件，保护需要认证的页面。
/// - 提供未知路由处理，显示 404 页面。
/// - 统一页面过渡动画（300ms，easeInOut 曲线），增强用户体验。
class AppPages {
  // 常量定义
  static const initial = Routes.LOGIN; // 默认路由：登录页面
  static const _defaultTransitionDuration =
      Duration(milliseconds: 300); // 默认过渡动画时长
  static const _defaultCurve = Curves.easeInOut; // 默认过渡动画曲线

  /// 根路由列表
  static final rootRoutes = <GetPage>[
    /// 登录页面：用户登录界面
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// WebView 页面：展示外部网页内容
    GetPage(
      name: Routes.WEB_VIEW,
      page: () => const WebViewPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 首页：应用主界面，包含消息、通讯录等功能入口
    GetPage(
      name: Routes.HOME,
      page: () => const HomePage(),
      middlewares: [
        RouteAuthMiddleware(), // 登录验证中间件，未登录时跳转到登录页面
      ],
      children: homeChildRoutes,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
  ];

  /// 首页子路由列表
  static final homeChildRoutes = <GetPage>[
    // /// 会话页面：显示用户聊天会话列表（未启用）
    // GetPage(
    //   name: Routes.CHAT,
    //   page: () => const ChatPage(),
    //   transitionDuration: _defaultTransitionDuration,
    //   curve: _defaultCurve,
    // ),

    /// 消息页面：显示具体聊天会话的消息列表和输入框
    GetPage(
      name: Routes.MESSAGE,
      page: () => MessagePage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 聊天信息页面：显示用户或群聊的详细信息（如头像、名称、免打扰设置）
    GetPage(
      name: Routes.CHAT_INFO,
      page: () => ChatInfoPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 添加好友页面：搜索和添加新好友
    GetPage(
      name: Routes.ADD_FRIEND,
      page: () => AddFriendPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    // /// 通讯录页面：显示联系人列表（未启用）
    // GetPage(
    //   name: Routes.CONTACTS,
    //   page: () => const ContactsPage(),
    //   transitionDuration: _defaultTransitionDuration,
    //   curve: _defaultCurve,
    // ),

    /// 好友资料页面：显示好友的详细信息
    GetPage(
      name: Routes.FRIEND_PROFILE,
      page: () => const FriendProfilePage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 我的二维码页面：展示用户二维码以便添加好友
    GetPage(
      name: Routes.MY_QR_CODE,
      page: () => const MyQRCodePage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 好友请求页面：处理收到的好友请求
    GetPage(
      name: Routes.FRIEND_REQUESTS,
      page: () => const FriendRequestsPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 扫一扫页面：扫描二维码添加好友或处理其他操作
    GetPage(
      name: Routes.SCAN,
      page: () => const ScanPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 搜索页面：搜索用户、群聊或消息
    GetPage(
      name: Routes.SEARCH,
      page: () => const SearchPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 用户资料页面
    GetPage(
      name: Routes.USER_PROFILE,
      page: () => const UserProfilePage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 视频通话页面
    GetPage(
      name: Routes.VIDEO_CALL,
      page: () => const VideoCallPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 钱包页面
    GetPage(
      name: Routes.WALLET,
      page: () => const WalletPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 转账页面
    GetPage(
      name: Routes.TRANSFER,
      page: () => const WalletTransferPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 支付页面
    GetPage(
      name: Routes.PAYMENT,
      page: () => const WalletPaymentPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 交易详情页面
    GetPage(
      name: Routes.TRANSACTION_DETAIL,
      page: () => const WalletTransactionDetailPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 交易结果页面
    GetPage(
      name: Routes.WALLET_RESULT,
      page: () => const WalletResultPage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),

    /// 收款页面
    GetPage(
      name: Routes.WALLET_RECEIVE,
      page: () => const WalletReceivePage(),
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
  ];

  /// 未知路由：处理无效路由，显示 404 页面
  static final unknownRoute = GetPage(
    name: Routes.UNKNOWN,
    page: () => const UnknownView(),
    transitionDuration: _defaultTransitionDuration,
    curve: _defaultCurve,
  );
}
