// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, unreachable_switch_default, unused_import, unused_local_variable, unused_element, unnecessary_import, dead_code, invalid_use_of_visible_for_testing_member, unused_field, use_build_context_synchronously, deprecated_member_use, deprecated_member_use, duplicate_ignore, use_super_parameters

import 'package:flutter/material.dart';
// 移除不需要的导入
// import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
// 移除不需要的组件导入
// import '../component/dropdown_component.dart';
import '../component/status_indicator_component.dart'; // 保留状态指示器组件
import '../controllers/header_controller.dart';
import '../models/auth_model.dart'; // 保留 AuthModel
import '../models/ui_config_model.dart'; // 保留 UIConfigModel (如果页头需要根据UI配置调整)
import '../services/ssh_service.dart'; // 使用 SshService 替代 ServerService
// 移除不需要的导入
// import 'dart:developer' as developer;
// import 'dart:async';
// import '../models/status_bar_model.dart'; // 如果状态不是通过HeaderController提供，可能需要
// import '../models/login_model.dart'; // 如果不处理登录对话框，不再需要 LoginModel
// import '../models/game_model.dart'; // 如果不处理游戏选择，不再需要 GameModel

/// 头部页面组件
class HeaderScreen extends StatelessWidget {
  /// 退出登录回调
  final VoidCallback onLogout;

  /// 刷新系统回调
  final VoidCallback onRefreshSystem;

  /// 构造函数
  const HeaderScreen({
    Key? key,
    required this.onLogout,
    required this.onRefreshSystem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用Provider获取 AuthModel 和 SshService 来获取状态
    final authModel = Provider.of<AuthModel>(context);
    final sshService = Provider.of<SshService>(context); // 使用 SshService 替代 ServerService
    final uiConfigModel = Provider.of<UIConfigModel>(context); // 保留 UIConfigModel

    final String username = authModel.username; // 获取用户名
    // 使用 SshService 获取连接状态
    final bool isConnected = sshService.isConnected;
    final String connectionStatus = isConnected ? '已连接' : '未连接'; // 示例状态文本

    // 获取UI配置
    final Color backgroundColor = uiConfigModel.backgroundColor;
    final Color textColor = uiConfigModel.textColor;
    // 可以根据需要从 uiConfigModel 获取更多样式配置

    return SizedBox(
      height: 64, // 固定高度
      width: double.infinity, // 宽度占满
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: backgroundColor, // 使用 UI 配置的背景色
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 用户头像和用户名
            Row(
              children: [
                // TODO: 添加用户头像
                Icon(Icons.account_circle, color: textColor, size: 40), // 占位符头像
                const SizedBox(width: 8),
                Text(
                  username.isNotEmpty ? username : '未知用户', // 显示用户名
                  style: TextStyle(color: textColor, fontSize: 16), // 使用 UI 配置的文本颜色和字号
                ),
              ],
            ),

            // 用户状态 - 使用SizedBox包装确保有尺寸
            SizedBox(
              width: 120, // 给状态指示器一个固定宽度
              child: StatusIndicatorComponent.createConnectionStatus(isConnected: isConnected), // 使用状态指示器组件并传入连接状态
            ),

            // 刷新和退出登录按钮
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.refresh, color: textColor), // 刷新按钮
                  onPressed: onRefreshSystem, // 调用传入的刷新回调
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: textColor), // 退出登录按钮
                  onPressed: onLogout, // 调用传入的退出登录回调
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 移除旧的 _HeaderScreenState 类和相关方法
// class _HeaderScreenState extends State<HeaderScreen> { ... }
