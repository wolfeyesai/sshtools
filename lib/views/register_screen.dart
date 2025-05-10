// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, unused_import, unused_element

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../component/Button_component.dart';
import '../component/input_component.dart';
import '../controllers/register_controller.dart';

/// 注册页面
class RegisterScreen extends StatefulWidget {
  /// 注册成功回调
  final VoidCallback onRegisterSuccess;
  
  /// 返回登录页面回调
  final VoidCallback onBackToLogin;

  const RegisterScreen({
    Key? key,
    required this.onRegisterSuccess,
    required this.onBackToLogin,
  }) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 全局表单验证键
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 更新密码可见性
  void _updatePasswordVisibility(BuildContext context, int index, bool isVisible) {
    Provider.of<RegisterController>(context, listen: false)
        .updatePasswordVisibility(index, isVisible);
  }

  // 添加密码验证方法
  String? _validatePasswordMatch(BuildContext context, String? value) {
    final controller = Provider.of<RegisterController>(context, listen: false);
    if (value != controller.passwordController.text) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();

    if (controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: GFCard(
            boxFit: BoxFit.cover,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 标题
                    const Center(
                      child: Text(
                        '注册新账号',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 输入框组
                    InputComponent.createMultiInputs(
                      inputs: controller.getInputFields(),
                      controllers: controller.controllers,
                      spacing: 24.0,
                      passwordVisibleList: controller.passwordVisibleList,
                      onTogglePasswordVisibility: (index, isVisible) =>
                          _updatePasswordVisibility(context, index, isVisible),
                    ),
                    
                    // 用户协议同意选项
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GFCheckbox(
                          size: GFSize.SMALL,
                          type: GFCheckboxType.square,
                          activeIcon: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                          value: controller.agreeToTerms,
                          onChanged: (value) {
                            controller.updateAgreeToTerms(value);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black87, fontSize: 14),
                              children: [
                                TextSpan(text: '我已阅读并同意 '),
                                TextSpan(
                                  text: '用户协议',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                TextSpan(text: ' 和 '),
                                TextSpan(
                                  text: '隐私政策',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 注册按钮
                    GFButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false && !controller.isLoading) {
                          final success = await controller.handleRegister(context);
                          if (success) {
                            widget.onRegisterSuccess();
                          }
                        }
                      },
                      text: controller.isLoading ? '注册中...' : '注册',
                      icon: controller.isLoading ? null : const Icon(Icons.person_add, color: Colors.white),
                      size: GFSize.LARGE,
                      fullWidthButton: true,
                      color: Theme.of(context).primaryColor,
                      shape: GFButtonShape.standard,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 返回登录按钮
                    Center(
                      child: GFButton(
                        onPressed: widget.onBackToLogin,
                        text: '返回登录',
                        type: GFButtonType.transparent,
                        textStyle: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
