// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, use_build_context_synchronously, deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../component/Button_component.dart';
import '../component/input_component.dart';
import '../component/background_component.dart';
import '../component/status_indicator_component.dart'; // 导入新的状态指示器组件
import '../controllers/login_controller.dart';
import '../utils/logger.dart'; // 添加 Logger 导入
// import '../services/server_service.dart'; // 导入 ServerService (移除)
// import '../services/auth_service.dart'; // 导入 AuthService (移除)
// import '../models/auth_model.dart'; // 导入 AuthModel (移除)
// import '../models/login_model.dart'; // 导入 LoginModel (移除)

/// 登录界面
class LoginScreen extends StatefulWidget {
  /// 登录成功回调
  final VoidCallback onLoginSuccess;
  
  /// 跳转到注册页面回调
  final VoidCallback onRegister;

  const LoginScreen({
    Key? key, 
    required this.onLoginSuccess,
    required this.onRegister,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 全局表单验证键
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // 日志工具
  final log = Logger();
  final String _logTag = 'LoginScreen';

  // 更新密码可见性
  void _updatePasswordVisibility(int index, bool isVisible) {
    Provider.of<LoginController>(context, listen: false)
        .updatePasswordVisibility(index, isVisible);
  }

  @override
  Widget build(BuildContext context) {
    // 使用Provider获取服务和控制器
    final controller = Provider.of<LoginController>(context);

    return BackgroundComponent.createGradientBackground(
      gradientColors: [
        Colors.blue.shade100,
        Colors.lightBlue.shade50,
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                          '欢迎登录',
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
                        inputs: controller.getInputFieldsData(),
                        controllers: controller.controllers,
                        spacing: 24.0,
                        passwordVisibleList: controller.passwordVisibleList,
                        onTogglePasswordVisibility: _updatePasswordVisibility,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 登录状态指示器
                      if (controller.isLoading)
                        StatusIndicatorComponent.create(
                          message: '正在登录，请稍候...',
                          type: StatusType.loading,
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // 登录和注册按钮并排
                      Row(
                        children: [
                          // 登录按钮
                          Expanded(
                            flex: 3,
                            child: GFButton(
                              onPressed: controller.isLoading 
                                  ? null 
                                  : () {
                                      log.i(_logTag, '用户点击了登录按钮');
                                      if (_formKey.currentState?.validate() ?? false) {
                                        log.i(_logTag, '表单验证通过，开始登录流程');
                                        controller.handleLogin(context).then((success) {
                                          log.i(_logTag, '登录结果: ${success ? "成功" : "失败"}');
                                          if (success) {
                                            widget.onLoginSuccess();
                                          }
                                        });
                                      } else {
                                        log.w(_logTag, '表单验证失败');
                                      }
                                    },
                              text: controller.isLoading ? '登录中...' : '登录',
                              icon: controller.isLoading 
                                  ? null
                                  : const Icon(Icons.login, color: Colors.white),
                              size: GFSize.LARGE,
                              fullWidthButton: true,
                              color: Theme.of(context).primaryColor,
                              shape: GFButtonShape.standard,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 注册按钮
                          Expanded(
                            flex: 2,
                            child: GFButton(
                              onPressed: widget.onRegister,
                              text: '注册账号',
                              type: GFButtonType.transparent,
                              textColor: Colors.blue,
                              size: GFSize.SMALL,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
