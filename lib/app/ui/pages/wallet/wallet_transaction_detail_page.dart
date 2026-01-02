import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controller/wallet_controller.dart';
import '../../../models/wallet_model.dart';

class WalletTransactionDetailPage extends GetView<WalletController> {
  const WalletTransactionDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TransactionVo transaction = Get.arguments;
    // 使用 Obx 监听钱包地址变化，虽然进入详情页时钱包通常已加载，但为了安全起见
    // 这里直接取值也可以，因为 controller 是全局的
    final isReceive =
        transaction.receiverAddress == controller.wallet.value?.address;

    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易详情'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSizes.spacing20),
            Icon(
              _getTransactionIcon(transaction, isReceive),
              size: AppSizes.spacing64,
              color: isReceive ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              _getTransactionTitle(transaction, isReceive),
              style: const TextStyle(fontSize: AppSizes.font18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              '${isReceive ? '+' : '-'}${transaction.amount} COIN',
              style: TextStyle(
                fontSize: AppSizes.font32,
                fontWeight: FontWeight.bold,
                color: isReceive ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12, vertical: AppSizes.spacing4),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.statusEnum).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Text(
                transaction.statusEnum.description,
                style: TextStyle(
                  color: _getStatusColor(transaction.statusEnum),
                  fontSize: AppSizes.font12,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing40),
            _buildDetailItem('交易时间', _formatDate(transaction.timestamp)),
            _buildDetailItem('交易类型', transaction.typeEnum.description),
            _buildDetailItem('手续费', '${transaction.fee} COIN'),
            _buildDetailItem('交易ID', transaction.transactionId, copyable: true),
            _buildDetailItem('发款方', transaction.senderAddress, copyable: true),
            _buildDetailItem('收款方', transaction.receiverAddress,
                copyable: true),
            if (transaction.blockHash != null &&
                transaction.blockHash!.isNotEmpty)
              _buildDetailItem('区块哈希', transaction.blockHash!, copyable: true),

            const SizedBox(height: AppSizes.spacing40),

            // 操作按钮：仅当我是接收方时显示
            if (isReceive) ...[
              // 如果是待确认状态，显示确认收款
              if (transaction.statusEnum == TransactionStatus.awaitConfirm)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _confirmTransaction(transaction.transactionId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12)),
                    ),
                    child: const Text('确认收款'),
                  ),
                ),
              const SizedBox(height: AppSizes.spacing16),
              if (_canReturn(transaction))
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        _returnTransaction(transaction.transactionId),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12)),
                    ),
                    child:
                        const Text('退回转账', style: TextStyle(color: AppColors.error)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.spacing80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                Get.showSnackbar(const GetSnackBar(
                  message: '已复制',
                  duration: Duration(seconds: 1),
                ));
              },
              child: const Padding(
                padding: EdgeInsets.only(left: AppSizes.spacing8),
                child: Icon(Icons.copy,
                    size: AppSizes.iconSmall, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  String _getTransactionTitle(TransactionVo tx, bool isReceive) {
    if (tx.typeEnum == TransactionType.transfer) {
      return isReceive ? '收到转账' : '转账支出';
    }
    return tx.typeEnum.description;
  }

  IconData _getTransactionIcon(TransactionVo tx, bool isReceive) {
    switch (tx.typeEnum) {
      case TransactionType.transfer:
        return isReceive ? Icons.arrow_downward : Icons.arrow_upward;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.fee:
        return Icons.remove_circle_outline;
      case TransactionType.reward:
        return Icons.card_giftcard;
      default:
        return isReceive ? Icons.arrow_downward : Icons.arrow_upward;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return AppColors.success;
      case TransactionStatus.awaitConfirm:
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.failed:
      case TransactionStatus.returned:
      case TransactionStatus.cancelled:
      case TransactionStatus.expired:
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  bool _canReturn(TransactionVo tx) {
    final now = DateTime.now();
    final created = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
    final diff = now.difference(created);
    return diff <= const Duration(hours: 2);
  }

  void _confirmTransaction(String txId) {
    Get.defaultDialog(
      title: '确认收款',
      middleText: '确定要确认这笔收款吗？',
      textConfirm: '确认',
      textCancel: '取消',
      confirmTextColor: AppColors.white,
      onConfirm: () async {
        Get.back();
        final success = await controller.confirmTransaction(txId);
        if (success) {
          Get.back(); // 返回列表页
        }
      },
    );
  }

  void _returnTransaction(String txId) {
    Get.defaultDialog(
      title: '退回转账',
      middleText: '确定要退回这笔转账吗？此操作不可撤销。',
      textConfirm: '确认退回',
      textCancel: '取消',
      confirmTextColor: AppColors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        Get.back();
        final success = await controller.returnTransaction(txId);
        if (success) {
          Get.back(); // 返回列表页
        }
      },
    );
  }
}
