# 页头控制系统API

本文档描述页头控制系统的WebSocket API请求和响应格式。

## 请求和响应格式

系统使用以下主要操作：
- `status_bar_query`: 查询状态栏信息（重连按钮）
- `heartbeat`: 心跳请求

> **注意**：`home_read`操作已移至home_api文档中，不再属于页头控制系统API范围。

### 查询状态栏信息 (status_bar_query)

**说明**：当用户点击重连按钮时，发送此请求查询服务器状态，不会更新数据库，只是获取当前服务状态。状态只有两种：正常（true，绿色）和异常（false，红色）。

**客户端请求**：

```json
{
  "action": "status_bar_query",
  "token": "认证令牌"
}
```

**服务器响应**：

```json
{
  "action": "status_bar_response",
  "status": "success",
  "data": {
    "dbStatus": true,          // true（绿色）或 false（红色）
    "inferenceStatus": true,   // true（绿色）或 false（红色）
    "cardKeyStatus": true,     // true（绿色）或 false（红色）
    "keyMouseStatus": true,    // true（绿色）或 false（红色）
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

### 心跳请求 (heartbeat)

**说明**：定期发送心跳请求以维持与服务器的连接状态。不会更新数据库数据，仅确认连接状态。简化的心跳请求只需要包含最基本的信息。

**客户端请求**：

```json
{
  "action": "heartbeat",
  "content": {
    "clientStatus": "active",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "heartbeat_response",
  "status": "success",
  "data": {
    "serverStatus": "online",
    "serverTime": "2023-06-01T12:00:01Z"
  }
}
```

## 参数说明

### 状态栏查询参数

**重要说明**：状态栏查询不会更新数据库数据，只反映当前服务器状态。所有状态仅有两种：正常（true）和异常（false）。

| 参数名称 | 类型 | 描述 | 可能的值 |
|---------|------|------|---------|
| dbStatus | boolean | 数据库连接状态 | true（绿色）, false（红色） |
| inferenceStatus | boolean | 推理服务状态 | true（绿色）, false（红色） |
| cardKeyStatus | boolean | 卡密状态 | true（绿色）, false（红色） |
| keyMouseStatus | boolean | 键鼠状态 | true（绿色）, false（红色） |

### 心跳请求参数

| 参数名称 | 类型 | 描述 | 可能的值 |
|---------|------|------|---------|
| clientStatus | string | 客户端状态 | active, idle, closing |
| updatedAt | string | 更新时间 | ISO8601格式时间字符串 | 