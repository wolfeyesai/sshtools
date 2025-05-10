import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入模型和控制器
import '../models/terminal_model.dart';
import '../controllers/terminal_controller.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({Key? key}) : super(key: key);

  @override
  _TerminalScreenState createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TerminalController _terminalController;

  @override
  void initState() {
    super.initState();
    // 初始化终端控制器
    _terminalController = Provider.of<TerminalController>(context, listen: false);
    // 如果没有活动会话，创建一个临时会话
    Future.microtask(() {
      final terminalModel = Provider.of<TerminalModel>(context, listen: false);
      if (terminalModel.currentSession == null) {
        _terminalController.connectToDevice('temp');
      }
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendCommand(BuildContext context) {
    final command = _commandController.text;
    if (command.isNotEmpty) {
      // 调用 TerminalController 发送命令
      _terminalController.sendCommand(command);
      _commandController.clear();
      
      // 滚动到底部
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 监听 TerminalModel 的变化
    return Consumer<TerminalModel>(
      builder: (context, terminalModel, child) {
        // 获取当前会话的输出行
        final List<String> outputLines = terminalModel.currentSession?.outputLines ?? [];
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('终端'), // Terminal
            actions: [
              // 添加清空终端按钮
              IconButton(
                icon: Icon(Icons.clear_all),
                onPressed: () => _terminalController.clearOutput(),
                tooltip: '清空终端',
              ),
              // 添加断开连接按钮
              IconButton(
                icon: Icon(Icons.link_off),
                onPressed: () => _terminalController.disconnect(),
                tooltip: '断开连接',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                // 终端输出区域
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: outputLines.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      child: Text(
                        outputLines[index],
                        style: TextStyle(fontFamily: 'Courier', fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1), // 分隔线
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        decoration: InputDecoration(
                          hintText: '输入命令', // Enter command
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendCommand(context), // 按回车发送命令
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send), // Send icon
                      onPressed: () => _sendCommand(context), // 点击按钮发送命令
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 