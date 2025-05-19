// ignore_for_file: unused_import, use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../models/ssh_saved_session_model.dart';
import '../controllers/ssh_controller.dart';
import '../models/ip_model.dart';
import '../controllers/ssh_header_controller.dart';
import '../models/ssh_header_model.dart';

/// SSH会话标签管理组件
/// 用于在SSH终端页面中管理多个会话标签
class SSHSessionTabManager extends StatefulWidget {
  /// 活动会话索引
  final int activeIndex;
  
  /// 会话列表
  final List<SSHSessionTab> sessions;
  
  /// 添加新会话回调
  final Function() onAddSession;
  
  /// 切换会话回调
  final Function(int index) onSwitchSession;
  
  /// 关闭会话回调
  final Function(int index) onCloseSession;
  
  /// 构造函数
  const SSHSessionTabManager({
    Key? key,
    required this.activeIndex,
    required this.sessions,
    required this.onAddSession,
    required this.onSwitchSession,
    required this.onCloseSession,
  }) : super(key: key);

  @override
  State<SSHSessionTabManager> createState() => _SSHSessionTabManagerState();
}

class _SSHSessionTabManagerState extends State<SSHSessionTabManager> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 会话标签列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.sessions.length,
              itemBuilder: (context, index) {
                final session = widget.sessions[index];
                final isActive = index == widget.activeIndex;
                
                return _buildSessionTab(session, index, isActive);
              },
            ),
          ),
          
          // 添加会话按钮
          GFIconButton(
            icon: Icon(
              Icons.add,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            size: GFSize.SMALL,
            type: GFButtonType.transparent,
            shape: GFIconButtonShape.circle,
            onPressed: widget.onAddSession,
            tooltip: '添加新会话',
            boxShadow: const BoxShadow(
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建会话标签
  Widget _buildSessionTab(SSHSessionTab session, int index, bool isActive) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.primary;
    
    // 活动会话使用鲜明的颜色，非活动会话使用较淡的颜色
    final backgroundColor = isActive 
        ? baseColor
        : theme.colorScheme.surfaceVariant;
        
    final textColor = isActive 
        ? theme.colorScheme.onPrimary 
        : theme.colorScheme.onSurfaceVariant;
    
    // 连接状态指示器颜色
    final indicatorColor = session.isConnected
        ? Colors.green
        : (session.connectionStatus.contains('失败') ? Colors.red : Colors.orange);
    
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: baseColor.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, -1),
            )
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onSwitchSession(index),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    // 连接状态指示器
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    
                    // 会话名称
                    Text(
                      session.displayName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    
                    // 关闭按钮
                    GFIconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: textColor.withOpacity(0.8),
                      ),
                      size: GFSize.SMALL,
                      type: GFButtonType.transparent,
                      onPressed: () => widget.onCloseSession(index),
                      padding: EdgeInsets.zero,
                      boxShadow: const BoxShadow(
                        color: Colors.transparent,
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

/// SSH会话标签模型
class SSHSessionTab {
  /// 显示名称
  final String displayName;
  
  /// 设备信息
  final IPDeviceModel device;
  
  /// SSH凭据
  final String username;
  final String password;
  final int port;
  
  /// SSH控制器
  final SSHController controller;
  
  /// SSH头部控制器
  final SSHHeaderController headerController;
  
  /// 是否已连接
  bool isConnected;
  
  /// 连接状态
  String connectionStatus;
  
  /// 构造函数
  SSHSessionTab({
    required this.displayName,
    required this.device,
    required this.username,
    required this.password,
    required this.port,
    required this.controller,
    SSHHeaderController? headerController,
    this.isConnected = false,
    this.connectionStatus = '准备连接...',
  }) : headerController = headerController ?? SSHHeaderController(
         model: SSHHeaderModel(
           title: displayName,
           isConnected: false,
         ),
         sshController: controller,
       );
  
  /// 从会话模型创建
  factory SSHSessionTab.fromSessionModel(
    SSHSavedSessionModel model, 
    SSHController controller
  ) {
    // 创建设备模型
    final device = IPDeviceModel(
      ipAddress: model.host,
      type: IPType.localNetwork,
      hostname: model.name,
      macAddress: '',
    );
    
    return SSHSessionTab(
      displayName: model.name,
      device: device,
      username: model.username,
      password: model.password,
      port: model.port,
      controller: controller,
    );
  }
  
  /// 从当前会话复制创建新会话
  SSHSessionTab copy({
    String? displayName,
    IPDeviceModel? device,
    String? username,
    String? password,
    int? port,
    SSHController? controller,
  }) {
    return SSHSessionTab(
      displayName: displayName ?? this.displayName,
      device: device ?? this.device,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
      controller: controller ?? this.controller,
      isConnected: false,
      connectionStatus: '准备连接...',
    );
  }
} 