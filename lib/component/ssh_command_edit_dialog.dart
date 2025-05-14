// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../models/ssh_command_model.dart';

/// SSH命令编辑对话框
class SSHCommandEditDialog extends StatefulWidget {
  /// 要编辑的命令，为null时表示创建新命令
  final SSHCommandModel? command;
  
  /// 构造函数
  const SSHCommandEditDialog({
    Key? key,
    this.command,
  }) : super(key: key);
  
  /// 显示命令编辑对话框
  static Future<SSHCommandModel?> show(
    BuildContext context, {
    SSHCommandModel? command,
  }) async {
    return showDialog<SSHCommandModel>(
      context: context,
      builder: (context) => SSHCommandEditDialog(command: command),
    );
  }
  
  @override
  State<SSHCommandEditDialog> createState() => _SSHCommandEditDialogState();
}

class _SSHCommandEditDialogState extends State<SSHCommandEditDialog> {
  /// 表单键
  final _formKey = GlobalKey<FormState>();
  
  /// 控制器
  late TextEditingController _nameController;
  late TextEditingController _commandController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  
  /// 命令类型
  late SSHCommandType _selectedType;
  
  /// 收藏状态
  late bool _isFavorite;
  
  /// 标签列表
  late List<String> _tags;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化控制器
    _nameController = TextEditingController(text: widget.command?.name ?? '');
    _commandController = TextEditingController(text: widget.command?.command ?? '');
    _descriptionController = TextEditingController(text: widget.command?.description ?? '');
    _tagController = TextEditingController();
    
    // 初始化类型和收藏状态
    _selectedType = widget.command?.type ?? SSHCommandType.custom;
    _isFavorite = widget.command?.isFavorite ?? false;
    
    // 初始化标签
    _tags = widget.command?.tags != null 
        ? List<String>.from(widget.command!.tags) 
        : [];
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }
  
  /// 保存命令
  void _saveCommand() {
    if (_formKey.currentState!.validate()) {
      final command = widget.command != null
          ? widget.command!.copyWith(
              name: _nameController.text.trim(),
              command: _commandController.text.trim(),
              description: _descriptionController.text.trim(),
              type: _selectedType,
              isFavorite: _isFavorite,
              tags: _tags,
            )
          : SSHCommandModel(
              name: _nameController.text.trim(),
              command: _commandController.text.trim(),
              description: _descriptionController.text.trim(),
              type: _selectedType,
              isFavorite: _isFavorite,
              tags: _tags,
            );
      
      Navigator.of(context).pop(command);
    }
  }
  
  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }
  
  /// 移除标签
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }
  
  /// 构建标签列表
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '标签',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 标签输入框
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: '输入标签',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            // 添加标签按钮
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
              tooltip: '添加标签',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 标签展示区域
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeTag(tag),
              backgroundColor: Colors.blue.shade100,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  /// 构建命令类型选择器
  Widget _buildTypeSelector() {
    return DropdownButtonFormField<SSHCommandType>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: '命令类型',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: SSHCommandType.values.map((type) {
        String label;
        IconData icon;
        
        switch (type) {
          case SSHCommandType.general:
            label = '通用命令';
            icon = Icons.terminal;
            break;
          case SSHCommandType.system:
            label = '系统命令';
            icon = Icons.computer;
            break;
          case SSHCommandType.network:
            label = '网络命令';
            icon = Icons.wifi;
            break;
          case SSHCommandType.file:
            label = '文件操作';
            icon = Icons.folder;
            break;
          case SSHCommandType.custom:
            label = '自定义';
            icon = Icons.build;
            break;
        }
        
        return DropdownMenuItem<SSHCommandType>(
          value: type,
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      }).toList(),
      onChanged: (type) {
        if (type != null) {
          setState(() {
            _selectedType = type;
          });
        }
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.command != null;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.add,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(isEditing ? '编辑SSH命令' : '创建SSH命令'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 命令名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '命令名称',
                  hintText: '输入一个易于记忆的名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入命令名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 命令内容
              TextFormField(
                controller: _commandController,
                decoration: const InputDecoration(
                  labelText: '命令内容',
                  hintText: '输入SSH命令',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入命令内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 命令描述
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '命令描述',
                  hintText: '描述命令的用途（可选）',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // 命令类型
              _buildTypeSelector(),
              const SizedBox(height: 16),
              
              // 标签部分
              _buildTagsSection(),
              const SizedBox(height: 16),
              
              // 收藏选项
              SwitchListTile(
                title: const Text('添加到收藏'),
                subtitle: const Text('收藏的命令会显示在快速访问区域'),
                value: _isFavorite,
                secondary: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? Colors.amber : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton.icon(
          onPressed: _saveCommand,
          icon: Icon(isEditing ? Icons.save : Icons.add),
          label: Text(isEditing ? '保存' : '创建'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
} 