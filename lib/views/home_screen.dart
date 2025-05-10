// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:getwidget/getwidget.dart';
// import '../component/card_select_component.dart';
// import '../component/input_component.dart';
import '../controllers/home_controller.dart';
// import '../controllers/header_controller.dart'; // 移除不再需要的导入
import '../services/server_service.dart'; // 保留或替换为 SSHService
import '../services/ssh_service.dart'; // 导入 SshService
import '../models/auth_model.dart'; // 可能仍然需要用于一些状态或信息
// 移除不再需要的模型导入
// import '../models/game_model.dart'; 
// import '../component/message_component.dart'; 

// 导入 DeviceModel，用于获取设备列表
import '../models/device_model.dart';

// TODO: 导入 SSHService，如果 ServerService 被替换
// import '../services/ssh_service.dart';

/// 首页 - 显示最近连接和快速连接入口
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final deviceModel = Provider.of<DeviceModel>(context, listen: false);
        final sshService = Provider.of<SshService>(context, listen: false); // 获取 SshService
        return HomeController(
          deviceModel: deviceModel,
          sshService: sshService, // 只传递 sshService
        );
      },
      child: const _HomeScreenView(),
    );
  }
}

/// 首页视图组件
class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  @override
  Widget build(BuildContext context) {
    final deviceModel = Provider.of<DeviceModel>(context);
    final homeController = Provider.of<HomeController>(context);

    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    final recentConnections = deviceModel.devices;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '最近连接',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '当前本地 IP 地址: 192.168.1.100 (占位符)',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: recentConnections.isEmpty
                    ? const Center(child: Text('没有最近连接'))
                    : ListView.builder(
                        itemCount: recentConnections.length,
                        itemBuilder: (context, index) {
                          final device = recentConnections[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: Icon(Icons.computer),
                              title: Text(device.name ?? '无别名'),
                              subtitle: Text('${device.host}:${device.port}'),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                homeController.connectToDevice(context, device);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 移除旧的不需要的构建方法
  // Widget _buildHeader(BuildContext context, HomeController controller) { ... }
  // Widget _buildCardSelectionArea(...) { ... }
  // Widget _buildSelectedGameBar(...) { ... }
}

// 移除旧的 _handleRefreshConfig, _handleSaveConfig 方法
// void _handleRefreshConfig(BuildContext context) { ... }
// void _handleSaveConfig(BuildContext context) { ... }

// 移除旧的 _handleRefreshConfig, _handleSaveConfig 方法
// void _handleRefreshConfig(BuildContext context) { ... }
// void _handleSaveConfig(BuildContext context) { ... }

// 移除旧的 _handleRefreshConfig, _handleSaveConfig 方法
// void _handleRefreshConfig(BuildContext context) { ... }
// void _handleSaveConfig(BuildContext context) { ... } 