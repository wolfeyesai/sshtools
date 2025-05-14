// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ip_model.dart';
import 'Button_component.dart';
import 'message_component.dart';

/// 扫描结果列表组件
class ScanResultComponent extends StatelessWidget {
  /// 扫描结果标题
  final String title;
  
  /// 扫描结果列表
  final List<IPDeviceModel> devices;
  
  /// 正在扫描状态
  final bool isScanning;
  
  /// 扫描状态信息
  final String? statusText;
  
  /// 扫描进度 (0-1)
  final double? scanProgress;
  
  /// 清除结果回调
  final VoidCallback? onClearResults;
  
  /// 连接设备回调
  final Function(IPDeviceModel device)? onConnectDevice;
  
  /// 空状态提示文本
  final String emptyStateText;
  
  /// 构造函数
  const ScanResultComponent({
    super.key,
    required this.title,
    required this.devices,
    this.isScanning = false,
    this.statusText,
    this.scanProgress,
    this.onClearResults,
    this.onConnectDevice,
    this.emptyStateText = '暂无扫描结果',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            _buildHeaderRow(context),
            
            // 状态信息和进度条
            if (statusText != null && statusText!.isNotEmpty || isScanning)
              _buildStatusSection(context),
            
            // 扫描结果列表
            Expanded(
              child: _buildResultsList(context),
            ),
            
            // 底部操作栏
            if (!isScanning && devices.isNotEmpty && onClearResults != null)
              _buildBottomActions(context),
          ],
        ),
      ),
    );
  }
  
  /// 构建标题栏
  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 标题
        Row(
          children: [
            const Icon(Icons.developer_board, color: Colors.blue, size: 14),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        // 找到的设备数量
        if (devices.isNotEmpty && !isScanning)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '找到 ${devices.length} 台设备',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
      ],
    );
  }
  
  /// 构建状态信息和进度条
  Widget _buildStatusSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态文本
          if (statusText != null && statusText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1, bottom: 1),
              child: Text(
                statusText!,
                style: TextStyle(
                  fontSize: 11,
                  color: isScanning ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          
          // 进度条
          if (isScanning && scanProgress != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 1),
              child: LinearProgressIndicator(
                value: scanProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
  
  /// 构建底部操作栏
  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: onClearResults,
            icon: const Icon(Icons.clear_all, size: 12),
            label: const Text(
              '清除结果',
              style: TextStyle(fontSize: 11),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建结果列表
  Widget _buildResultsList(BuildContext context) {
    if (devices.isEmpty) {
      return isScanning
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isScanning)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      '正在扫描网段...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      emptyStateText,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return _buildDeviceItem(context, device);
        },
      ),
    );
  }
  
  /// 构建设备列表项
  Widget _buildDeviceItem(BuildContext context, IPDeviceModel device) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 500;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 4.0),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            // 设备图标
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4.0),
              child: const Icon(
                Icons.computer,
                color: Colors.blue,
                size: 16,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 设备信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IP和复制按钮
                  Row(
                    children: [
                      Text(
                        device.ipAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 3),
                      InkWell(
                        onTap: () {
                          _copyToClipboard(context, device.ipAddress);
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 1),
                  
                  // 设备名称和系统信息
                  Text(
                    device.sshInfo?.name ?? device.hostname,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  
                  if (device.sshInfo?.os != null && device.sshInfo!.os.isNotEmpty)
                    Text(
                      '系统: ${device.sshInfo!.os}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            
            // 连接按钮
            if (onConnectDevice != null)
              SizedBox(
                height: 28,
                child: isLargeScreen ? 
                  ElevatedButton.icon(
                    onPressed: () => onConnectDevice!(device),
                    icon: const Icon(Icons.login, size: 12, color: Colors.white),
                    label: const Text(
                      '连接',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  )
                  :
                  ElevatedButton(
                    onPressed: () => onConnectDevice!(device),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(0),
                      minimumSize: const Size(28, 28),
                    ),
                    child: const Icon(
                      Icons.login,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// 复制文本到剪贴板
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    MessageComponentFactory.showSuccess(
      context, 
      message: '已复制到剪贴板: $text',
    );
  }
} 