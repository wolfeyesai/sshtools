// ignore_for_file: use_super_parameters, library_private_types_in_public_api, unused_import, sort_child_properties_last, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 视图导入
import 'views/login_screen.dart';
import 'views/register_screen.dart';
import 'views/layout_screen.dart';
import 'views/home_screen.dart';
import 'views/function/function_screen.dart';
import 'views/pid_screen.dart';
import 'views/fov_screen.dart';
import 'views/aim_screen.dart';
import 'views/fire_screen.dart';
import 'views/data_collection_screen.dart';

// 模型导入
import 'models/auth_model.dart';
import 'models/app_settings_model.dart';
import 'models/sidebar_model.dart';
import 'models/resource_model.dart';
import 'models/game_model.dart';
import 'models/login_model.dart';
import 'models/ui_config_model.dart';
import 'models/function_model.dart';
import 'models/aim_model.dart';
import 'models/fov_model.dart';
import 'models/pid_model.dart';
import 'models/fire_model.dart';
import 'models/data_collection_model.dart';
import 'models/status_bar_model.dart';

// 控制器/服务导入
import 'services/server_service.dart';
import 'services/auth_service.dart';
import 'controllers/header_controller.dart';
import 'controllers/login_controller.dart';
import 'controllers/side_controller.dart';
import 'controllers/function_controller.dart';
import 'controllers/aim_controller.dart';
import 'controllers/fov_controller.dart';
import 'controllers/pid_controller.dart';
import 'controllers/fire_controller.dart';
import 'controllers/data_collection_controller.dart';

// 全局服务访问助手函数
ServerService getServerService(BuildContext context) => Provider.of<ServerService>(context, listen: false);

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化共享偏好设置
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // 创建AuthModel并加载认证状态
  final authModel = AuthModel();
  await authModel.loadAuthState();
  
  // 创建GameModel并加载游戏设置
  final gameModel = GameModel();
  await gameModel.loadSettings();
  
  // 创建LoginModel并加载登录设置
  final loginModel = LoginModel();
  await loginModel.loadLoginSettings();
  
  // 创建UIConfigModel并加载UI配置
  final uiConfigModel = UIConfigModel();
  await uiConfigModel.loadSettings();
  
  runApp(MyApp(
    sharedPreferences: sharedPreferences,
    authModel: authModel,
    gameModel: gameModel,
    loginModel: loginModel,
    uiConfigModel: uiConfigModel,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final AuthModel authModel;
  final GameModel gameModel;
  final LoginModel loginModel;
  final UIConfigModel uiConfigModel;
  
  const MyApp({
    Key? key, 
    required this.sharedPreferences,
    required this.authModel,
    required this.gameModel,
    required this.loginModel,
    required this.uiConfigModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 核心服务
        Provider<SharedPreferences>.value(value: sharedPreferences),
        
        // 服务
        ChangeNotifierProvider(create: (_) => ServerService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // 数据模型
        ChangeNotifierProvider.value(value: authModel),
        ChangeNotifierProvider(create: (_) => AppSettingsModel()),
        ChangeNotifierProvider(create: (_) => SidebarModel()),
        ChangeNotifierProvider(create: (_) => ResourceModel()),
        ChangeNotifierProvider.value(value: gameModel),
        ChangeNotifierProvider.value(value: loginModel),
        ChangeNotifierProvider.value(value: uiConfigModel),
        ChangeNotifierProvider(create: (_) => FunctionModel()),
        ChangeNotifierProvider(create: (_) => AimModel()),
        ChangeNotifierProvider(create: (_) => FovModel()),
        ChangeNotifierProvider(create: (_) => PidModel()),
        ChangeNotifierProvider(create: (_) => FireModel()),
        ChangeNotifierProvider(create: (_) => DataCollectionModel()),
        ChangeNotifierProvider(create: (_) => StatusBarModel()),
        
        // 控制器 - 注意：控制器的注册顺序很重要，依赖项需要先注册
        ChangeNotifierProxyProvider4<ServerService, AuthModel, GameModel, LoginModel, HeaderController>(
          create: (context) => HeaderController(
            serverService: Provider.of<ServerService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
            loginModel: Provider.of<LoginModel>(context, listen: false),
          ),
          update: (context, serverService, authModel, gameModel, loginModel, previous) => 
            previous ?? HeaderController(
              serverService: serverService,
              authModel: authModel,
              gameModel: gameModel,
              loginModel: loginModel,
            ),
        ),
        
        // 添加LoginController
        ChangeNotifierProxyProvider5<ServerService, AuthService, AuthModel, LoginModel, GameModel, LoginController>(
          create: (context) => LoginController(
            serverService: Provider.of<ServerService>(context, listen: false),
            authService: Provider.of<AuthService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            loginModel: Provider.of<LoginModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
          ),
          update: (context, serverService, authService, authModel, loginModel, gameModel, previous) {
            if (previous == null) {
              return LoginController(
                serverService: serverService,
                authService: authService,
                authModel: authModel,
                loginModel: loginModel,
                gameModel: gameModel,
              );
            }
            return previous;
          },
        ),
        
        // 添加SideController
        ChangeNotifierProxyProvider4<ServerService, SidebarModel, AuthModel, GameModel, SideController>(
          create: (context) => SideController(
            serverService: Provider.of<ServerService>(context, listen: false),
            sidebarModel: Provider.of<SidebarModel>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
          ),
          update: (context, serverService, sidebarModel, authModel, gameModel, previous) {
            if (previous == null) {
              return SideController(
                serverService: serverService,
                sidebarModel: sidebarModel,
                authModel: authModel,
                gameModel: gameModel,
              );
            }
            return previous;
          },
        ),
        
        // 添加FunctionController
        ChangeNotifierProxyProvider4<ServerService, AuthModel, GameModel, FunctionModel, FunctionController>(
          create: (context) => FunctionController(
            functionModel: Provider.of<FunctionModel>(context, listen: false),
            serverService: Provider.of<ServerService>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
          ),
          update: (context, serverService, authModel, gameModel, functionModel, previous) {
            if (previous == null) {
              return FunctionController(
                functionModel: functionModel,
                serverService: serverService,
                gameModel: gameModel,
                authModel: authModel,
              );
            }
            return previous;
          },
        ),
        
        // 添加AimController
        ChangeNotifierProxyProvider4<ServerService, AuthModel, GameModel, AimModel, AimController>(
          create: (context) => AimController(
            serverService: Provider.of<ServerService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
            aimModel: Provider.of<AimModel>(context, listen: false),
          ),
          update: (context, serverService, authModel, gameModel, aimModel, previous) {
            if (previous == null) {
              return AimController(
                serverService: serverService,
                authModel: authModel,
                gameModel: gameModel,
                aimModel: aimModel,
              );
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider4<ServerService, AuthModel, GameModel, FovModel, FovController>(
          create: (context) => FovController(
            serverService: Provider.of<ServerService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
            fovModel: Provider.of<FovModel>(context, listen: false),
          ),
          update: (context, serverService, authModel, gameModel, fovModel, previous) {
            if (previous == null) {
              return FovController(
                serverService: serverService,
                authModel: authModel,
                gameModel: gameModel,
                fovModel: fovModel,
              );
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider4<ServerService, AuthModel, GameModel, PidModel, PidController>(
          create: (context) => PidController(
            serverService: Provider.of<ServerService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
            pidModel: Provider.of<PidModel>(context, listen: false),
          ),
          update: (context, serverService, authModel, gameModel, pidModel, previous) {
            if (previous == null) {
              return PidController(
                serverService: serverService,
                authModel: authModel,
                gameModel: gameModel,
                pidModel: pidModel,
              );
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider4<ServerService, AuthModel, GameModel, FireModel, FireController>(
          create: (context) => FireController(
            serverService: Provider.of<ServerService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
            fireModel: Provider.of<FireModel>(context, listen: false),
          ),
          update: (context, serverService, authModel, gameModel, fireModel, previous) {
            if (previous == null) {
              return FireController(
                serverService: serverService,
                authModel: authModel,
                gameModel: gameModel,
                fireModel: fireModel,
              );
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider4<ServerService, AuthModel, GameModel, DataCollectionModel, DataCollectionController>(
          create: (context) => DataCollectionController(
            serverService: Provider.of<ServerService>(context, listen: false),
            authModel: Provider.of<AuthModel>(context, listen: false),
            gameModel: Provider.of<GameModel>(context, listen: false),
            dataCollectionModel: Provider.of<DataCollectionModel>(context, listen: false),
          ),
          update: (context, serverService, authModel, gameModel, dataCollectionModel, previous) {
            if (previous == null) {
              return DataCollectionController(
                serverService: serverService,
                authModel: authModel,
                gameModel: gameModel,
                dataCollectionModel: dataCollectionModel,
              );
            }
            return previous;
          },
        ),
      ],
      child: Consumer2<UIConfigModel, AppSettingsModel>(
        builder: (context, uiConfig, appSettings, child) {
          return MaterialApp(
            title: 'BlWeb',
            debugShowCheckedModeBanner: false,
            // 使用UIConfigModel中的字体配置
            theme: ThemeData(
              // 基础主题配置
              primarySwatch: Colors.blue,
              // 应用Google Fonts
              textTheme: uiConfig.useGoogleFonts 
                  ? uiConfig.getTextTheme(Theme.of(context).textTheme)
                  : Theme.of(context).textTheme,
              // 其他主题配置
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            // 使用AppSettingsModel中定义的路由
            initialRoute: authModel.isAuthenticated ? '/' : '/login',
            routes: appSettings.getRoutes(context),
          );
        },
      ),
    );
  }
}
