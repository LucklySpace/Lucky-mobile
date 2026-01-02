import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_im/utils/date.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_constant.dart';
import '../../../../constants/app_sizes.dart';
import '../../../controller/wallet_controller.dart';
import '../../../models/wallet_model.dart';

class WalletPage extends GetView<WalletController> {
  const WalletPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      initState: (_) => _init(),
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('我的钱包'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadWalletData(),
              )
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.wallet.value == null) {
              return _buildCreateWalletView();
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadWalletData(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.spacing16),
                      child: Column(
                        children: [
                          _buildAssetCard(context),
                          const SizedBox(height: AppSizes.spacing24),
                          _buildActionButtons(context),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing16, vertical: AppSizes.spacing8),
                      child: Text(
                        '最近交易',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ),
                  _buildTransactionList(),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCreateWalletView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet,
              size: AppSizes.spacing80, color: AppColors.textHint),
          const SizedBox(height: AppSizes.spacing16),
          const Text('您还没有钱包',
              style: TextStyle(
                  fontSize: AppSizes.font18, color: AppColors.textHint)),
          const SizedBox(height: AppSizes.spacing24),
          ElevatedButton(
            onPressed:
                controller.isCreating.value ? null : controller.createWallet,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing32,
                  vertical: AppSizes.spacing12),
            ),
            child: controller.isCreating.value
                ? const SizedBox(
                    width: AppSizes.spacing20,
                    height: AppSizes.spacing20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('立即创建'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context) {
    final wallet = controller.wallet.value!;
    final address = wallet.address.length >= 12
        ? '${wallet.address.substring(0, 6)}...${wallet.address.substring(wallet.address.length - 6)}'
        : wallet.address;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: AppSizes.radius10,
            offset: const Offset(0, AppSizes.spacing5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '总资产',
                style: TextStyle(
                    color: AppColors.textWhite.withOpacity(0.9), fontSize: AppSizes.font14),
              ),
              IconButton(
                icon: const Icon(
                  Icons.qr_code,
                  color: AppColors.textWhite,
                  size: AppSizes.iconLarge,
                ),
                onPressed: () => _showReceiveDialog(context, wallet.address),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          // const SizedBox(height: 8),
          Text(
            wallet.balance,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: AppSizes.font32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12, vertical: AppSizes.spacing6),
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radius20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: AppSizes.font12),
                ),
                const SizedBox(width: AppSizes.spacing8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: wallet.address));
                    Get.showSnackbar(const GetSnackBar(
                      message: '地址已复制',
                      duration: Duration(seconds: 1),
                    ));
                  },
                  child: const Icon(Icons.copy, color: AppColors.textWhite, size: AppSizes.font14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context,
          icon: Icons.send,
          label: '转账',
          color: AppColors.primary,
          onTap: () => controller.openTransferPage(),
        ),
        _buildActionButton(
          context,
          icon: Icons.call_received,
          label: '收款',
          color: AppColors.success,
          onTap: () => controller.openReceivePage(),
        ),
        _buildActionButton(
          context,
          icon: Icons.history,
          label: '账单',
          color: AppColors.warning,
          // TODO: 跳转到详细账单页
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing20, vertical: AppSizes.spacing12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Obx(() {
      if (controller.transactions.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: AppSizes.spacing40),
            child: Center(
                child: Text('暂无交易记录', style: TextStyle(color: AppColors.textHint))),
          ),
        );
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tx = controller.transactions[index];
            final isReceive =
                tx.receiverAddress == controller.wallet.value?.address;
            return ListTile(
              onTap: () => controller.openTransactionDetail(tx),
              leading: CircleAvatar(
                backgroundColor: isReceive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                child: Icon(
                  _getTransactionIcon(tx, isReceive),
                  color: isReceive ? AppColors.success : AppColors.error,
                  size: AppSizes.font20,
                ),
              ),
              title: Text(
                _getTransactionTitle(tx, isReceive),
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: AppSizes.font15,
                ),
              ),
              subtitle: Text(
                DateUtil.getTimeToDisplay(
                    tx.timestamp ?? 0, "yy-MM-dd HH:mm", true),
                style: const TextStyle(fontSize: AppSizes.font12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isReceive ? '+' : '-'}${tx.amount}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      // fontFamily: 'Arial',
                      fontSize: AppSizes.font15,
                    ),
                  ),
                  // Text(
                  //   tx.statusEnum.description,
                  //   style: TextStyle(
                  //     fontSize: 11,
                  //     color: _getStatusColor(tx.statusEnum),
                  //   ),
                  // ),
                ],
              ),
            );
          },
          childCount: controller.transactions.length,
        ),
      );
    });
  }

  String _getTransactionTitle(TransactionVo tx, bool isReceive) {
    // 如果是转账类型，区分收入支出
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

  void _showReceiveDialog(BuildContext context, String address) {
    showDialog(
      context: context,
      builder: (context) => ReceiveDialog(address: address),
    );
  }

  void _init() {
    controller.loadWalletData();
    // 启动 NFC 支付会话监听
    //NfcService.to.startPaymentSession(controller.handleNfcPayment);
  }
}

class ReceiveDialog extends StatefulWidget {
  final String address;

  const ReceiveDialog({Key? key, required this.address}) : super(key: key);

  @override
  State<ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends State<ReceiveDialog> {
  @override
  Widget build(BuildContext context) {
    // 构建二维码数据
    String qrData = '${AppConstants.WALLET_ADDRESS_PREFIX}${widget.address}';

    final encodedQrData = Uri.encodeComponent(qrData);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('收款码',
                style: TextStyle(fontSize: AppSizes.font18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.spacing12),
            QrImageView(
              data: encodedQrData,
              version: QrVersions.auto,
              size: AppSizes.spacing200,
              embeddedImageStyle:
                  const QrEmbeddedImageStyle(size: Size(AppSizes.spacing36, AppSizes.spacing36)),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              errorStateBuilder: (context, error) {
                debugPrint('二维码生成失败: $error');
                return const Center(
                  child: Text(
                    '二维码生成失败',
                    style: TextStyle(color: AppColors.error, fontSize: AppSizes.font14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
