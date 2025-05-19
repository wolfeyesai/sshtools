// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ssh_header_model.dart';
import '../controllers/ssh_header_controller.dart';
import '../models/ip_model.dart';
import '../models/ssh_command_model.dart';

/// SSH终端页头视图组件
class SSHHeaderView extends StatelessWidget {
  /// 目标设备
  final IPDeviceModel device;
  
  /// SSH凭据
  final String username;
  final String password;
  final int port;
  
  /// 命令选择回调
  final Function(SSHCommandModel command)? onCommandSelected;
  
  /// 构造函数
  const SSHHeaderView({
    Key? key,
    required this.device,
    required this.username,
    required this.password,
    required this.port,
    this.onCommandSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听模型变化
    return Consumer<SSHHeaderModel>(
      builder: (context, headerModel, child) {
        // 直接在这里获取控制器，避免在action方法中每次都获取
        final headerController = Provider.of<SSHHeaderController>(context, listen: false);
        
        return AppBar(
          title: Text(headerModel.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 2.0,
          shadowColor: Colors.black26,
          actions: _buildActions(context, headerModel, headerController),
        );
      },
    );
  }
  
  /// 构建操作按钮
  List<Widget> _buildActions(
    BuildContext context, 
    SSHHeaderModel model,
    SSHHeaderController controller
  ) {
    return [
      // 上传文件按钮
      _buildActionButton(
        context: context,
        icon: Icons.upload_file,
        tooltip: '上传文件',
        isEnabled: model.isFileUploadEnabled,
        onPressed: () => controller.handleFileUpload(context),
      ),
      
      // 下载文件按钮
      _buildActionButton(
        context: context,
        icon: Icons.download,
        tooltip: '下载文件',
        isEnabled: model.isFileDownloadEnabled,
        onPressed: () => controller.handleFileDownload(context),
      ),
      
      // 设备信息按钮
      IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: '连接信息',
        onPressed: () {
          _showDeviceInfo(context);
        },
      ),
    ];
  }
  
  /// 显示设备连接信息
  void _showDeviceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('主机', device.ipAddress),
            _buildInfoRow('端口', port.toString()),
            _buildInfoRow('用户名', username),
            _buildInfoRow('设备名', device.hostname),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  /// 构建操作按钮
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: isEnabled ? onPressed : null,
    );
  }
} 