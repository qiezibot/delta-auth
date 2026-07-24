# 部署到 Railway 的步骤

## 1. 创建 GitHub 仓库
在 github.com/qiezibot 下创建新仓库 `delta-auth`

## 2. 推送代码
```bash
cd delta-auth
git remote add origin https://github.com/qiezibot/delta-auth.git
git push -u origin master
```

## 3. Railway 部署
- 登录 railway.app/dashboard
- New Project → Deploy from GitHub repo
- 选择 qiezibot/delta-auth
- 设置 Root Directory: api/
- 设置 Start Command: python main.py
- 添加环境变量 AUTH_SECRET=自己设一个密钥

## 4. 验证
打开 Railway 生成的域名，应该能看到扫码授权页面
