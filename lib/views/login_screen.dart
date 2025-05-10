// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, use_build_context_synchronously, deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../component/Button_component.dart';
import '../component/input_component.dart';
import '../component/background_component.dart';
import '../component/status_indicator_component.dart'; // 导入新的状态指示器组件
import '../controllers/login_controller.dart';
import '../services/server_service.dart'; // 导入 ServerService
import '../services/auth_service.dart'; // 导入 AuthService
import '../models/auth_model.dart'; // 导入 AuthModel
import '../models/login_model.dart'; // 导入 LoginModel

/// 登录界面
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 全局表单验证键
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 更新密码可见性
  void _updatePasswordVisibility(int index, bool isVisible) {
    Provider.of<LoginController>(context, listen: false)
        .updatePasswordVisibility(index, isVisible);
  }

  @override
  Widget build(BuildContext context) {
    // 使用Provider获取服务和控制器
    final serverService = Provider.of<ServerService>(context);
    final loginModel = Provider.of<LoginModel>(context);
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
                      
                      // 连接状态指示器
                      StatusIndicatorComponent.createServerStatus(
                        isConnected: serverService.isConnected,
                        isConnecting: serverService.isConnecting,
                        hasError: serverService.hasError,
                        errorText: serverService.errorText,
                        serverAddress: loginModel.serverAddress,
                        serverPort: loginModel.serverPort,
                      ),
                      
                      // 登录状态指示器
                      if (controller.isLoading)
                        StatusIndicatorComponent.create(
                          message: '正在登录，请稍候...',
                          type: StatusType.loading,
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // 连接服务器按钮
                      ButtonComponent.create(
                        type: ButtonType.secondary,
                        label: serverService.isConnecting 
                            ? '连接中...'
                            : serverService.isConnected 
                                ? '已连接服务器' 
                                : '连接服务器',
                        icon: const Icon(Icons.link),
                        onPressed: serverService.isConnected || serverService.isConnecting
                            ? null 
                            : () => controller.handleConnectService(context),
                        shape: ButtonShape.standard,
                        fullWidth: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
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
                                      if (_formKey.currentState?.validate() ?? false) {
                                        controller.handleLogin(context);
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
                              onPressed: () => controller.handleRegister(context),
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
