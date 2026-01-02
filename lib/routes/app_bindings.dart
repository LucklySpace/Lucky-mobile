import 'package:flutter_im/app/controller/wallet_controller.dart';
import 'package:flutter_im/app/services/nfc_service.dart';
import 'package:get/get.dart';

import '../app/api/api_service.dart';
import '../app/services/event_bus_service.dart';
import '../app/services/notification_service.dart';
import '../app/services/websocket_service.dart';
import '../app/controller/chat_controller.dart';
import '../app/controller/contact_controller.dart';
import '../app/controller/home_controller.dart';
import '../app/controller/login_controller.dart';
import '../app/controller/search_controller.dart';
import '../app/controller/user_controller.dart';

class AppAllBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(EventBus()); // 注入事务总线
    Get.put(ApiService()); // ✅ 这里注入 HttpService
    Get.put(WebSocketService()); // ✅ 注入 websocket
    Get.put(NfcService(), permanent: true);
    Get.put(LocalNotificationService());

    Get.put(ContactController(), permanent: true);

    Get.put(ChatController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(HomeController(), permanent: true);

    Get.put(WalletController(), permanent: true);
   
    Get.put(SearchController());
    Get.put(LoginController());
  }
}
