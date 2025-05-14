// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../controllers/ssh_command_controller.dart';
import '../controllers/ssh_session_controller.dart';
import '../models/ssh_saved_session_model.dart';
import 'message_component.dart';
import 'Button_component.dart';

/// 导入导出数据类型
enum ImportExportDataType {
  /// 命令
  commands,
  
  /// 会话
  sessions,
  
  /// 全部
  all
}

/// 导入导出管理器
class ImportExportManager {
  /// 显示导入导出对话框
  static Future<void> show(
    BuildContext context, {
    required SSHCommandController commandController,
    required SSHSessionController sessionController,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.import_export, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('数据导入导出'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 数据统计部分
              _buildStatisticsSection(commandController, sessionController),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // 导出部分
              _buildExportSection(context, commandController, sessionController),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // 导入部分
              _buildImportSection(context, commandController, sessionController),
            ],
          ),
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
  
  /// 构建数据统计信息部分
  static Widget _buildStatisticsSection(
    SSHCommandController commandController, 
    SSHSessionController sessionController
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据统计',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SSH命令: ${commandController.commandCount}个'),
                Text('历史连接: ${sessionController.sessionCount}个'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建导出部分
  static Widget _buildExportSection(
    BuildContext context, 
    SSHCommandController commandController, 
    SSHSessionController sessionController
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '导出数据',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '可选择导出命令、会话或全部数据',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 导出命令按钮
            ElevatedButton.icon(
              onPressed: () => _exportData(
                context, 
                commandController, 
                sessionController,
                type: ImportExportDataType.commands,
              ),
              icon: const Icon(Icons.terminal),
              label: const Text('导出命令'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            // 导出会话按钮
            ElevatedButton.icon(
              onPressed: () => _exportData(
                context, 
                commandController, 
                sessionController,
                type: ImportExportDataType.sessions,
              ),
              icon: const Icon(Icons.device_hub),
              label: const Text('导出会话'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            
            // 导出全部按钮
            ButtonComponent.create(
              type: ButtonType.custom,
              label: '导出全部',
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () => _exportData(
                context, 
                commandController, 
                sessionController,
                type: ImportExportDataType.all,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 构建导入部分
  static Widget _buildImportSection(
    BuildContext context, 
    SSHCommandController commandController, 
    SSHSessionController sessionController
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '导入数据',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '从文件或剪贴板导入数据',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 从剪贴板导入按钮
            ElevatedButton.icon(
              onPressed: () => _importFromClipboard(
                context, 
                commandController, 
                sessionController,
              ),
              icon: const Icon(Icons.paste),
              label: const Text('从剪贴板导入'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            
            // 从文件导入按钮
            ElevatedButton.icon(
              onPressed: () => _importFromFile(
                context, 
                commandController, 
                sessionController,
              ),
              icon: const Icon(Icons.file_open),
              label: const Text('从文件导入'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 导出数据到剪贴板或文件
  static Future<void> _exportData(
    BuildContext context, 
    SSHCommandController commandController, 
    SSHSessionController sessionController, {
    required ImportExportDataType type,
    bool toFile = false,
  }) async {
    try {
      // 准备要导出的数据
      final Map<String, dynamic> exportData = {};
      
      if (type == ImportExportDataType.commands || type == ImportExportDataType.all) {
        final commandsJson = commandController.exportCommandsToJson();
        final commandsList = json.decode(commandsJson) as List;
        exportData['commands'] = commandsList;
      }
      
      if (type == ImportExportDataType.sessions || type == ImportExportDataType.all) {
        final sessionsList = sessionController.sessions.map((s) => s.toJson()).toList();
        exportData['sessions'] = sessionsList;
      }
      
      // 添加元数据
      exportData['exportTime'] = DateTime.now().toIso8601String();
      exportData['version'] = '1.0';
      
      // 转换为JSON字符串
      final jsonString = json.encode(exportData);
      
      // 导出到剪贴板或文件
      if (toFile) {
        await _exportToFile(context, jsonString, type);
      } else {
        await _copyToClipboard(context, jsonString, type);
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '导出数据失败: $e',
        );
      }
    }
  }
  
  /// 复制数据到剪贴板
  static Future<void> _copyToClipboard(
    BuildContext context, 
    String jsonString,
    ImportExportDataType type,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      String message = '数据已复制到剪贴板';
      switch (type) {
        case ImportExportDataType.commands:
          message = '命令数据已复制到剪贴板';
          break;
        case ImportExportDataType.sessions:
          message = '会话数据已复制到剪贴板';
          break;
        case ImportExportDataType.all:
          message = '全部数据已复制到剪贴板';
          break;
      }
      
      if (context.mounted) {
        MessageComponentFactory.showSuccess(
          context,
          message: message,
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '复制到剪贴板失败: $e',
        );
      }
    }
  }
  
  /// 导出数据到文件
  static Future<void> _exportToFile(
    BuildContext context, 
    String jsonString,
    ImportExportDataType type,
  ) async {
    try {
      // 确定文件名
      String fileName = 'ssh_data.json';
      switch (type) {
        case ImportExportDataType.commands:
          fileName = 'ssh_commands.json';
          break;
        case ImportExportDataType.sessions:
          fileName = 'ssh_sessions.json';
          break;
        case ImportExportDataType.all:
          fileName = 'ssh_all_data.json';
          break;
      }
      
      // 选择保存路径
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (outputPath == null) {
        // 用户取消选择
        return;
      }
      
      // 确保文件扩展名为.json
      if (!outputPath.endsWith('.json')) {
        outputPath += '.json';
      }
      
      // 写入文件
      final file = File(outputPath);
      await file.writeAsString(jsonString);
      
      String message = '数据已保存到文件';
      switch (type) {
        case ImportExportDataType.commands:
          message = '命令数据已保存到文件';
          break;
        case ImportExportDataType.sessions:
          message = '会话数据已保存到文件';
          break;
        case ImportExportDataType.all:
          message = '全部数据已保存到文件';
          break;
      }
      
      if (context.mounted) {
        MessageComponentFactory.showSuccess(
          context,
          message: message,
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '保存到文件失败: $e',
        );
      }
    }
  }
  
  /// 从剪贴板导入数据
  static Future<void> _importFromClipboard(
    BuildContext context, 
    SSHCommandController commandController, 
    SSHSessionController sessionController,
  ) async {
    try {
      // 获取剪贴板内容
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final jsonString = clipboardData?.text;
      
      if (jsonString == null || jsonString.isEmpty) {
        if (context.mounted) {
          MessageComponentFactory.showError(
            context,
            message: '剪贴板为空或不包含有效的数据',
          );
        }
        return;
      }
      
      // 导入数据
      final success = await _importData(
        context, 
        jsonString, 
        commandController, 
        sessionController,
      );
      
      if (success && context.mounted) {
        MessageComponentFactory.showSuccess(
          context,
          message: '数据已成功从剪贴板导入',
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '从剪贴板导入数据失败: $e',
        );
      }
    }
  }
  
  /// 从文件导入数据
  static Future<void> _importFromFile(
    BuildContext context, 
    SSHCommandController commandController, 
    SSHSessionController sessionController,
  ) async {
    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.single.path == null) {
        // 用户取消选择
        return;
      }
      
      // 读取文件内容
      final filePath = result.files.single.path!;
      final file = File(filePath);
      final jsonString = await file.readAsString();
      
      // 导入数据
      final success = await _importData(
        context, 
        jsonString, 
        commandController, 
        sessionController,
      );
      
      if (success && context.mounted) {
        MessageComponentFactory.showSuccess(
          context,
          message: '数据已成功从文件导入',
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '从文件导入数据失败: $e',
        );
      }
    }
  }
  
  /// 导入数据
  static Future<bool> _importData(
    BuildContext context, 
    String jsonString, 
    SSHCommandController commandController, 
    SSHSessionController sessionController,
  ) async {
    try {
      // 解析JSON
      final Map<String, dynamic> importedData = json.decode(jsonString);
      
      int commandsImported = 0;
      int sessionsImported = 0;
      
      // 导入命令
      if (importedData.containsKey('commands')) {
        final commandsJson = json.encode(importedData['commands']);
        final oldCount = commandController.commandCount;
        final success = await commandController.importCommandsFromJson(commandsJson);
        
        if (success) {
          commandsImported = commandController.commandCount - oldCount;
          // 确保命令被保存到持久化存储
          await commandController.saveCommands();
          debugPrint('导入后已保存 $commandsImported 个命令到持久化存储');
        }
      } else if (importedData is List) {
        // 兼容旧格式的命令数据
        final commandsJson = jsonString;
        final oldCount = commandController.commandCount;
        final success = await commandController.importCommandsFromJson(commandsJson);
        
        if (success) {
          commandsImported = commandController.commandCount - oldCount;
          // 确保命令被保存到持久化存储
          await commandController.saveCommands();
          debugPrint('导入后已保存 $commandsImported 个命令到持久化存储');
        }
      }
      
      // 导入会话
      if (importedData.containsKey('sessions')) {
        final sessionsList = importedData['sessions'] as List;
        // 暂存要导入的会话
        final List<SSHSavedSessionModel> sessionsToImport = [];
        
        for (final sessionJson in sessionsList) {
          try {
            final session = sessionJson is Map<String, dynamic> 
                ? sessionJson 
                : Map<String, dynamic>.from(sessionJson);
                
            sessionsToImport.add(SSHSavedSessionModel.fromJson(session));
          } catch (e) {
            debugPrint('解析会话失败: $e');
          }
        }
        
        // 批量导入会话
        if (sessionsToImport.isNotEmpty) {
          debugPrint('准备导入 ${sessionsToImport.length} 个会话');
          for (final session in sessionsToImport) {
            await sessionController.addSession(session);
            sessionsImported++;
            debugPrint('已导入会话: ${session.name} (${session.host}:${session.port})');
          }
          
          // 确保会话被保存到持久化存储
          await sessionController.saveSessions();
          debugPrint('导入后已保存 $sessionsImported 个会话到持久化存储');
        }
      }
      
      // 额外的强制保存 - 确保数据已写入持久化存储，并重新加载
      if (commandsImported > 0) {
        debugPrint('再次执行命令保存以确保数据持久化');
        await commandController.saveCommands();
        // 强制重新加载命令数据
        await commandController.loadCommands();
        debugPrint('导入完成后强制重新加载了${commandController.commandCount}个命令');
      }
      
      if (sessionsImported > 0) {
        debugPrint('再次执行会话保存以确保数据持久化');
        await sessionController.saveSessions();
        // 强制重新加载会话数据
        await sessionController.loadSessions();
        debugPrint('导入完成后强制重新加载了${sessionController.sessionCount}个会话');
      }
      
      // 显示导入结果
      if (context.mounted) {
        if (commandsImported > 0 || sessionsImported > 0) {
          String message = '';
          if (commandsImported > 0) {
            message += '导入了 $commandsImported 个命令';
          }
          
          if (sessionsImported > 0) {
            if (message.isNotEmpty) {
              message += '，';
            }
            message += '导入了 $sessionsImported 个会话';
          }
          
          MessageComponentFactory.showSuccess(
            context,
            message: message,
          );
          return true;
        } else {
          MessageComponentFactory.showInfo(
            context,
            message: '没有导入新的数据',
          );
          return false;
        }
      }
      
      return commandsImported > 0 || sessionsImported > 0;
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '导入数据失败: $e',
        );
      }
      return false;
    }
  }
} 