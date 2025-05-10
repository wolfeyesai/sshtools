# BlWeb WebSocket API 文档

## 简介

本文档详细说明BlWeb应用中通过WebSocket与服务器通信的API请求格式。所有请求都通过WebSocket发送JSON格式的消息，并包含标准化的请求结构。

## 通用请求格式

所有API请求遵循以下通用格式：

```json
{
  "action": "动作类型",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "updatedAt": "时间戳（ISO 8601格式）",
    // 其他特定于请求类型的字段
  }
}
```

### 通用字段说明

| 字段名 | 类型 | 描述 |
|-------|------|------|
| `action` | String | 请求的动作类型，指定要执行的操作 |
| `content.username` | String | 当前用户的用户名 |
| `content.gameName` | String | 当前选择的游戏名称 |
| `content.updatedAt` | String | ISO 8601格式的时间戳，表示请求发送时间 |

## 页面特定请求

### 1. 首页配置请求

当用户访问或切换到首页时发送。

```json
{
  "action": "home_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

### 2. 功能设置请求

当用户访问或切换到功能设置页面时发送。

```json
{
  "action": "function_read",
  "content": {
    "username": "用户名", 
    "gameName": "游戏名称",
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

### 3. PID设置请求

当用户访问或切换到PID设置页面时发送。

```json
{
  "action": "pid_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

### 4. 视野设置请求

当用户访问或切换到视野设置页面时发送。

```json
{
  "action": "fov_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称", 
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

### 5. 瞄准设置请求

当用户访问或切换到瞄准设置页面时发送。

```json
{
  "action": "aim_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

### 6. 射击设置请求

当用户访问或切换到射击设置页面时发送。

```json
{
  "action": "fire_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

### 7. 数据收集请求

当用户访问或切换到数据收集页面时发送。

```json
{
  "action": "data_collection_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

## 刷新请求

### 侧边栏刷新请求

当用户点击侧边栏上的"刷新数据"按钮时发送。

```json
{
  "action": "sidebar_refresh",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "updatedAt": "2023-07-01T12:00:00.000Z"
  }
}
```

### 系统刷新请求

当用户点击顶部导航栏上的刷新按钮时发送。

```json
{
  "action": "system_refresh",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "refreshTime": "2023-07-01T12:00:00.000Z"
  }
}
```

## 请求触发时机

| 请求类型 | 触发时机 |
|---------|----------|
| `home_read` | 用户访问首页或在侧边栏选择"首页配置"选项 |
| `function_read` | 用户在侧边栏选择"功能设置"选项 |
| `pid_read` | 用户在侧边栏选择"PID设置"选项 |
| `fov_read` | 用户在侧边栏选择"视野设置"选项 |
| `aim_read` | 用户在侧边栏选择"瞄准设置"选项 |
| `fire_read` | 用户在侧边栏选择"射击设置"选项 |
| `data_collection_read` | 用户在侧边栏选择"数据收集"选项 |
| `sidebar_refresh` | 用户点击侧边栏上的"刷新数据"按钮 |
| `system_refresh` | 用户点击顶部导航栏上的刷新按钮 | 