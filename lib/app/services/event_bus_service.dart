import 'package:get/get.dart';

///
/// 事件总线
/// https://www.bytezonex.com/archives/WRhf48iU.html
///
class EventBus extends GetxService {
  final Map<String, List<Function>> _eventMap = {};

  /// 注册事件监听器
  void on(String eventName, Function callback) {
    _eventMap.putIfAbsent(eventName, () => []);
    _eventMap[eventName]!.add(callback);
  }

  /// 注册一次性监听器，触发一次后自动移除
  void once(String eventName, Function callback) {
    void wrapper(dynamic data) {
      callback(data);
      off(eventName, wrapper);
    }

    on(eventName, wrapper);
  }

  /// 注销事件监听器
  /// 如果传入了 callback 则注销指定监听器，
  /// 否则清空该事件所有监听器
  void off(String eventName, [Function? callback]) {
    if (_eventMap.containsKey(eventName)) {
      if (callback != null) {
        _eventMap[eventName]!.remove(callback);
      } else {
        _eventMap[eventName]!.clear();
      }
    }
  }

  /// 触发事件，将 data 传递给所有注册的监听器
  void emit(String eventName, [dynamic data]) {
    if (_eventMap.containsKey(eventName)) {
      // 复制列表，防止在遍历过程中有修改导致异常
      final List<Function> callbacks = List.from(_eventMap[eventName]!);
      for (var callback in callbacks) {
        callback(data);
      }
    }
  }

  /// 问答模式：向指定事件发送请求并等待响应
  ///
  /// 参数：
  /// - [eventName]：要触发的事件名称
  /// - [data]：要传递的数据
  /// - [timeout]：等待响应的超时时间（默认 5 秒）
  /// - [singleResponse]：如果为 true，则仅返回第一个监听器的响应，否则返回所有响应的列表
  ///
  /// 如果监听器返回的是 Future，则会自动等待其完成；如果不是 Future，
  /// 则会包装成 Future。
  Future<dynamic> ask(
    String eventName, [
    dynamic data,
    Duration timeout = const Duration(seconds: 5),
    bool singleResponse = false,
  ]) async {
    if (!_eventMap.containsKey(eventName) || _eventMap[eventName]!.isEmpty) {
      return null;
    }
    if (singleResponse) {
      var callback = _eventMap[eventName]!.first;
      var result = callback(data);
      if (result is Future) {
        return await result.timeout(timeout);
      } else {
        return result;
      }
    } else {
      List<Future<dynamic>> futures = [];
      for (var callback in _eventMap[eventName]!) {
        try {
          var result = callback(data);
          if (result is Future) {
            futures.add(result.timeout(timeout));
          } else {
            futures.add(Future.value(result));
          }
        } catch (e) {
          futures.add(Future.error(e));
        }
      }
      return await Future.wait(futures).timeout(timeout);
    }
  }

  /// 判断指定事件是否有注册的监听器
  bool has(String eventName) {
    return _eventMap.containsKey(eventName) && _eventMap[eventName]!.isNotEmpty;
  }

  /// 清空所有注册的事件监听器
  void clear() {
    _eventMap.clear();
  }
}

// 使用说明
// 注册和触发事件
// 使用 on 方法注册监听器，使用 emit 方法触发事件：
// EventBus.getInstance().on("update", (data) {
// print("Received update: $data");
// });
// EventBus.getInstance().emit("update", "Hello, world!");

// 一次性监听器
// 使用 once 注册只响应一次的监听器：
// EventBus.getInstance().once("login", (user) {
// print("User logged in: $user");
// });

// 问答模式
// 使用 ask 方法来发送请求并等待响应：
// // 注册监听器，支持同步或异步返回结果
// EventBus.getInstance().on("query", (data) {
// // 可以直接返回结果，也可以返回 Future
// return "Result for $data";
// });

// // 获取所有监听器的响应（多响应模式）
// EventBus.getInstance().ask("query", "my question").then((responses) {
// print("Received responses: $responses");
// });

// // 仅获取第一个响应（单响应模式）
// EventBus.getInstance().ask("query", "my question", Duration(seconds: 3), true)
//     .then((response) {
// print("Received first response: $response");
// });
