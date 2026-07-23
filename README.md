# 三角洲授权系统 (Delta Auth)

独立项目，跟茄子数据完全分开。

## 项目结构

```
delta-auth/
├── start.bat          # 一键启动后端
├── api/               # 后端 API (FastAPI + SQLite)
│   ├── main.py        # 服务端，授权码生成/验证/凭证管理
│   └── requirements.txt
├── web/               # 网页扫码端
│   └── index.html     # 扫码授权页面
└── android/           # 安卓 App (Flutter)
    ├── pubspec.yaml   # Flutter 配置
    └── lib/main.dart  # 获取/应用授权凭证
```

## 启动

```bash
# 安装依赖
pip install -r api/requirements.txt

# 启动 API 服务器
python api/main.py
# => http://localhost:8000
# => 网页: http://localhost:8000/app/
```

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/create | 创建授权码 |
| GET | /api/auth/qrcode/{code} | 获取二维码信息 |
| POST | /api/auth/confirm/{code} | 确认授权（存储凭证） |
| GET | /api/auth/verify/{code} | 轮询授权状态 |
| GET | /api/auth/token/{code} | 获取授权凭证（需密钥） |
| POST | /api/auth/consume/{code} | 消耗凭证（标记已使用） |
| GET | /api/auth/list | 列出所有记录（管理用） |

## 安卓 App

Flutter 项目，需要安装 Flutter SDK 编译：

```bash
cd android
flutter build apk
```
