import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../constants/app_constant.dart';
import '../../../controller/wallet_controller.dart';
import '../../../services/nfc_service.dart';

class WalletReceivePage extends GetView<WalletController> {
  const WalletReceivePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收款'),
        elevation: 0,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // 假设已经从上一个页面传入了 address，如果没有，尝试从 Controller 获取
    // 为了更稳健，我们可以从 Controller 获取当前钱包地址
    final address = controller.wallet.value?.address ?? '';

    return ReceiveBody(address: address);
  }
}

class ReceiveBody extends StatefulWidget {
  final String address;

  const ReceiveBody({Key? key, required this.address}) : super(key: key);

  @override
  State<ReceiveBody> createState() => _ReceiveBodyState();
}

class _ReceiveBodyState extends State<ReceiveBody> {
  String? _amount;

  @override
  void initState() {
    super.initState();
    _updateNfc();
  }

  @override
  void dispose() {
    NfcService.to.stopSession();
    super.dispose();
  }

  Future<void> _updateNfc() async {
    await NfcService.to.stopSession();
    await NfcService.to.startWriteSession(widget.address, _amount);
  }

  @override
  Widget build(BuildContext context) {
    // 构建二维码数据
    String qrData = '${AppConstants.walletAddressPrefix}${widget.address}';
    if (_amount != null && _amount!.isNotEmpty) {
      qrData += '&amount=$_amount';
    }

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.spacing30),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
              padding: const EdgeInsets.all(AppSizes.spacing24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: AppSizes.radius20,
                    offset: const Offset(0, AppSizes.spacing10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '扫一扫，向我付款',
                    style: TextStyle(
                      fontSize: AppSizes.font16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: AppSizes.spacing200 + AppSizes.spacing20,
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(AppSizes.spacing40, AppSizes.spacing40)),
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    // TODO: 可以添加 logo
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                  if (_amount != null && _amount!.isNotEmpty)
                    Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '收款金额: ',
                                style: TextStyle(
                                    fontSize: AppSizes.font20,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: _amount,
                                style: const TextStyle(
                                    fontSize: AppSizes.font32,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                      ],
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacing12,
                        vertical: AppSizes.spacing8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radius8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.address,
                            style: const TextStyle(
                              fontSize: AppSizes.font13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacing8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.address));
                            Get.showSnackbar(const GetSnackBar(
                              message: '地址已复制',
                              duration: Duration(seconds: 1),
                            ));
                          },
                          child: const Icon(Icons.copy,
                              size: AppSizes.iconSmall,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spacing40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_amount == null || _amount!.isEmpty)
                  _buildActionButton(
                    icon: Icons.edit,
                    label: '设置金额',
                    onTap: () => _showAmountDialog(context),
                  )
                else
                  _buildActionButton(
                    icon: Icons.close,
                    label: '清除金额',
                    onTap: () {
                      setState(() {
                        _amount = null;
                      });
                      _updateNfc();
                    },
                  ),
                const SizedBox(width: AppSizes.spacing40),
                _buildActionButton(
                  icon: Icons.share,
                  label: '保存收款码',
                  onTap: () {
                    // TODO: 实现保存功能
                    Get.snackbar('提示', '保存功能开发中',
                        snackPosition: SnackPosition.BOTTOM);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: AppSizes.spacing50,
            height: AppSizes.spacing50,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: AppSizes.radius10,
                  offset: const Offset(0, AppSizes.spacing5),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            label,
            style: const TextStyle(
                fontSize: AppSizes.font14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  void _showAmountDialog(BuildContext context) {
    final controller = TextEditingController(text: _amount);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置收款金额'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入金额',
            suffixText: 'COIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  _amount = controller.text.trim();
                });
                _updateNfc();
                Navigator.pop(context);
              } else {
                Get.snackbar('错误', '请输入有效的金额',
                    snackPosition: SnackPosition.BOTTOM);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
