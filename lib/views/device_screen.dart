import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入模型和控制器
import '../models/device_model.dart';
import '../controllers/device_controller.dart';
import '../utils/logger.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late DeviceController _deviceController;
  late DeviceModel _deviceModel;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 只在第一次初始化时加载设备
    if (!_initialized) {
      _deviceController = Provider.of<DeviceController>(context);
      _deviceModel = Provider.of<DeviceModel>(context);
      _loadDevices();
      _initialized = true;
    }
  }

  void _loadDevices() {
    // 使用 Future.microtask 避免在构建过程中调用 setState
    Future.microtask(() {
      _deviceController.loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    log.i('DeviceScreen', '设备列表更新');
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: 实现添加设备逻辑
            },
          ),
        ],
      ),
      body: Consumer<DeviceModel>(
        builder: (_, deviceModel, __) {
          if (deviceModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (deviceModel.devices.isEmpty) {
            return const Center(
              child: Text('没有设备', style: TextStyle(fontSize: 20)),
            );
          }

          return ListView.builder(
            itemCount: deviceModel.devices.length,
            itemBuilder: (context, index) {
              final device = deviceModel.devices[index];
              return ListTile(
                leading: const Icon(Icons.computer),
                title: Text(device.name),
                subtitle: Text('${device.host}:${device.port}'),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    // TODO: 导航到终端页面并连接设备
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 实现添加新设备表单/对话框
        },
        child: const Icon(Icons.add),
        tooltip: '添加新设备',
      ),
    );
  }
} 