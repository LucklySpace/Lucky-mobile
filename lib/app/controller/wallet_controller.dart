import 'dart:convert';

import 'package:flutter_im/app/core/base/base_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../models/wallet_model.dart';
import 'user_controller.dart';

/// 钱包控制器
class WalletController extends BaseController {
  // ==================== 常量定义 ====================
  static const String _walletKeyPrefix = 'wallet_info_';
  static const int _decimalPlaces = 8;

  // ==================== 依赖注入 ====================
  final UserController _userController = Get.find<UserController>();
  final _secureStorage = const FlutterSecureStorage();

  // ==================== 响应式状态 ====================
  final Rx<WalletVo?> wallet = Rx<WalletVo?>(null);
  final RxList<TransactionVo> transactions = <TransactionVo>[].obs;
  final RxBool isCreating = false.obs;
  final Rx<FeeVo?> feeInfo = Rx<FeeVo?>(null);
  final RxString estimatedFee = '0.00000000'.obs;

  @override
  void onInit() {
    super.onInit();
    if (_userController.userId.isNotEmpty) {
      loadWalletData();
    }
    fetchFeeInfo();
  }

  // ==================== 钱包数据管理 ====================

  Future<void> loadWalletData() async {
    if (_userController.userId.isEmpty) return;
    if (wallet.value == null) isLoading.value = true;

    await _loadWalletFromCache();
    if (wallet.value != null) isLoading.value = false;

    try {
      await fetchWalletInfo();
      if (wallet.value != null) {
        await _saveWalletToCache();
        await fetchTransactions();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWalletInfo() async {
    final response =
        await apiService.getWalletByUser(_userController.userId.value);
    handleApiResponse(response, onSuccess: (data) async {
      wallet.value = data;
      await _saveWalletToCache();
    }, showError: false);
  }

  Future<void> createWallet(String password) async {
    if (isCreating.value) return;
    final response = await apiService.createWallet({'password': password});
    handleApiResponse(response, onSuccess: (data) async {
      wallet.value = data;
      await _saveWalletToCache();
      showSuccess('钱包创建成功');
    }, showError: true);
  }

  Future<void> fetchTransactions({int page = 0, int size = 20}) async {
    if (wallet.value == null) return;
    final response = await apiService.getTransactionsByAddress(
      wallet.value!.address,
      {'page': page, 'size': size},
    );
    handleApiResponse(response, onSuccess: (data) {
      if (page == 0) transactions.clear();
      transactions.addAll(data);
    }, showError: true);
  }

  // ==================== 手续费管理 ====================

  Future<void> fetchFeeInfo() async {
    final response = await apiService.fee();
    handleApiResponse(response, onSuccess: (data) {
      feeInfo.value = data;
    }, showError: false);
  }

  String calculateFee(String amount) {
    final info = feeInfo.value;
    if (info == null) return _formatAmount(0);
    final amt = double.tryParse(amount) ?? 0.0;
    final base = double.tryParse(info.fee) ?? 0.0;
    final fee = info.feeMode == FeeMode.fixed ? base : amt * base;
    return _formatAmount(fee);
  }

  void computeEstimatedFee(String amount) {
    estimatedFee.value =
        amount.isEmpty ? _formatAmount(0) : calculateFee(amount);
  }

  String _formatAmount(double value) => value.toStringAsFixed(_decimalPlaces);

  // ==================== 转账和支付 ====================

  Future<void> transfer(
      {required String toAddress,
      required String amount,
      String? signature}) async {
    if (!validateNotEmpty(toAddress, fieldName: '接收方地址') ||
        !validateNotEmpty(amount, fieldName: '转账金额')) return;
    if (wallet.value == null) {
      showError('钱包未初始化');
      return;
    }

    final fee = calculateFee(amount);
    final response = await apiService.transfer({
      'from': wallet.value!.address,
      'to': toAddress,
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'nonce': wallet.value!.nonce + 1,
      'fee': fee,
      'signature': signature ?? '',
    });
    handleApiResponse(response, onSuccess: (data) async {
      showSuccess('转账成功');
      await fetchTransactions(page: 0);
    }, showError: true);
  }

  Future<void> confirmPayment(String txId, String receiverAddress) async {
    final response = await apiService.confirmPayment({
      'txId': txId,
      'receiverAddress': receiverAddress,
    });
    handleApiResponse(response, onSuccess: (data) async {
      showSuccess('确认收款成功');
      await fetchTransactions(page: 0);
    }, showError: true);
  }

  Future<void> returnPayment(String txId, String receiverAddress) async {
    final response = await apiService.returnPayment({
      'txId': txId,
      'receiverAddress': receiverAddress,
    });
    handleApiResponse(response, onSuccess: (data) async {
      showSuccess('转账已退回');
      await fetchTransactions(page: 0);
    }, showError: true);
  }

  Future<void> cancelPayment(String txId, String senderAddress) async {
    final response = await apiService.cancelPayment({
      'txId': txId,
      'senderAddress': senderAddress,
    });
    handleApiResponse(response, onSuccess: (data) async {
      showSuccess('转账已取消');
      await fetchTransactions(page: 0);
    }, showError: true);
  }

  // ==================== 缓存管理 ====================

  Future<void> _loadWalletFromCache() async {
    try {
      final key = '$_walletKeyPrefix${_userController.userId.value}';
      final cachedJson = await _secureStorage.read(key: key);
      if (cachedJson != null) {
        wallet.value = WalletVo.fromJson(jsonDecode(cachedJson));
      }
    } catch (e) {}
  }

  Future<void> _saveWalletToCache() async {
    if (wallet.value == null) return;
    try {
      final key = '$_walletKeyPrefix${_userController.userId.value}';
      final json = jsonEncode(wallet.value!.toJson());
      await _secureStorage.write(key: key, value: json);
    } catch (e) {}
  }

  Future<void> clearWalletCache() async {
    try {
      final key = '$_walletKeyPrefix${_userController.userId.value}';
      await _secureStorage.delete(key: key);
    } catch (e) {}
  }

  // ==================== 便捷方法 ====================

  Future<void> refreshData() async {
    await Future.wait([
      fetchWalletInfo(),
      fetchTransactions(page: 0),
      fetchFeeInfo(),
    ]);
  }

  String get formattedBalance => wallet.value?.balance ?? '0.00000000';

  String get formattedFrozenBalance =>
      wallet.value?.frozenBalance ?? '0.00000000';

  String? get walletAddress => wallet.value?.address;

  bool get hasWallet => wallet.value != null;

  void openTransactionDetail(TransactionVo tx) {}

  void openReceivePage() {}

  void openTransferPage() {}

  Future<void> pay({required String toAddress, required String amount}) async {}

  Future confirmTransaction(String txId) async {}

  Future returnTransaction(String txId) async {}
}
