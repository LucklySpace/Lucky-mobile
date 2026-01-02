import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../utils/objects.dart';
import '../api/api_service.dart';
import '../core/handlers/error_handler.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import '../models/wallet_model.dart';
import '../services/nfc_service.dart';
import 'user_controller.dart';

class WalletController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final UserController _userController = Get.find<UserController>();

  // 依赖注入
  final _secureStorage = const FlutterSecureStorage();
  static const String _walletKeyPrefix = 'wallet_info_';

  final Rx<WalletVo?> wallet = Rx<WalletVo?>(null);
  final RxList<TransactionVo> transactions = <TransactionVo>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final Rx<FeeVo?> feeInfo = Rx<FeeVo?>(null);
  final RxString estimatedFee = '0.00000000'.obs;

  static const int _successCode = 200;

  @override
  void onInit() {
    super.onInit();
    if (_userController.userId.isNotEmpty) {
      loadWalletData();
    }
    fetchFeeInfo();
  }

  /// 加载钱包数据（信息 + 交易记录）
  Future<void> loadWalletData() async {
    if (_userController.userId.isEmpty) return;

    // 如果没有数据，先显示加载中，避免闪烁
    if (wallet.value == null) {
      isLoading.value = true;
    }

    await _loadWalletFromCache();

    // 如果缓存有数据，立即取消加载状态显示内容
    if (wallet.value != null) {
      isLoading.value = false;
    }

    try {
      await fetchWalletInfo();
      if (wallet.value != null) {
        await _saveWalletToCache();
      }
      if (wallet.value != null) {
        await fetchTransactions();
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取钱包信息
  Future<void> fetchWalletInfo() async {
    try {
      final res =
          await _apiService.getWalletByUser(_userController.userId.value);

      _handleApiResponse(res, onSuccess: (data) async {
        wallet.value = WalletVo.fromJson(data);
        await _saveWalletToCache();
      }, errorMessage: '获取钱包信息失败');
    } catch (e) {
      // 获取失败时尝试自动创建（处理钱包不存在的情况）
      ErrorHandler.handle(AppException('获取钱包信息失败，尝试自动创建', details: e),
          silent: true);
      try {
        await createWallet();
      } catch (ex) {
        // 创建也失败，置空
        wallet.value = null;
      }
    }
  }

  /// 获取手续费信息
  Future<void> fetchFeeInfo() async {
    final res = await _apiService.fee();
    _handleApiResponse(res, onSuccess: (data) {
      feeInfo.value = FeeVo.fromJson(data);
    }, errorMessage: '获取手续费信息失败');
  }
  String _formatAmount(double value) => value.toStringAsFixed(8);
  String calculateFee(String amount) {
    final info = feeInfo.value;
    final amt = double.tryParse(amount) ?? 0.0;
    if (info == null) return _formatAmount(0);
    final base = double.tryParse(info.fee) ?? 0.0;
    final val = info.feeMode == FeeMode.fixed ? base : amt * base;
    return _formatAmount(val);
  }
  void computeEstimatedFee(String amount) {
    estimatedFee.value = calculateFee(amount);
  }

  /// 创建钱包
  Future<void> createWallet() async {
    if (isCreating.value) return;
    isCreating.value = true;
    try {
      final res =
          await _apiService.createUserWallet(_userController.userId.value);

      _handleApiResponse(res, onSuccess: (data) async {
        wallet.value = WalletVo.fromJson(data);
        await _saveWalletToCache();
        Get.snackbar('成功', '钱包创建成功', snackPosition: SnackPosition.BOTTOM);
      }, errorMessage: '创建钱包失败');
    } catch (e) {
      _showError('创建钱包失败: $e');
    } finally {
      isCreating.value = false;
    }
  }

  /// 获取交易记录
  Future<void> fetchTransactions({int page = 0, int size = 20}) async {
    if (wallet.value == null) return;
    try {
      final res = await _apiService.getTransactionsByAddress(
        wallet.value!.address,
        page,
        size,
      );

      _handleApiResponse(res, onSuccess: (data) {
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['content'] is List) {
          list = data['content'];
        }

        if (page == 0) {
          transactions
              .assignAll(list.map((e) => TransactionVo.fromJson(e)).toList());
        } else {
          transactions
              .addAll(list.map((e) => TransactionVo.fromJson(e)).toList());
        }
      }, errorMessage: '获取交易记录失败');
    } catch (e) {
      ErrorHandler.handle(AppException('获取交易记录失败', details: e), silent: true);
    }
  }

  /// 转账
  Future<bool> transfer({
    required String toAddress,
    required String amount,
  }) async {
    if (wallet.value == null) return false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nonce = wallet.value!.nonce + 1;

      final data = {
        'from': wallet.value!.address,
        'to': toAddress,
        'amount': amount,
        'timestamp': timestamp,
        'nonce': nonce,
        'signature': 'simulated_signature',
      };

      final res = await _apiService.transfer(data);

      _handleApiResponse(res, onSuccess: (data) {
        loadWalletData(); // 刷新余额
        Get.toNamed('${Routes.HOME}${Routes.WALLET_RESULT}', arguments: {
          'success': true,
          'title': '转账成功',
          'amount': amount,
          'toAddress': toAddress,
          'transactionId':
              data is Map ? (data['transactionId'] ?? data['txId']) : null,
        });
      }, errorMessage: '转账失败');

      return true;
    } catch (e) {
      Get.toNamed('${Routes.HOME}${Routes.WALLET_RESULT}', arguments: {
        'success': false,
        'title': '转账失败',
        'amount': amount,
        'errorMessage': e is BusinessException ? e.message : '转账发生错误',
      });
      _showError('转账失败: $e');
      return false;
    }
  }

  /// 支付
  Future<bool> pay({
    required String toAddress,
    required String amount,
  }) async {
    if (wallet.value == null) return false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nonce = wallet.value!.nonce + 1;

      final data = {
        'from': wallet.value!.address,
        'to': toAddress,
        'amount': amount,
        'timestamp': timestamp,
        'nonce': nonce,
        'signature': 'simulated_signature',
      };

      final res = await _apiService.pay(data);

      _handleApiResponse(res, onSuccess: (data) {
        loadWalletData(); // 刷新余额
        final transactionId = data is Map
            ? Objects.safeGet<String>(data, 'transactionId') ??
                Objects.safeGet<String>(data, 'txId')
            : null;

        Get.toNamed('${Routes.HOME}${Routes.WALLET_RESULT}', arguments: {
          'success': true,
          'title': '支付成功',
          'amount': amount,
          'toAddress': toAddress,
          'transactionId': transactionId,
        });
      }, errorMessage: '支付失败');

      return true;
    } catch (e) {
      Get.toNamed('${Routes.HOME}${Routes.WALLET_RESULT}', arguments: {
        'success': false,
        'title': '支付失败',
        'amount': amount,
        'errorMessage': e is BusinessException ? e.message : '支付发生错误',
      });
      _showError('支付失败: $e');
      return false;
    }
  }

  /// 保存钱包到缓存
  Future<void> _saveWalletToCache() async {
    final w = wallet.value;
    if (w == null || _userController.userId.isEmpty) return;
    final key = '$_walletKeyPrefix${_userController.userId.value}';
    await _secureStorage.write(key: key, value: jsonEncode(w.toJson()));
  }

  /// 从缓存加载钱包数据
  Future<void> _loadWalletFromCache() async {
    if (_userController.userId.isEmpty) return;
    final key = '$_walletKeyPrefix${_userController.userId.value}';
    try {
      final data = await _secureStorage.read(key: key);
      if (data != null && data.isNotEmpty) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        wallet.value = WalletVo.fromJson(map);
      }
    } catch (e) {
      ErrorHandler.handle(AppException('加载钱包缓存失败', details: e), silent: true);
    }
  }

  /// 确认收款
  Future<bool> confirmTransaction(String txId) async {
    if (wallet.value == null) return false;
    try {
      final res = await _apiService.confirmPayment(txId, wallet.value!.address);
      _handleApiResponse(res, onSuccess: (_) {
        Get.snackbar('成功', '收款确认成功', snackPosition: SnackPosition.BOTTOM);
        loadWalletData();
      }, errorMessage: '确认失败');
      return true;
    } catch (e) {
      _showError('确认收款失败: $e');
      return false;
    }
  }

  /// 退回转账
  Future<bool> returnTransaction(String txId) async {
    if (wallet.value == null) return false;
    try {
      final res = await _apiService.returnPayment(txId, wallet.value!.address);
      _handleApiResponse(res, onSuccess: (_) {
        Get.snackbar('成功', '退回成功', snackPosition: SnackPosition.BOTTOM);
        loadWalletData();
      }, errorMessage: '退回失败');
      return true;
    } catch (e) {
      _showError('退回失败: $e');
      return false;
    }
  }

  // --- 页面导航逻辑 ---

  /// 打开转账页面
  void openTransferPage() {
    Get.toNamed('${Routes.HOME}${Routes.TRANSFER}');
  }

  /// 打开收款页面
  void openReceivePage() {
    Get.toNamed('${Routes.HOME}${Routes.WALLET_RECEIVE}');
  }

  /// 打开交易详情
  void openTransactionDetail(TransactionVo tx) {
    Get.toNamed('${Routes.HOME}${Routes.TRANSACTION_DETAIL}', arguments: tx);
  }

  /// 处理 NFC 支付
  void handleNfcPayment(PaymentIntent intent) {
    Get.toNamed(
      '${Routes.HOME}${Routes.PAYMENT}',
      arguments: {
        'toAddress': intent.address,
        'amount': intent.amount,
      },
    );
  }

  /// 统一处理 API 响应
  void _handleApiResponse(
    Map<String, dynamic>? response, {
    required void Function(dynamic) onSuccess,
    required String errorMessage,
  }) {
    final code = Objects.safeGet<int>(response, 'code');
    if (code == _successCode) {
      return onSuccess(response?['data']);
    }
    final msg = Objects.safeGet<String>(response, 'message', errorMessage);
    throw BusinessException(msg.toString());
  }

  /// 显示错误提示
  void _showError(dynamic error) {
    ErrorHandler.handle(error);
  }
}
