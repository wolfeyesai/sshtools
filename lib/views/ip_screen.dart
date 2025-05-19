// ignore_for_file: use_super_parameters, unused_import, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/ip_controller.dart';
import '../controllers/ssh_controller.dart';
import '../providers/sidebar_provider.dart';
import '../component/Button_component.dart';
import '../component/progress_bar_component.dart';
import '../component/message_component.dart';
import '../component/scan_result_component.dart';
import '../component/ssh_connect_dialog.dart';
import '../models/ip_model.dart';
import 'ssh_terminal_screen.dart';
import '../component/ssh_session_history.dart';
import '../component/import_export_manager.dart';
import '../controllers/ssh_command_controller.dart';
import '../controllers/ssh_session_controller.dart';

/// IP地址信息页面
class IPPage extends StatefulWidget {
  /// 页面标题
  static const String pageTitle = 'IP地址与SSH设备';
  
  /// 路由名称
  static const String routeName = '/ip-info';

  /// 构造函数
  const IPPage({Key? key}) : super(key: key);

  @override
  State<IPPage> createState() => _IPPageState();
}

class _IPPageState extends State<IPPage> with SingleTickerProviderStateMixin {
  // 自定义网段输入控制器
  final TextEditingController _subnetController = TextEditingController();
  
  // 标签控制器
  late TabController _tabController;
  
  // 用于限制日志打印频率
  static DateTime? _lastLogTime;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 添加标签切换监听
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // 切换到历史连接标签时，强制刷新会话列表
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 节流日志打印 - 只有超过5秒才打印
            final now = DateTime.now();
            final shouldLog = _lastLogTime == null || now.difference(_lastLogTime!).inSeconds > 5;
            
            if (shouldLog) {
              _lastLogTime = now;
              debugPrint('IPPage: 切换到历史连接标签页，立即刷新会话数据');
            }
            
            final sessionController = Provider.of<SSHSessionController>(context, listen: false);
            // 使用 Future.delayed 确保UI渲染完成后再加载数据
            Future.delayed(Duration.zero, () {
              sessionController.loadSessions();
            });
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    // 释放控制器
    _subnetController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 获取全局的命令和会话控制器
    final commandController = Provider.of<SSHCommandController>(context, listen: false);
    final sessionController = Provider.of<SSHSessionController>(context, listen: false);
    
    // 确保会话控制器已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sessionController.init();
    });
    
    return ChangeNotifierProvider(
      create: (_) => IPController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(IPPage.pageTitle),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // 导入导出按钮
            IconButton(
              icon: const Icon(Icons.import_export),
              tooltip: '导入/导出数据',
              onPressed: () async {
                // 显示导入导出对话框
                await ImportExportManager.show(
                  context,
                  commandController: commandController,
                  sessionController: sessionController,
                );
                
                // 导入导出完成后，刷新会话列表
                if (mounted) {
                  sessionController.init();
                  // 如果当前在历史连接标签页，则强制刷新UI
                  if (_tabController.index == 1) {
                    setState(() {});
                  }
                }
              },
            ),
            
            // 更多操作按钮
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新加载',
              onPressed: () {
                final controller = Provider.of<IPController>(context, listen: false);
                controller.refreshIP();
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: Consumer<IPController>(
              builder: (context, controller, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // IP地址和扫描控制区域
                    _buildIPAddressCard(context, controller),
                    
                    const SizedBox(height: 8),
                    
                    // 扫描结果列表
                    Expanded(
                      child: Column(
                        children: [
                          // 标签栏
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.search, size: 16),
                                text: '扫描结果',
                                height: 36,
                              ),
                              Tab(
                                icon: Icon(Icons.history, size: 16),
                                text: '历史连接',
                                height: 36,
                              ),
                            ],
                            indicatorColor: Theme.of(context).primaryColor,
                            labelColor: Theme.of(context).primaryColor,
                            indicatorWeight: 2,
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            unselectedLabelStyle: const TextStyle(fontSize: 12),
                          ),
                          
                          // 标签内容
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // 扫描结果
                                ScanResultComponent(
                                  title: 'SSH设备扫描结果',
                                  devices: controller.scannedSSHDevices,
                                  isScanning: controller.isScanning,
                                  statusText: controller.scanStatus,
                                  scanProgress: controller.scanProgress,
                                  emptyStateText: '暂无扫描结果，点击"扫描"开始扫描',
                                  onClearResults: controller.isScanning ? null : controller.clearScanResults,
                                  onConnectDevice: (device) => _connectToSSH(context, device),
                                ),
                                
                                // 历史连接
                                Consumer<SSHSessionController>(
                                  builder: (context, sessionController, _) {
                                    // 限制日志打印频率
                                    final now = DateTime.now();
                                    final shouldLog = _lastLogTime == null || now.difference(_lastLogTime!).inSeconds > 5;
                                    
                                    if (shouldLog) {
                                      _lastLogTime = now;
                                      debugPrint('IPPage: 构建历史连接标签页组件');
                                    }
                                    
                                    // 确保不在build方法中执行异步操作，改用延迟处理
                                    if (_tabController.index == 1) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        sessionController.loadSessions();
                                      });
                                    }
                                    return const SSHSessionHistory();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建IP地址和扫描控制区域
  Widget _buildIPAddressCard(BuildContext context, IPController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 标题
                const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '本机IP地址',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // 刷新按钮（圆形）
                SizedBox(
                  height: 30,
                  width: 30,
                  child: Material(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () async {
                        await controller.refreshIP();
                        if (context.mounted) {
                          MessageComponentFactory.showSuccess(
                            context, 
                            message: 'IP地址已刷新',
                          );
                        }
                      },
                      customBorder: const CircleBorder(),
                      child: const Center(
                        child: Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // IP地址显示区域
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 网络适配器选择器
                  if (controller.networkAdapters.isNotEmpty)
                    _buildNetworkAdapterSelector(context, controller),
                  
                  // IP地址展示
                  Row(
                    children: [
                      // IP地址文本
                      Expanded(
                        child: controller.isLoading 
                          ? ProgressBarComponent.createIndeterminateLoader(
                              type: ProgressBarType.circular,
                              size: ProgressBarSize.small,
                              color: Theme.of(context).primaryColor,
                            )
                          : controller.deviceIP != null
                            ? GestureDetector(
                                onTap: () {
                                  _copyToClipboard(context, controller.deviceIP!.ipAddress);
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.computer, color: Colors.grey, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          controller.deviceIP!.ipAddress,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    // 显示网络接口名称
                                    Row(
                                      children: [
                                        const Icon(Icons.settings_ethernet, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          controller.deviceIP!.hostname,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const Text(
                                '未能获取IP地址',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                      ),
                      
                      // 操作按钮容器
                      if (controller.deviceIP != null && !controller.isLoading)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 复制按钮
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.blue, size: 18),
                              tooltip: '复制IP地址',
                              onPressed: () {
                                _copyToClipboard(context, controller.deviceIP!.ipAddress);
                              },
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            
                            // 扫描当前网段按钮
                            SizedBox(
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (controller.isScanning) {
                                    controller.cancelScan();
                                    MessageComponentFactory.showInfo(
                                      context, 
                                      message: '扫描已取消',
                                    );
                                    return;
                                  }
                                  
                                  if (controller.deviceIP == null) {
                                    MessageComponentFactory.showError(
                                      context, 
                                      message: '未能获取IP地址，无法扫描网段',
                                    );
                                    return;
                                  }
                                  
                                  // 执行实际的扫描
                                  controller.scanSSHDevices();
                                  
                                  // 提取网段以显示消息
                                  final ipParts = controller.deviceIP!.ipAddress.split('.');
                                  if (ipParts.length == 4) {
                                    final subnet = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}';
                                    MessageComponentFactory.showSuccess(
                                      context, 
                                      message: '开始扫描网段 $subnet.* 上的SSH设备',
                                    );
                                  }
                                },
                                icon: Icon(
                                  controller.isScanning ? Icons.stop : Icons.wifi_find,
                                  size: 16,
                                ),
                                label: Text(
                                  controller.isScanning ? '停止' : '扫描',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 状态信息
            if (controller.status.isNotEmpty && !controller.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  controller.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            // 添加分隔线
            const Divider(height: 16),
            
            // 自定义网段扫描部分
            const Row(
              children: [
                Icon(Icons.search, color: Colors.blue, size: 16),
                SizedBox(width: 6),
                Text(
                  '自定义网段扫描',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                // 网段输入框
                Expanded(
                  child: TextField(
                    controller: _subnetController,
                    decoration: InputDecoration(
                      hintText: '输入网段，如：192.168.1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      prefixIcon: const Icon(Icons.public, size: 16),
                      hintStyle: const TextStyle(fontSize: 12),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      // 限制只能输入IP地址格式的字符
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onSubmitted: (value) {
                      _scanCustomSubnet(context, controller);
                    },
                  ),
                ),
                
                const SizedBox(width: 6),
                
                // 扫描自定义网段按钮
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _scanCustomSubnet(context, controller);
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 14,
                    ),
                    label: const Text(
                      '扫描',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // 提示信息
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '输入网段格式为 x.x.x（如 192.168.1），将扫描 x.x.x.1 到 x.x.x.254 范围内的所有IP',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建网络适配器选择器
  Widget _buildNetworkAdapterSelector(BuildContext context, IPController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.network_check, size: 14, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              '选择网络适配器',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: controller.selectedAdapterIndex >= 0 ? controller.selectedAdapterIndex : null,
              hint: const Text('选择网络适配器', style: TextStyle(fontSize: 12)),
              onChanged: (int? newIndex) {
                if (newIndex != null) {
                  controller.selectNetworkAdapter(newIndex);
                }
              },
              items: List.generate(
                controller.networkAdapters.length,
                (index) => DropdownMenuItem<int>(
                  value: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getNetworkAdapterIcon(controller.networkAdapters[index].displayName),
                          size: 14,
                          color: controller.networkAdapters[index].isActiveAdapter 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${controller.networkAdapters[index].displayName} - ${controller.networkAdapters[index].ipAddress}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemHeight: 48.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 6),
      ],
    );
  }
  
  /// 获取网络适配器图标
  IconData _getNetworkAdapterIcon(String adapterName) {
    if (adapterName.toLowerCase().contains('以太网') || 
        adapterName.toLowerCase().contains('ethernet')) {
      return Icons.settings_ethernet;
    } else if (adapterName.toLowerCase().contains('无线') || 
               adapterName.toLowerCase().contains('wi-fi') || 
               adapterName.toLowerCase().contains('wlan')) {
      return Icons.wifi;
    } else if (adapterName.toLowerCase().contains('虚拟') || 
               adapterName.toLowerCase().contains('virtual') ||
               adapterName.toLowerCase().contains('hyper-v')) {
      return Icons.dns;
    }
    return Icons.network_check;
  }
  
  /// 扫描自定义网段
  void _scanCustomSubnet(BuildContext context, IPController controller) {
    final subnet = _subnetController.text.trim();
    
    if (subnet.isEmpty) {
      MessageComponentFactory.showError(
        context, 
        message: '请输入要扫描的网段',
      );
      return;
    }
    
    if (controller.isScanning) {
      MessageComponentFactory.showInfo(
        context, 
        message: '正在扫描中，请等待当前扫描完成',
      );
      return;
    }
    
    // 执行扫描
    controller.scanSubnet(subnet);
    
    MessageComponentFactory.showSuccess(
      context, 
      message: '开始扫描网段 $subnet.* 上的SSH设备',
    );
  }
  
  /// 连接到SSH设备
  void _connectToSSH(BuildContext context, IPDeviceModel device) {
    // 获取会话控制器并确保它处于可用状态
    final sessionController = Provider.of<SSHSessionController>(context, listen: false);
    final sshController = Provider.of<SSHController>(context, listen: false);
    
    // 预先加载会话，避免"控制器忙"的问题
    try {
      debugPrint('预加载SSH会话数据...');
      // 使用内部方法强制加载会话数据
      sessionController.init();
    } catch (e) {
      debugPrint('预加载会话数据时出错: $e');
    }
    
    // 显示SSH连接对话框
    SSHConnectDialog.show(
      context,
      device,
      onConnect: (username, password, port) {
        // 创建终端页面并将其传递给侧边栏的终端页面索引
        final terminalPage = SSHTerminalPage(
          device: device,
          username: username,
          password: password,
          port: port,
        );
        
        // 获取Provider并更新终端页面
        final sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);
        
        debugPrint('开始连接到SSH设备: ${device.displayName} (${device.ipAddress})');
        
        // 使用两阶段处理：先切换索引，再延迟更新内容
        // 第一阶段：切换到终端页面索引
        sidebarProvider.setIndex(1);
        
        // 确保先将终端页面设置为"连接中"状态
        final connectingWidget = _buildConnectingWidget(device);
        sidebarProvider.updateTerminalPage(connectingWidget);
        
        // 第二阶段：增加延迟后更新终端内容
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!context.mounted) return;
          
          debugPrint('更新终端页面内容 (500ms延迟后)');
          
          // 更新终端页面内容
          sidebarProvider.updateTerminalPage(terminalPage);
          
          // 记录调试信息
          debugPrint('终端页面内容已更新: ${device.displayName} (${device.ipAddress})');
          
          // 显示连接成功消息
          MessageComponentFactory.showSuccess(
            context,
            message: '已连接到 ${device.displayName}',
          );
          
          // 再次强制刷新
          Future.delayed(const Duration(milliseconds: 200), () {
            if (!context.mounted) return;
            sidebarProvider.refresh();
            debugPrint('额外UI刷新触发完成');
          });
        });
      },
    );
  }
  
  /// 构建连接中状态的Widget
  Widget _buildConnectingWidget(IPDeviceModel device) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 24),
          Text(
            '正在连接到 ${device.displayName}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '地址: ${device.ipAddress}',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '请稍候...',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 复制文本到剪贴板
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    MessageComponentFactory.showSuccess(
      context, 
      message: '已复制到剪贴板: $text',
    );
  }
} 