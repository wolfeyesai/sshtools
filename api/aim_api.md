# 瞄准设置系统API

本文档描述瞄准设置系统的WebSocket API请求和响应格式。

## 请求和响应格式

系统使用两种主要操作：
- `aim_read`: 读取瞄准设置
- `aim_modify`: 修改瞄准设置

### 读取瞄准设置 (aim_read)

**客户端请求**：

```json
{
  "action": "aim_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "aim_read_response",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "aimRange": 100.0,
    "trackRange": 50.0,
    "headHeight": 10.0,
    "neckHeight": 8.0,
    "chestHeight": 6.0,
    "headRangeX": 0.5,
    "headRangeY": 0.5,
    "neckRangeX": 0.4,
    "neckRangeY": 0.4,
    "chestRangeX": 0.6,
    "chestRangeY": 0.6,
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T13:30:00Z"
  }
}
```

### 修改瞄准设置 (aim_modify)

**客户端请求**：

```json
{
  "action": "aim_modify",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "aimRange": 100.0,
    "trackRange": 50.0,
    "headHeight": 10.0,
    "neckHeight": 8.0,
    "chestHeight": 6.0,
    "headRangeX": 0.5,
    "headRangeY": 0.5,
    "neckRangeX": 0.4,
    "neckRangeY": 0.4,
    "chestRangeX": 0.6,
    "chestRangeY": 0.6,
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "aim_modify_response",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "aimRange": 100.0,
    "trackRange": 50.0,
    "headHeight": 10.0,
    "neckHeight": 8.0,
    "chestHeight": 6.0,
    "headRangeX": 0.5,
    "headRangeY": 0.5,
    "neckRangeX": 0.4,
    "neckRangeY": 0.4,
    "chestRangeX": 0.6,
    "chestRangeY": 0.6,
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

## 参数说明

| 参数名称 | 类型 | 描述 | 可选值/范围 |
|---------|------|------|-------|
| aimRange | double | 瞄准范围 | 0.0 - 416.0 |
| trackRange | double | 跟踪范围 | 0.001 - 15.0 |
| headHeight | double | 头部高度 | 0.0 - 50.0 |
| neckHeight | double | 颈部高度 | 0.0 - 50.0 |
| chestHeight | double | 胸部高度 | 0.0 - 50.0 |
| headRangeX | double | 头部X范围 | 0.1 - 1.0 |
| headRangeY | double | 头部Y范围 | 0.1 - 1.0 |
| neckRangeX | double | 颈部X范围 | 0.1 - 1.0 |
| neckRangeY | double | 颈部Y范围 | 0.1 - 1.0 |
| chestRangeX | double | 胸部X范围 | 0.1 - 1.0 |
| chestRangeY | double | 胸部Y范围 | 0.1 - 1.0 | 