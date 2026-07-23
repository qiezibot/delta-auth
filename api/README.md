# 三角洲授权系统 - 后端 API

## 技术
- FastAPI + SQLite（本地开发用，可切换 PostgreSQL）
- 独立部署，跟茄子数据完全分开

## API 接口

### 创建授权码
`POST /api/auth/create`
→ 返回 `{code, qrcode_url}`

### 获取二维码
`GET /api/auth/qrcode/{code}`
→ 返回二维码内容

### 确认授权（微信扫码后回调）
`POST /api/auth/confirm/{code}`
body: `{credential}`

### 轮询状态
`GET /api/auth/verify/{code}`
→ 返回 `{status: "pending"|"confirmed"}`

### 获取凭证
`GET /api/auth/token/{code}?secret=xxx`
→ 返回授权凭证

## 部署
Railway / Fly.io 独立项目
