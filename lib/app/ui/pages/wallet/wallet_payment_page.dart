import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/wallet_controller.dart';

class WalletPaymentPage extends GetView<WalletController> {
  const WalletPaymentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toAddressController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // 获取传入的参数
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args.containsKey('toAddress')) {
        toAddressController.text = args['toAddress'];
      }
      if (args.containsKey('amount')) {
        amountController.text = args['amount']?.toString() ?? '';
      }
    }

    return GetBuilder<WalletController>(
      initState: (_) {
        controller.loadWalletData();
        controller.fetchFeeInfo();
      },
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('支付'),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Get.toNamed('${Routes.HOME}'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacing20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => _buildBalanceInfo(context)),
                  const SizedBox(height: AppSizes.spacing30),
                  const Text('收款方地址',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSizes.spacing10),
                  TextFormField(
                    controller: toAddressController,
                    readOnly:
                        toAddressController.text.isNotEmpty, // 如果是扫码进来的，建议只读
                    decoration: InputDecoration(
                      hintText: '输入收款方地址',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12)),
                      prefixIcon: const Icon(Icons.store),
                      suffixIcon: toAddressController.text.isEmpty
                          ? IconButton(
                              icon: const Icon(Icons.paste),
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                    Clipboard.kTextPlain);
                                if (data?.text != null) {
                                  toAddressController.text = data!.text!;
                                }
                              },
                            )
                          : null,
                    ),
                    validator: (v) =>
                        v == null || v.length != 40 ? '请输入有效的40位地址' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('支付金额',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    // inputFormatters: [
                    //   FilteringTextInputFormatter.allow(
                    //       RegExp(r'[0-9]')), // 限制仅允许输入数字
                    // ],
                    // 自动聚焦金额输入框
                    decoration: InputDecoration(
                      hintText: '0.00',
                      suffixText: 'COIN',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    onChanged: (v) => controller.computeEstimatedFee(v),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入金额';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return '金额无效';
                      final feeVal =
                          double.tryParse(controller.calculateFee(v)) ?? 0.0;
                      final balance =
                          double.tryParse(controller.wallet.value?.balance ?? '0') ??
                              0.0;
                      if ((val + feeVal) > balance) {
                        return '余额不足';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacing12),
                  Obx(() {
                    final feeText = controller.estimatedFee.value;
                    return Text(
                      '预计手续费: $feeText COIN',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.font12),
                    );
                  }),
                  const SizedBox(height: AppSizes.spacing40),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.spacing50,
                    child: ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        if (formKey.currentState!.validate()) {
                          await controller.pay(
                            toAddress: toAddressController.text.trim(),
                            amount: amountController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12),
                        ),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                      ),
                      child: const Text('确认支付', style: TextStyle(fontSize: AppSizes.font16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('当前可用余额'),
          Text(
            '${controller.wallet.value?.balance ?? "0.00"} COIN',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.font18,
            ),
          ),
        ],
      ),
    );
  }
}
