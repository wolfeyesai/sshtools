// ignore_for_file: library_private_types_in_public_api, unused_import, unreachable_switch_default, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 状态类型枚举
enum StatusType {
  success, // 成功状态
  error,   // 错误状态
  warning, // 警告状态
  info,    // 信息状态
  loading, // 加载状态
  neutral, // 中性状态
}

/// 状态指示器组件
/// 
/// 用于显示各种状态信息，如连接状态、操作结果等
class StatusIndicatorComponent {
  /// 创建状态指示器
  /// 
  /// [message] 状态消息
  /// [type] 状态类型，如成功、错误等
  /// [icon] 自定义图标，若不提供则使用默认图标
  /// [description] 详细描述，可选
  /// [borderRadius] 边框圆角
  /// [padding] 内部填充
  /// [margin] 外部边距
  static Widget create({
    required String message,
    StatusType type = StatusType.neutral,
    Icon? icon,
    String? description,
    double borderRadius = 4.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    // 根据状态类型获取颜色
    final Color statusColor = _getStatusColor(type);
    final Color bgColor = statusColor.withOpacity(0.1);
    
    // 根据状态类型获取图标
    final Icon statusIcon = icon ?? _getStatusIcon(type);
    
    // 设置默认内边距
    final EdgeInsetsGeometry contentPadding = padding ?? 
        const EdgeInsets.symmetric(vertical: 8, horizontal: 12);
    
    // 设置默认外边距
    final EdgeInsetsGeometry containerMargin = margin ?? 
        const EdgeInsets.symmetric(vertical: 4);
    
    return Container(
      margin: containerMargin,
      padding: contentPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 状态图标
          Icon(
            statusIcon.icon,
            size: statusIcon.size ?? 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          
          // 状态文本
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 主要消息
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                    height: 1.4,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                ),
                
                // 可选的描述文本
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color.fromRGBO(25, 28, 32, 1.0),
                      height: 1.4,
                      leadingDistribution: TextLeadingDistribution.even,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 创建连接状态指示器
  /// 
  /// [isConnected] 是否已连接
  /// [hasError] 是否有错误
  /// [errorText] 错误文本
  /// [connectionDetails] 连接详情，如服务器地址和端口
  /// [isConnecting] 是否正在连接中
  static Widget createConnectionStatus({
    required bool isConnected,
    bool hasError = false,
    String? errorText,
    String? connectionDetails,
    bool isConnecting = false,
  }) {
    // 确定状态类型
    StatusType type;
    String message;
    String? description;
    
    if (isConnecting) {
      // 正在连接/断开状态
      type = StatusType.loading;
      message = '正在${isConnected ? '断开' : '连接'}...';
      description = null;
    } else if (isConnected) {
      // 已连接状态
      type = StatusType.success;
      message = '已连接';
      description = connectionDetails;
    } else if (hasError) {
      // 错误状态
      type = StatusType.error;
      message = '连接错误';
      description = errorText;
    } else {
      // 未连接状态
      type = StatusType.neutral;
      message = '未连接';
      description = null;
    }
    
    // 创建状态指示器
    return create(
      message: message,
      type: type,
      description: description,
    );
  }
  
  /// 创建服务器连接状态指示器（专用于显示WebSocket连接状态）
  static Widget createServerStatus({
    required bool isConnected,
    required bool isConnecting, 
    required bool hasError,
    String errorText = '',
    String? serverAddress,
    String? serverPort,
  }) {
    // 构建连接详情
    String? connectionDetails;
    if (isConnected && serverAddress != null && serverPort != null) {
      connectionDetails = '$serverAddress:$serverPort';
    }
    
    return createConnectionStatus(
      isConnected: isConnected,
      hasError: hasError,
      errorText: errorText,
      connectionDetails: connectionDetails,
      isConnecting: isConnecting,
    );
  }
  
  /// 获取状态对应的颜色
  static Color _getStatusColor(StatusType type) {
    switch (type) {
      case StatusType.success:
        return Colors.green;
      case StatusType.error:
        return Colors.red;
      case StatusType.warning:
        return Colors.orange;
      case StatusType.info:
        return Colors.blue;
      case StatusType.loading:
        return Colors.purple;
      case StatusType.neutral:
      default:
        return Colors.grey;
    }
  }
  
  /// 获取状态对应的默认图标
  static Icon _getStatusIcon(StatusType type) {
    switch (type) {
      case StatusType.success:
        return const Icon(Icons.check_circle_outline, size: 16);
      case StatusType.error:
        return const Icon(Icons.error_outline, size: 16);
      case StatusType.warning:
        return const Icon(Icons.warning_amber_outlined, size: 16);
      case StatusType.info:
        return const Icon(Icons.info_outline, size: 16);
      case StatusType.loading:
        return const Icon(Icons.sync, size: 16);
      case StatusType.neutral:
      default:
        return const Icon(Icons.circle_outlined, size: 16);
    }
  }
  
  /// 创建服务状态指示器（用于显示数据库、推理、卡密和键鼠状态）
  static Widget createServiceStatusCard({
    required bool dbStatus,
    required bool inferenceStatus,
    required bool cardKeyStatus,
    required bool keyMouseStatus,
    String? updatedAt,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            '服务状态',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(25, 28, 32, 1.0),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 状态条目
          _buildStatusItem('数据库', dbStatus),
          _buildStatusItem('推理服务', inferenceStatus),
          _buildStatusItem('卡密', cardKeyStatus),
          _buildStatusItem('键鼠', keyMouseStatus),
          
          // 更新时间
          if (updatedAt != null && updatedAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '更新时间: ${_formatDateTime(updatedAt)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// 构建单个状态项目
  static Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color.fromRGBO(25, 28, 32, 1.0),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status ? '正常' : '异常',
            style: TextStyle(
              fontSize: 12,
              color: status ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 格式化日期时间字符串
  static String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
    } catch (e) {
      return dateTimeStr;
    }
  }
  
  /// 在个位数前补零
  static String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }
}

/* 使用示例：

// 基本使用
StatusIndicatorComponent.create(
  message: '操作成功',
  type: StatusType.success,
)

// 带描述的使用
StatusIndicatorComponent.create(
  message: '文件上传成功',
  description: '文件已保存到服务器',
  type: StatusType.success,
)

// 连接状态指示器
StatusIndicatorComponent.createConnectionStatus(
  isConnected: true,
  connectionDetails: '192.168.1.1:8080',
)

// 错误状态指示器
StatusIndicatorComponent.createConnectionStatus(
  isConnected: false,
  hasError: true,
  errorText: '无法连接到服务器：连接超时',
)

// 服务器连接状态
StatusIndicatorComponent.createServerStatus(
  isConnected: true,
  isConnecting: false,
  hasError: false,
  serverAddress: '192.168.1.1',
  serverPort: '8080',
)
*/ 