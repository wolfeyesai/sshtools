// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:getwidget/getwidget.dart';
import '../models/ssh_footer_model.dart';
import '../controllers/ssh_footer_controller.dart';
import '../models/ssh_command_model.dart';
import '../component/Button_component.dart';
import '../component/card_component.dart';

/// SSH终端页尾视图组件
class SSHFooterView extends StatelessWidget {
  /// 文本输入控制器
  final TextEditingController _textController = TextEditingController();
  
  /// 构造函数
  // ignore: use_super_parameters
  SSHFooterView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // 监听模型变化
    return Consumer<SSHFooterModel>(
      builder: (context, footerModel, child) {
        // 直接获取控制器，避免在action方法中每次都获取
        final footerController = Provider.of<SSHFooterController>(context, listen: false);
        
        // 每次构建时同步文本控制器的值与模型中的值
        if (_textController.text != footerModel.commandText) {
          _textController.text = footerModel.commandText;
        }
        
        // 监听文本变化并更新模型
        _textController.addListener(() {
          if (footerModel.commandText != _textController.text) {
            footerController.updateCommandText(_textController.text);
          }
        });
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 快捷命令区域
              if (footerModel.showQuickCommands)
                _buildQuickCommands(context, footerModel, footerController),
              
              // 命令输入行
              Row(
                children: [
                  // 命令输入框
                  Expanded(
                    child: _buildCommandInput(context, footerModel, footerController),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 命令菜单按钮
                  _buildMenuButton(context, footerModel, footerController),
                  
                  const SizedBox(width: 12),
                  
                  // 发送按钮
                  _buildSendButton(context, footerModel, footerController),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 构建命令输入框
  Widget _buildCommandInput(
    BuildContext context,
    SSHFooterModel model,
    SSHFooterController controller
  ) {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        hintText: '输入命令',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // 添加命令历史按钮
        suffixIcon: Container(
          margin: const EdgeInsets.all(4),
          child: GFIconButton(
            icon: Icon(
              Icons.history,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            type: GFButtonType.solid,
            onPressed: model.isHistoryEnabled 
                ? () => controller.showCommandHistory(context)
                : null,
            shape: GFIconButtonShape.circle,
            size: GFSize.SMALL,
            color: Theme.of(context).colorScheme.primary,
            boxShadow: BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ),
        ),
        fillColor: Theme.of(context).colorScheme.surface,
        filled: true,
      ),
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      enabled: model.isConnected,
      onSubmitted: (_) {
        if (model.isCommandEnabled) {
          controller.sendCommand(context);
        }
      },
    );
  }
  
  /// 构建命令菜单按钮
  Widget _buildMenuButton(
    BuildContext context,
    SSHFooterModel model,
    SSHFooterController controller
  ) {
    return ButtonComponent.create(
      type: model.isMenuEnabled 
          ? ButtonType.primary 
          : ButtonType.disabled,
      label: '',
      icon: const Icon(
        Icons.menu,
        size: 20,
        color: Colors.white,
      ),
      shape: ButtonShape.pill,
      size: ButtonSize.medium,
      backgroundColor: Colors.indigo,
      onPressed: model.isMenuEnabled 
          ? () => controller.showCommandMenu(context)
          : null,
    );
  }
  
  /// 构建发送按钮
  Widget _buildSendButton(
    BuildContext context,
    SSHFooterModel model,
    SSHFooterController controller
  ) {
    return ButtonComponent.create(
      type: model.isCommandEnabled 
          ? ButtonType.primary 
          : ButtonType.disabled,
      label: '发送',
      icon: const Icon(
        Icons.send, 
        size: 16, 
        color: Colors.white
      ),
      shape: ButtonShape.pill,
      size: ButtonSize.medium,
      onPressed: model.isCommandEnabled 
          ? () => controller.sendCommand(context)
          : null,
    );
  }
  
  /// 构建快捷命令区域
  Widget _buildQuickCommands(
    BuildContext context,
    SSHFooterModel model,
    SSHFooterController controller
  ) {
    final quickCommands = model.quickCommands;
    
    if (quickCommands.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快捷命令标题
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '快捷命令',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // 快捷命令列表
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCommands.map((cmd) => _buildQuickCommandChip(
              context,
              cmd,
              controller,
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  /// 构建快捷命令芯片
  Widget _buildQuickCommandChip(
    BuildContext context,
    SSHCommandModel command,
    SSHFooterController controller
  ) {
    final color = _getCommandTypeColor(command.type);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => controller.handleQuickCommand(context, command),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCommandTypeIcon(command.type),
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                command.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 获取命令类型图标
  IconData _getCommandTypeIcon(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.general:
        return Icons.terminal;
      case SSHCommandType.system:
        return Icons.computer;
      case SSHCommandType.network:
        return Icons.wifi;
      case SSHCommandType.file:
        return Icons.folder;
      case SSHCommandType.custom:
        return Icons.build;
    }
  }
  
  /// 获取命令类型颜色
  Color _getCommandTypeColor(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.general:
        return Colors.blue;
      case SSHCommandType.system:
        return Colors.green;
      case SSHCommandType.network:
        return Colors.orange;
      case SSHCommandType.file:
        return Colors.amber;
      case SSHCommandType.custom:
        return Colors.purple;
    }
  }
} 