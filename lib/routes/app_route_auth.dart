import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/controller/user_controller.dart';
import 'app_routes.dart';

/// 路由鉴权中间件
class RouteAuthMiddleware extends GetMiddleware {
  @override
  //需要实现系统的该方法
  RouteSettings? redirect(String? route) {
    UserController userController = Get.find<UserController>();
    String token = userController.token.value;
    //根据条件进行判断,满足条件进行跳转,否则不进行跳转（return null）

    if (token.isNotEmpty && token != '') {
      return null; // 表示跳转到目标路由
    }

    Get.log('❌  token is empty,goto login: $token');
    return RouteSettings(name: Routes.LOGIN); // 同时传参
  }
}
