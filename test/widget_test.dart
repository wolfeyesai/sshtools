// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blui/main.dart';
import 'package:blui/models/auth_model.dart';
import 'package:blui/models/device_model.dart';
import 'package:blui/models/login_model.dart';
import 'package:blui/models/settings_model.dart';
import 'package:blui/models/ui_config_model.dart';
import 'package:blui/services/ssh_service.dart';

void main() {
  testWidgets('应用初始化测试', (WidgetTester tester) async {
    // 初始化SharedPreferences模拟
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    
    // 初始化所需的模型
    final authModel = AuthModel();
    final deviceModel = DeviceModel();
    final loginModel = LoginModel();
    final uiConfigModel = UIConfigModel();
    final settingsModel = SettingsModel();
    final sshService = SshService(settingsModel: settingsModel);
    
    // 构建应用并触发一帧
    await tester.pumpWidget(Builder(
      builder: (context) => MyApp(
        sharedPreferences: sharedPreferences,
        authModel: authModel,
        deviceModel: deviceModel,
        loginModel: loginModel,
        uiConfigModel: uiConfigModel,
        settingsModel: settingsModel,
        sshService: sshService,
      ),
    ));
    
    // 验证应用已经初始化
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
