// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入 SettingsController 和 SettingsModel
import '../controllers/settings_controller.dart';
import '../models/settings_model.dart';
import '../utils/logger.dart';

// 导入一些可能的通用组件，如果需要的话
// import '../component/input_component.dart';
// import '../component/dropdown_component.dart';
// import '../component/slider_component.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用 Provider 获取 SettingsController
    final settingsController = Provider.of<SettingsController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        // TODO: 添加保存按钮
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              settingsController.saveSettings();
              log.i('SettingsScreen', '保存设置');
              // TODO: 显示保存成功提示
            },
            tooltip: '保存设置',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // --- 终端设置 --- 
              Text(
                '终端设置',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // 终端字体大小
              ListTile(
                title: const Text('终端字体大小'),
                subtitle: Slider(
                  value: settingsController.terminalFontSize,
                  min: 8.0,
                  max: 30.0,
                  divisions: 22, // 8到30之间有23个值，divisions比值的数量少1
                  label: settingsController.terminalFontSize.round().toString(),
                  onChanged: (double value) {
                    settingsController.setTerminalFontSize(value);
                  },
                ),
                trailing: Text(settingsController.terminalFontSize.round().toString()),
              ),
              const SizedBox(height: 8),

              // 终端字体
              ListTile(
                title: const Text('终端字体'),
                trailing: DropdownButton<String>(
                  value: settingsController.terminalFontFamily,
                  items: settingsController.availableFontFamilies.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settingsController.setTerminalFontFamily(newValue);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // --- SSH 连接设置 --- 
               Text(
                'SSH 连接设置',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // SSH 端口
              ListTile(
                title: const Text('SSH 端口'),
                trailing: SizedBox( // 使用 SizedBox 限制 TextField 宽度
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    controller: TextEditingController(text: settingsController.sshPort.toString()),
                    onChanged: (value) {
                       final port = int.tryParse(value);
                       if (port != null) {
                         settingsController.setSshPort(port);
                       }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 连接超时
              ListTile(
                title: const Text('连接超时 (秒)'),
                 trailing: SizedBox( // 使用 SizedBox 限制 TextField 宽度
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    controller: TextEditingController(text: settingsController.connectionTimeout.toString()),
                    onChanged: (value) {
                       final timeout = int.tryParse(value);
                       if (timeout != null) {
                         settingsController.setConnectionTimeout(timeout);
                       }
                    },
                     decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 关于 --- 
               Text(
                '关于',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // 版本号
              ListTile(
                title: const Text('版本号'),
                trailing: Text(settingsController.appVersion), // 从 Controller 获取版本号
              ),
              const SizedBox(height: 8),

              // 关于文本
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // 添加内边距
                child: Text(
                  settingsController.aboutText, // 从 Controller 获取关于文本
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 移除旧的 SettingsScreen 占位符类
// class SettingsScreen extends StatelessWidget { ... } 