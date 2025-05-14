// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sidebar_provider.dart';

/// 空终端组件 - 在没有SSH会话时显示
class EmptyTerminalWidget extends StatelessWidget {
  const EmptyTerminalWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.terminal,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            '无活动终端连接',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请在IP管理页面选择设备以创建SSH连接',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // 切换到IP页面
              Provider.of<SidebarProvider>(context, listen: false).setIndex(0);
            },
            icon: const Icon(Icons.search),
            label: const Text('查找设备'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
} 