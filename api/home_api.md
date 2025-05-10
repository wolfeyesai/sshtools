# 首页配置系统API

本文档描述首页配置系统的WebSocket API请求和响应格式。

## 请求和响应格式

系统使用两种主要操作：
- `home_read`: 读取首页配置
- `home_modify`: 修改首页配置

### 读取首页配置 (home_read)

**客户端请求**：

```json
{
  "action": "home_read",
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
  "action": "home_read",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T13:30:00Z"
  }
}
```

### 修改首页配置 (home_modify)

**客户端请求**：

```json
{
  "action": "home_modify",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "home_modify_response",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

## 参数说明

| 参数名称 | 类型 | 描述 | 可选值 |
|---------|------|------|-------|
| username | string | 用户名 | 任意字符串 |
| gameName | string | 游戏名称 | apex, cf, cfhd, csgo2, pubg, sjz, ssjj2, wwqy |
| cardKey | string | 用户卡密 | 任意字符串 |
| updatedAt | string | 更新时间戳 | ISO8601格式的时间字符串 | 