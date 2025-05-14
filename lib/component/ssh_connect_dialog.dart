// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ip_model.dart';
import '../views/ssh_terminal_screen.dart';
import 'Button_component.dart';
import 'package:provider/provider.dart';
import '../controllers/ssh_controller.dart';

/// SSH连接模式
enum ConnectionMode { defaultMode, customMode }

/// SSH连接对话框
class SSHConnectDialog extends StatefulWidget {
  /// 要连接的设备
  final IPDeviceModel device;
  
  /// 连接回调
  final Function(String username, String password, int port)? onConnect;
  
  /// 构造函数
  const SSHConnectDialog({
    super.key,
    required this.device,
    this.onConnect,
  });
  
  /// 显示SSH连接对话框
  static Future<void> show(
    BuildContext context, 
    IPDeviceModel device, 
    {Function(String username, String password, int port)? onConnect}
  ) async {
    return showDialog(
      context: context,
      builder: (context) => SSHConnectDialog(
        device: device,
        onConnect: onConnect,
      ),
    );
  }

  @override
  State<SSHConnectDialog> createState() => _SSHConnectDialogState();
}

class _SSHConnectDialogState extends State<SSHConnectDialog> {
  // 默认凭据
  static const String _defaultUsername = 'bred';
  static const String _defaultPassword = 'bred';
  
  // 当前选择的连接模式
  ConnectionMode _selectedMode = ConnectionMode.defaultMode;
  
  // 输入控制器
  final TextEditingController _usernameController = TextEditingController(text: _defaultUsername);
  final TextEditingController _passwordController = TextEditingController(text: _defaultPassword);
  final TextEditingController _portController = TextEditingController();
  
  // 密码可见性
  bool _passwordVisible = false;
  
  // 错误信息
  String? _error;
  
  // 连接状态
  bool _isConnecting = false;
  
  @override
  void initState() {
    super.initState();
    // 设置默认端口
    _portController.text = '${widget.device.sshInfo?.port ?? 22}';
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.terminal, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SSH连接'),
                Text(
                  widget.device.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 连接模式选择
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '连接模式',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<ConnectionMode>(
                      title: const Text('使用默认凭据'),
                      subtitle: const Text('使用系统默认的SSH凭据'),
                      value: ConnectionMode.defaultMode,
                      groupValue: _selectedMode,
                      onChanged: (ConnectionMode? value) {
                        if (value != null) {
                          setState(() {
                            _selectedMode = value;
                            // 重置为默认用户名密码
                            _usernameController.text = _defaultUsername;
                            _passwordController.text = _defaultPassword;
                          });
                        }
                      },
                      dense: true,
                    ),
                    RadioListTile<ConnectionMode>(
                      title: const Text('使用自定义凭据'),
                      subtitle: const Text('自定义用户名和密码'),
                      value: ConnectionMode.customMode,
                      groupValue: _selectedMode,
                      onChanged: (ConnectionMode? value) {
                        if (value != null) {
                          setState(() {
                            _selectedMode = value;
                            // 清空凭据
                            _usernameController.text = '';
                            _passwordController.text = '';
                          });
                        }
                      },
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            
            // 连接信息表单
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '连接信息',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // 用户名
                    TextField(
                      controller: _usernameController,
                      enabled: _selectedMode == ConnectionMode.customMode,
                      decoration: InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 密码
                    TextField(
                      controller: _passwordController,
                      enabled: _selectedMode == ConnectionMode.customMode,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: '密码',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                    ),
                    const SizedBox(height: 16),
                    
                    // 端口
                    TextField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: '端口',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.settings_ethernet),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 取消按钮
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        
        // 连接按钮
        ButtonComponent.create(
          type: ButtonType.primary,
          label: '连接',
          icon: const Icon(Icons.login, color: Colors.white, size: 16),
          onPressed: _connect,
        ),
      ],
    );
  }

  /// 执行连接操作
  Future<void> _connect() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _portController.text.isEmpty) {
      setState(() {
        _error = '请填写必要的连接信息';
      });
      return;
    }
    
    setState(() {
      _isConnecting = true;
      _error = null;
    });
    
    try {
      final sshController = Provider.of<SSHController>(context, listen: false);
      
      final connected = await sshController.connect(
        host: widget.device.ipAddress,
        port: int.tryParse(_portController.text) ?? 22,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        context: context,
      );
      
      if (!mounted) return;
      
      if (connected) {
        // 连接成功，调用onConnect回调
        if (widget.onConnect != null) {
          widget.onConnect!(
            _usernameController.text.trim(),
            _passwordController.text,
            int.tryParse(_portController.text) ?? 22,
          );
          
          // 给回调一些时间处理
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _isConnecting = false;
          _error = '连接失败，请检查连接信息';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isConnecting = false;
        _error = '连接错误: $e';
      });
    }
  }
} 