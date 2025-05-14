// ignore_for_file: use_super_parameters, unnecessary_cast, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 提示组件，包含各种便捷的对话框和提示工具
class PromptComponent {
  /// 显示请求信息的对话框
  /// 
  /// [context] - 上下文
  /// [title] - 对话框标题
  /// [requestData] - 请求数据
  static void showRequestInfo(
    BuildContext context, 
    String title, 
    Map<String, dynamic> requestData
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$title 请求信息'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('请求数据:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                  child: Text(
                    _formatJson(requestData),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('复制'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _formatJson(requestData)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请求信息已复制到剪贴板'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  /// 格式化JSON数据
  static String _formatJson(Map<String, dynamic> json) {
    String result = '';
    json.forEach((key, value) {
      if (value is Map) {
        result += '$key: {\n';
        (value as Map).forEach((k, v) {
          result += '  $k: $v,\n';
        });
        result += '},\n';
      } else {
        result += '$key: $value,\n';
      }
    });
    return result;
  }
  
  /// 显示确认对话框
  /// 
  /// [context] - 上下文
  /// [title] - 对话框标题
  /// [message] - 对话框内容
  /// [onConfirm] - 确认回调
  /// [onCancel] - 取消回调
  /// [confirmButtonText] - 确认按钮文本
  /// [cancelButtonText] - 取消按钮文本
  /// [isDangerousAction] - 是否为危险操作
  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmButtonText = '确认',
    String cancelButtonText = '取消',
    bool isDangerousAction = false,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onCancel != null) {
                  onCancel();
                }
              },
              child: Text(cancelButtonText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: TextButton.styleFrom(
                foregroundColor: isDangerousAction ? Colors.red : null,
              ),
              child: Text(confirmButtonText),
            ),
          ],
        );
      },
    );
  }
}
