import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ssh_saved_session_model.dart';
import 'Button_component.dart';

/// SSH会话编辑对话框
class SSHSessionEditDialog extends StatefulWidget {
  /// 要编辑的会话
  final SSHSavedSessionModel? session;
  
  /// 构造函数
  // ignore: use_super_parameters
  const SSHSessionEditDialog({Key? key, this.session}) : super(key: key);
  
  /// 显示SSH会话编辑对话框
  static Future<SSHSavedSessionModel?> show({
    required BuildContext context,
    SSHSavedSessionModel? session,
  }) async {
    return showDialog<SSHSavedSessionModel>(
      context: context,
      builder: (context) => SSHSessionEditDialog(session: session),
    );
  }

  @override
  State<SSHSessionEditDialog> createState() => _SSHSessionEditDialogState();
}

class _SSHSessionEditDialogState extends State<SSHSessionEditDialog> {
  // 表单Key
  final _formKey = GlobalKey<FormState>();
  
  // 文本控制器
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  
  // 密码可见性
  bool _passwordVisible = false;
  
  // 是否是编辑模式
  bool get _isEditMode => widget.session != null;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化文本控制器
    if (_isEditMode) {
      // 编辑模式，填充现有数据
      _nameController = TextEditingController(text: widget.session!.name);
      _hostController = TextEditingController(text: widget.session!.host);
      _portController = TextEditingController(text: widget.session!.port.toString());
      _usernameController = TextEditingController(text: widget.session!.username);
      _passwordController = TextEditingController(text: widget.session!.password);
    } else {
      // 新建模式，使用默认值
      _nameController = TextEditingController();
      _hostController = TextEditingController();
      _portController = TextEditingController(text: '22'); // 默认SSH端口
      _usernameController = TextEditingController();
      _passwordController = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    // 清理控制器
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  /// 保存会话
  void _saveSession() {
    // 验证表单
    if (_formKey.currentState!.validate()) {
      // 创建会话对象
      final session = SSHSavedSessionModel(
        id: _isEditMode ? widget.session!.id : null, // 如果是编辑模式，保留原ID
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        createdAt: _isEditMode ? widget.session!.createdAt : null, // 如果是编辑模式，保留创建时间
      );
      
      // 返回会话对象
      Navigator.of(context).pop(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.computer, color: Colors.blue),
          const SizedBox(width: 8),
          Text(_isEditMode ? '编辑SSH会话' : '添加SSH会话'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 会话名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '会话名称',
                  hintText: '输入会话名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入会话名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 主机地址
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  hintText: '输入主机IP或域名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入主机地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 端口
              TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: '端口',
                  hintText: '输入SSH端口',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入端口';
                  }
                  
                  final port = int.tryParse(value);
                  if (port == null || port <= 0 || port > 65535) {
                    return '端口必须是0-65535之间的数字';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 用户名
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  hintText: '输入SSH用户名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 密码
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '输入SSH密码',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
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
        ButtonComponent.create(
          type: ButtonType.primary,
          label: '保存',
          icon: const Icon(Icons.save, color: Colors.white, size: 16),
          onPressed: _saveSession,
        ),
      ],
    );
  }
} 