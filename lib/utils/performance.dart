import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// 性能优化工具类
///
/// 提供防抖、节流、批处理等性能优化功能
class Performance {
  // 私有构造函数，防止实例化
  Performance._();

  // ==================== 防抖（Debounce） ====================

  /// 防抖函数
  ///
  /// 在连续触发事件时，只有在事件停止触发后的一段时间才执行函数
  ///
  /// 使用场景：
  /// - 搜索输入框（用户停止输入后才发起请求）
  /// - 窗口调整大小
  /// - 表单验证
  ///
  /// 示例：
  /// ```dart
  /// final debouncedSearch = Performance.debounce(
  ///   (String query) => searchApi(query),
  ///   duration: Duration(milliseconds: 500),
  /// );
  /// // 用户快速输入时，只有最后一次输入会触发搜索
  /// debouncedSearch('hello');
  /// ```
  static Function debounce(
    Function func, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    Timer? timer;

    return (List<dynamic> args) {
      // 取消之前的定时器
      timer?.cancel();

      // 创建新的定时器
      timer = Timer(duration, () {
        Function.apply(func, args);
      });
    };
  }

  // ==================== 节流（Throttle） ====================

  /// 节流函数
  ///
  /// 在指定时间内，无论触发多少次事件，只执行一次函数
  ///
  /// 使用场景：
  /// - 滚动事件监听
  /// - 按钮点击（防止重复提交）
  /// - 鼠标移动事件
  ///
  /// 示例：
  /// ```dart
  /// final throttledScroll = Performance.throttle(
  ///   () => loadMoreData(),
  ///   duration: Duration(milliseconds: 1000),
  /// );
  /// // 在1秒内，无论调用多少次，只执行一次
  /// throttledScroll();
  /// ```
  static Function throttle(
    Function func, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    DateTime? lastExecuted;

    return (List<dynamic> args) {
      final now = DateTime.now();

      if (lastExecuted == null ||
          now.difference(lastExecuted!).compareTo(duration) >= 0) {
        lastExecuted = now;
        Function.apply(func, args);
      }
    };
  }

  // ==================== 批处理（Batch） ====================

  /// 批处理执行器
  ///
  /// 收集多个操作，批量执行以提升性能
  ///
  /// 使用场景：
  /// - 批量数据库插入
  /// - 批量网络请求
  /// - 批量UI更新
  static Future<void> batchExecute<T>(
    List<T> items,
    Future<void> Function(T) operation, {
    int batchSize = 50,
    Duration? delay,
  }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);

      // 并行执行批次内的操作
      await Future.wait(batch.map((item) => operation(item)));

      // 可选：批次之间添加延迟，避免阻塞UI
      if (delay != null && i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }
  }

  // ==================== 异步操作优化 ====================

  /// 在Isolate中执行计算密集型任务
  ///
  /// 避免阻塞主线程（UI线程）
  ///
  /// 使用场景：
  /// - JSON解析
  /// - 图片处理
  /// - 加密解密
  /// - 大量数据计算
  ///
  /// 示例：
  /// ```dart
  /// final result = await Performance.compute(
  ///   heavyCalculation,
  ///   params: {'data': largeDataSet},
  /// );
  /// ```
  static Future<R> compute<M, R>(
    ComputeCallback<M, R> callback,
    M message, {
    String? debugLabel,
  }) async {
    return await compute<M, R>(callback, message, debugLabel: debugLabel);
  }

  // ==================== 延迟加载 ====================

  /// 延迟执行函数
  ///
  /// 将任务推迟到下一帧执行，避免阻塞当前帧
  ///
  /// 使用场景：
  /// - 页面初始化后加载非关键数据
  /// - 动画完成后执行操作
  static Future<void> defer(Function func, {Duration? delay}) async {
    if (delay != null) {
      await Future.delayed(delay);
    } else {
      await Future.delayed(Duration.zero);
    }
    func();
  }

  /// 在下一帧执行函数
  static void nextFrame(Function func) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      func();
    });
  }

  // ==================== 内存管理 ====================

  /// 弱引用缓存
  ///
  /// 当内存不足时,缓存的数据会被自动清理
  ///
  /// 注意：Flutter暂时不支持弱引用，这里提供接口设计
  static final Map<String, dynamic> _cache = {};

  /// 设置缓存
  static void setCache(String key, dynamic value) {
    _cache[key] = value;
  }

  /// 获取缓存
  static dynamic getCache(String key) {
    return _cache[key];
  }

  /// 清除缓存
  static void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  // ==================== 性能监控 ====================

  /// 性能计时器
  ///
  /// 测量代码执行时间
  ///
  /// 示例：
  /// ```dart
  /// final stopwatch = Performance.startTimer('数据处理');
  /// // 执行耗时操作
  /// processData();
  /// Performance.stopTimer(stopwatch, '数据处理');
  /// // 输出：[性能] 数据处理 耗时: 123ms
  /// ```
  static Stopwatch startTimer([String? label]) {
    final stopwatch = Stopwatch()..start();
    if (label != null) {
      debugPrint('[性能] $label 开始...');
    }
    return stopwatch;
  }

  /// 停止计时器并输出结果
  static void stopTimer(Stopwatch stopwatch, [String? label]) {
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    final labelStr = label ?? '操作';
    debugPrint('[性能] $labelStr 耗时: ${elapsed}ms');
  }

  /// 执行并测量时间
  static Future<T> measure<T>(
    String label,
    Future<T> Function() func,
  ) async {
    final stopwatch = startTimer(label);
    try {
      return await func();
    } finally {
      stopTimer(stopwatch, label);
    }
  }
}

/// 防抖控制器
///
/// 更灵活的防抖实现，支持取消、重置等操作
class DebounceController {
  final Duration duration;
  Timer? _timer;

  DebounceController({
    this.duration = const Duration(milliseconds: 500),
  });

  /// 执行函数
  void call(Function func, [List<dynamic> args = const []]) {
    cancel();
    _timer = Timer(duration, () => Function.apply(func, args));
  }

  /// 取消待执行的函数
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 是否有待执行的函数
  bool get isActive => _timer?.isActive ?? false;

  /// 释放资源
  void dispose() {
    cancel();
  }
}

/// 节流控制器
///
/// 更灵活的节流实现，支持立即执行等选项
class ThrottleController {
  final Duration duration;
  final bool leading; // 是否在开始时立即执行
  final bool trailing; // 是否在结束时执行

  DateTime? _lastExecuted;
  Timer? _trailingTimer;

  ThrottleController({
    this.duration = const Duration(milliseconds: 1000),
    this.leading = true,
    this.trailing = false,
  });

  /// 执行函数
  void call(Function func, [List<dynamic> args = const []]) {
    final now = DateTime.now();
    final shouldExecute = _lastExecuted == null ||
        now.difference(_lastExecuted!).compareTo(duration) >= 0;

    if (shouldExecute) {
      if (leading) {
        Function.apply(func, args);
        _lastExecuted = now;
      }

      if (trailing) {
        _trailingTimer?.cancel();
        _trailingTimer = Timer(duration, () => Function.apply(func, args));
      }
    }
  }

  /// 重置状态
  void reset() {
    _lastExecuted = null;
    _trailingTimer?.cancel();
    _trailingTimer = null;
  }

  /// 释放资源
  void dispose() {
    _trailingTimer?.cancel();
  }
}
