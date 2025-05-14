# 登录认证系统WebSocket API

本文档描述登录认证系统的WebSocket API请求和响应格式。

## 请求和响应格式

系统提供以下主要操作：
- `login`: 用户登录
- `register`: 用户注册
- `logout`: 用户退出登录

## WebSocket连接

### 建立WebSocket连接

**端点**: `ws://{serverAddress}:{serverPort}/ws`

**参数**:
- `token`: (可选) 认证令牌，用于已登录状态下的连接

## API请求

### 登录 (login)

**请求**:
```json
{
  "action": "login",
  "content": {
    "username": "用户名",
    "password": "密码",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

**成功响应**:
```json
{
  "action": "login_response",
  "success": true,
  "token": "认证令牌",
  "message": "登录成功"
}
```

**失败响应**:
```json
{
  "action": "login_response",
  "success": false,
  "message": "登录失败原因"
}
```

### 注册 (register)

**请求**:
```json
{
  "action": "register",
  "content": {
    "username": "用户名",
    "password": "密码",
    "createdAt": "2023-06-01T12:00:00Z"
  }
}
```

**成功响应**:
```json
{
  "action": "register_response",
  "success": true,
  "message": "注册成功"
}
```

**失败响应**:
```json
{
  "action": "register_response",
  "success": false,
  "message": "注册失败原因"
}
```

### 退出登录 (logout)

**请求**:
```json
{
  "action": "logout",
  "token": "认证令牌",
  "content": {
    "username": "用户名",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

**成功响应**:
```json
{
  "action": "logout_response",
  "success": true,
  "message": "退出成功"
}
```

### 心跳请求 (heartbeat)

**说明**：定期发送心跳请求以维持与服务器的连接状态。

**请求**:
```json
{
  "action": "heartbeat",
  "content": {
    "username": "用户名",
    "updatedAt": "2023-06-01T12:00:00Z",
    "clientStatus": "active"
  }
}
```

**响应**:
```json
{
  "action": "heartbeat_response",
  "serverStatus": "online",
  "serverTime": "2023-06-01T12:00:01Z"
}
```

## 前端实现说明

### WebSocket连接管理
1. 使用`BlWebSocket`类管理WebSocket连接
2. 通过`initSocket()`方法初始化连接，可选携带认证令牌
3. 所有请求通过`sendMessage()`方法发送
4. 通过消息回调处理服务器响应

### 登录流程
1. 用户输入服务器地址、端口、用户名和密码
2. 点击登录按钮时，通过WebSocket发送登录请求
3. 登录成功后，获取令牌并保存至`AuthModel`
4. 跳转至主页面

### 注册流程
1. 用户填写注册表单（用户名、密码、确认密码）
2. 点击注册按钮时，通过WebSocket发送注册请求
3. 注册成功后，显示成功消息，可返回登录页面

### 退出登录流程
1. 用户点击退出登录按钮
2. 发送退出登录请求
3. 清除认证信息并跳转回登录页面

## 错误处理

前端处理以下主要错误类型：
1. WebSocket连接错误 - 连接建立失败或中断
2. 认证错误 - 用户名或密码错误
3. 服务器错误 - 服务器内部错误
4. 连接超时 - WebSocket连接超时未响应（启动自动重连机制） 