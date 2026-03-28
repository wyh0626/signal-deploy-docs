# Signal 部署文档

把 Signal 的本地开发部署方式沉淀成一个可开源、可复现、可版本化的仓库。

这个项目的目标不是“完整复刻官方生产环境”，而是提供一套稳定的本地 dev stack，让你可以：

- 在 Docker 里启动 `Signal-Server`
- 用本地 `registration-service` 完成验证码注册
- 用 MinIO、DynamoDB Local、Redis、GCloud emulators 替代云依赖
- 让 `Signal-Desktop` 直连本地后端进行 standalone 调试
- 按 Signal 上游版本维护对应分支和版本清单

## 仓库包含什么

- `deploy/docker-compose.yml`
  Signal 本地依赖编排，包含 DynamoDB Local、MinIO、Redis、GCloud emulators、registration-service、signal-server。
- `deploy/config/signal-server.yml.tmpl`
  Signal-Server 的本地配置模板。运行时会渲染为 `deploy/generated/signal-server.yml`。
- `deploy/config/registration-service.yml`
  registration-service 的本地配置。
- `deploy/docker/*.Dockerfile`
  基于上游源码构建的本地镜像定义。
- `patches/`
  对上游 `Signal-Server` 和 `Signal-Desktop` 的最小本地开发补丁。
- `scripts/`
  一键拉取上游、应用补丁、生成证书/密钥、启动/停止环境、启动桌面端。
- `versions/`
  上游版本钉住清单。`current.env` 表示当前默认组合。
- `docs/`
  模块说明、替代件说明、版本策略、桌面端调试说明。

## 当前已验证的版本

见 [versions/current.env](./versions/current.env)。

当前默认组合：

- `Signal-Server`: `v20260324.1.0`
- `registration-service`: `2.58.0`
- `Signal-Desktop`: `v7.42.0-adhoc.20250124.1-1503-ge8efc3c66`

## 模块概览

核心模块：

- `Signal-Server`
  主后端服务，HTTP/HTTPS/Admin/gRPC 都由它提供。
- `registration-service`
  手机号验证与注册会话服务。本项目使用 `dev,local` 环境，不接真实短信供应商。
- `Signal-Desktop`
  可选。用于直连本地后端做 standalone 调试。

基础设施：

- `DynamoDB Local`
  替代 AWS DynamoDB。
- `MinIO`
  替代 S3/GCS。
- `Redis x5`
  其中 4 个按单节点 cluster 模式跑，1 个 standalone 用于 pubsub。
- `GCloud emulators`
  提供 Firestore / PubSub / Bigtable 的本地替代。

被 stub 或降级的模块：

- `Contact Discovery Service`
- `SVR2 / SVRB`
- `Key Transparency`
- `FCM / APNs`
- `Stripe / Braintree`
- `Google Play Billing / Apple App Store`
- `FoundationDB runtime`

详细模块表见 [docs/modules.md](./docs/modules.md)。

## 一键启动

第一次使用：

```bash
git clone <your-repo-url> signal-deploy-docs
cd signal-deploy-docs
cp .env.example .env
./scripts/dev-up.sh
```

成功后默认会得到：

- API: `http://localhost:8090`
- HTTPS API: `https://localhost:9443`
- Admin: `http://localhost:8091/healthcheck`
- MinIO Console: `http://localhost:9001`
- DynamoDB Local: `http://localhost:8000`

## 本地注册规则

本项目里的 `registration-service` 跑在 `MICRONAUT_ENVIRONMENTS=dev,local`：

- 不会发送真实短信
- 验证码 = 手机号后 6 位
- captcha 可用 `noop.noop.registration.localtest`

例如：

- 手机号：`+14155550131`
- 验证码：`550131`

## 桌面端调试

先启动服务端：

```bash
./scripts/dev-up.sh
```

再启动桌面端：

```bash
./scripts/desktop-up.sh
```

桌面端支持两种思路：

- `Standalone Device`
  不需要安卓，直接让 Desktop 自己注册到本地环境。
- `Link Device`
  需要一个同样接到本地环境的 Android 主设备。官方商店里的 Signal 手机端不能直接扫这套本地环境。

详细说明见 [docs/desktop-local.md](./docs/desktop-local.md)。

## 版本与分支策略

这个仓库建议按 `Signal-Server` 版本建分支：

- `main`
  持续维护的主分支。
- `signal-server/v20260324.1.0`
  对应 `Signal-Server v20260324.1.0` 的已验证部署分支。

每个分支都应同步更新：

- `versions/current.env`
- `patches/`
- `deploy/config/`
- 文档里的兼容性说明

详细策略见 [docs/versioning.md](./docs/versioning.md)。

## 已知边界

- 这不是官方生产部署，不适合直接对公网提供真实服务。
- SGX 相关服务没有本地等价物，只能 stub。
- FCM/APNs、支付、应用商店验证都是本地假实现或空实现。
- `Signal-Desktop` 本地直连可用于调试，但真正扫码链接仍需要本地版移动端主设备。

## License / Notice

这个仓库包含对 Signal 开源项目的派生补丁和部署脚本。发布到 GitHub 前，建议保留 AGPL-3.0-only 兼容许可，并在 `NOTICE` 中明确引用上游项目：

- [Signal-Server](https://github.com/signalapp/Signal-Server)
- [Signal-Desktop](https://github.com/signalapp/Signal-Desktop)
- [registration-service](https://github.com/signalapp/registration-service)
