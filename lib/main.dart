// ignore_for_file: use_super_parameters, library_private_types_in_public_api, unused_import, sort_child_properties_last, unnecessary_null_comparison, unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 视图导入
import 'views/login_screen.dart';
import 'views/register_screen.dart';
import 'views/layout_screen.dart'; // 导入 MainLayout 所在的文件
import 'views/home_screen.dart';
import 'views/device_screen.dart';
import 'views/terminal_screen.dart';
import 'views/settings_screen.dart';
// import 'views/pid_screen.dart'; // 根据项目结构文档，PID页面可能保留，暂时注释导入

// 模型导入
import 'models/auth_model.dart';
import 'models/login_model.dart';
import 'models/ui_config_model.dart';
import 'models/status_bar_model.dart'; // 根据项目结构文档，状态栏模型可能不再需要，暂时保留

// 新增SSH相关模型导入
import 'models/device_model.dart';
import 'models/terminal_model.dart';
import 'models/settings_model.dart';
// import 'models/pid_model.dart'; // 根据项目结构文档，PID模型可能保留，暂时注释导入

// 控制器/服务导入
import 'services/auth_service.dart';
import 'services/ssh_service.dart'; // 导入 SSHService
import 'controllers/header_controller.dart';
import 'controllers/login_controller.dart';
import 'controllers/register_controller.dart'; // 导入 RegisterController
import 'controllers/home_controller.dart'; // 导入 HomeController
// import 'controllers/pid_controller.dart'; // 根据项目结构文档，PID控制器可能保留，暂时注释导入

// 新增SSH相关控制器导入
import 'controllers/device_controller.dart';
import 'controllers/terminal_controller.dart';
import 'controllers/settings_controller.dart';

import './utils/logger.dart';

// 定义路由名称常量
class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String device = '/device';
  static const String terminal = '/terminal';
  static const String settings = '/settings';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志
  final logger = Logger();
  logger.setLogLevel(LogLevel.debug); // 设置日志级别为 debug，显示所有日志
  logger.enableLogs(true); // 启用日志
  logger.enableLogsInRelease(true); // 在发布模式下也启用日志
  logger.showFileInfo(true); // 显示文件信息
  
  logger.i('Main', '应用启动');
  
  final sharedPreferences = await SharedPreferences.getInstance();
  
  final authModel = AuthModel();
  await authModel.loadAuthState();
  
  final loginModel = LoginModel();
  final uiConfigModel = UIConfigModel();
  
  // 确保 settingsModel 被正确初始化
  final settingsModel = SettingsModel();
  await settingsModel.loadSettings();

  final deviceModel = DeviceModel();
  final sshService = SshService(settingsModel: settingsModel);

  // 使用 builder 模式确保所有参数被正确传递
  runApp(Builder(
    builder: (context) => MyApp(
      sharedPreferences: sharedPreferences,
      authModel: authModel,
      loginModel: loginModel,
      uiConfigModel: uiConfigModel,
      settingsModel: settingsModel,
      deviceModel: deviceModel,
      sshService: sshService,
    ),
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final AuthModel authModel;
  final LoginModel loginModel;
  final UIConfigModel uiConfigModel;
  final SettingsModel settingsModel;
  final DeviceModel deviceModel;
  final SshService sshService;
  
  const MyApp({
    Key? key, 
    required this.sharedPreferences,
    required this.authModel,
    required this.loginModel,
    required this.uiConfigModel,
    required this.settingsModel,
    required this.deviceModel,
    required this.sshService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log.i('Main', '应用的根Widget');
    return MultiProvider(
      providers: [
        // 核心服务
        Provider<SharedPreferences>.value(value: sharedPreferences),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: sshService),
        
        // 数据模型
        ChangeNotifierProvider.value(value: authModel),
        ChangeNotifierProvider.value(value: loginModel),
        ChangeNotifierProvider.value(value: uiConfigModel),
        ChangeNotifierProvider.value(value: settingsModel),
        ChangeNotifierProvider.value(value: deviceModel),
        ChangeNotifierProvider(create: (_) => TerminalModel()),

        // 控制器
        ChangeNotifierProxyProvider2<AuthService, LoginModel, RegisterController>(
          create: (context) => RegisterController(
            authService: Provider.of<AuthService>(context, listen: false),
            loginModel: Provider.of<LoginModel>(context, listen: false),
          ),
          update: (context, authService, loginModel, previous) => previous ?? RegisterController(authService: authService, loginModel: loginModel),
        ),

        // LoginController 移除 GameModel 依赖
        ChangeNotifierProxyProvider3<AuthService, AuthModel, LoginModel, LoginController>(
          create: (context) => LoginController(
            authService: Provider.of<AuthService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            loginModel: Provider.of<LoginModel>(context, listen: false),
          ),
          update: (context, authService, authModel, loginModel, previous) {
             if (previous == null) {
              return LoginController(
                authService: authService,
                authModel: authModel,
                loginModel: loginModel,
              );
            }
            return previous!;
          },
        ),

        // DeviceController 依赖 DeviceModel
        ChangeNotifierProxyProvider<DeviceModel, DeviceController>(
          create: (context) => DeviceController(
            Provider.of<DeviceModel>(context, listen: false)
          ),
          update: (context, deviceModel, previous) {
            if (previous == null) {
              return DeviceController(deviceModel);
            }
            return previous;
          },
        ),

        // TerminalController 依赖 TerminalModel 和 SshService
        ChangeNotifierProxyProvider2<TerminalModel, SshService, TerminalController>(
           create: (context) => TerminalController(
             Provider.of<TerminalModel>(context, listen: false),
             Provider.of<SshService>(context, listen: false),
           ),
           update: (context, terminalModel, sshService, previous) => previous ?? TerminalController(terminalModel, sshService),
        ),

        // SettingsController 依赖 SettingsModel
        ChangeNotifierProxyProvider<SettingsModel, SettingsController>(
          create: (context) => SettingsController(Provider.of<SettingsModel>(context, listen: false)),
          update: (context, settingsModel, previous) => previous ?? SettingsController(settingsModel),
        ),

        // HomeController 依赖 DeviceModel 和 SshService
        ChangeNotifierProxyProvider2<DeviceModel, SshService, HomeController>(
          create: (context) => HomeController(
            deviceModel: Provider.of<DeviceModel>(context, listen: false),
            sshService: Provider.of<SshService>(context, listen: false),
          ),
          update: (context, deviceModel, sshService, previous) => previous ?? HomeController(deviceModel: deviceModel, sshService: sshService),
        ),

         // HeaderController 依赖 AuthModel, SshService
         ChangeNotifierProxyProvider2<AuthModel, SshService, HeaderController>(
           create: (context) => HeaderController(
             authModel: Provider.of<AuthModel>(context, listen: false),
             sshService: Provider.of<SshService>(context, listen: false),
           ),
           update: (context, authModel, sshService, previous) => previous ?? HeaderController(authModel: authModel, sshService: sshService),
         ),
      ],
      child: Consumer<UIConfigModel>(
        builder: (context, uiConfig, child) {
          return MaterialApp(
            title: 'SSH Tool',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              textTheme: uiConfig.useGoogleFonts 
                  ? uiConfig.getTextTheme(Theme.of(context).textTheme)
                  : Theme.of(context).textTheme,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            // 根据登录状态决定初始路由
            initialRoute: authModel.isAuthenticated ? Routes.main : Routes.login,
            // 定义路由
            routes: {
              Routes.login: (context) => LoginScreen(
                onLoginSuccess: () => Navigator.pushReplacementNamed(context, Routes.main),
                onRegister: () => Navigator.pushNamed(context, Routes.register),
              ),
              Routes.register: (context) => RegisterScreen(
                onRegisterSuccess: () => Navigator.pushReplacementNamed(context, Routes.login),
                onBackToLogin: () => Navigator.pop(context),
              ),
              Routes.main: (context) => MainLayout(
                onLogout: () {
                  authModel.logout();
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                onRefreshSystem: () {
                  // 刷新系统逻辑
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('系统刷新中...'))
                  );
                },
                onRefreshData: () {
                  // 刷新数据逻辑
                },
              ),
              Routes.home: (context) => HomeScreen(),
              Routes.device: (context) => DeviceScreen(),
              Routes.terminal: (context) => TerminalScreen(),
              Routes.settings: (context) => SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
