import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../controller/login_controller.dart';
import '../../widgets/icon/icon_font.dart';

/// 登录页面
///
/// 支持账号密码登录和手机验证码登录两种模式。
/// 页面设计追求简洁、大方，与应用整体风格保持一致。
class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface, // 使用纯白底色，显得干净
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing32),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                /// Logo 与欢迎语
                _buildHeader(),

                const SizedBox(height: AppSizes.spacing48),

                /// 登录表单切换区域
                SizedBox(
                  height: 320, // 稍微增加高度以容纳更多内容
                  child: TabBarView(
                    controller: controller.tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildLoginForm(context, isPasswordMode: true),
                      _buildLoginForm(context, isPasswordMode: false),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.spacing12),

                /// 切换登录方式与注册引导
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  /// 构建头部 Logo 与欢迎信息
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSizes.radius20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            child: Image.asset(
              'assets/logo/app_icon.png',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacing24),
        const Text(
          '欢迎登录 Lucky',
          style: TextStyle(
            fontSize: AppSizes.font24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),
      ],
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm(BuildContext context, {required bool isPasswordMode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 账号/手机号输入框
        _buildInputField(
          controller: controller.principalController,
          hintText: isPasswordMode ? '请输入账号' : '请输入手机号',
          icon: isPasswordMode
              ? Iconfont.fromName('User')
              : Iconfont.fromName('shouji'),
          keyboardType:
              isPasswordMode ? TextInputType.text : TextInputType.phone,
          inputFormatters: isPasswordMode
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ]
              : null,
        ),
        const SizedBox(height: AppSizes.spacing20),

        /// 密码/验证码输入框
        _buildInputField(
          controller: controller.credentialsController,
          hintText: isPasswordMode ? '请输入密码' : '请输入验证码',
          icon: isPasswordMode
              ? Iconfont.fromName('shezhix')
              : Iconfont.fromName('tixing'),
          obscureText: isPasswordMode,
          keyboardType:
              isPasswordMode ? TextInputType.text : TextInputType.number,
          suffixIcon: !isPasswordMode ? _buildVerifyCodeBtn(context) : null,
        ),

        if (isPasswordMode) ...[
          const SizedBox(height: AppSizes.spacing12),
          _buildRememberMe(),
        ],

        const SizedBox(height: AppSizes.spacing32),

        /// 登录按钮
        _buildSubmitButton(context),
      ],
    );
  }

  /// 通用输入框构建
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
            fontSize: AppSizes.font16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
              color: AppColors.textHint, fontSize: AppSizes.font14),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// 记住密码勾选框
  Widget _buildRememberMe() {
    return Row(
      children: [
        Obx(() => SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: controller.rememberCredentials.value,
                onChanged: (value) =>
                    controller.rememberCredentials.value = value ?? false,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: AppColors.textHint, width: 1.5),
              ),
            )),
        const SizedBox(width: AppSizes.spacing8),
        GestureDetector(
          onTap: () => controller.rememberCredentials.toggle(),
          child: const Text(
            '记住密码',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: AppSizes.font13),
          ),
        ),
      ],
    );
  }

  /// 发送验证码按钮
  Widget _buildVerifyCodeBtn(BuildContext context) {
    return Obx(() => TextButton(
          onPressed: controller.canSendCode.value
              ? controller.sendVerificationCode
              : null,
          child: Text(
            controller.canSendCode.value
                ? '发送验证码'
                : '${controller.countDown}s 后重发',
            style: TextStyle(
              fontSize: AppSizes.font13,
              fontWeight: FontWeight.w600,
              color: controller.canSendCode.value
                  ? AppColors.primary
                  : AppColors.textDisabled,
            ),
          ),
        ));
  }

  /// 提交按钮
  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Obx(() => ElevatedButton(
            onPressed:
                controller.isLoading.value ? null : controller.handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius12)),
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '登 录',
                    style: TextStyle(
                        fontSize: AppSizes.font18, fontWeight: FontWeight.bold),
                  ),
          )),
    );
  }

  /// 底部引导与切换
  Widget _buildFooter(BuildContext context) {
    return Obx(() {
      // 显式使用 .value 以确保 GetX 能够监听到变化
      final isPasswordMode = controller.activeTabIndex.value == 0;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isPasswordMode ? '还没有账号？' : '已有账号？',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: AppSizes.font14),
              ),
              TextButton(
                onPressed: () {
                  controller.tabController.animateTo(isPasswordMode ? 1 : 0);
                },
                child: Text(
                  isPasswordMode ? '验证码登录' : '账号密码登录',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: AppSizes.font14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing32),
          // 这里可以预留第三方登录入口等
        ],
      );
    });
  }
}
