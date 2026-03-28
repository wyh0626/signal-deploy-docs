# 维护指南

English: [./en/maintenance.md](./en/maintenance.md)

这个仓库想长期可维护，关键不是把脚本写得多复杂，而是把“升级、验证、记录、回滚”的习惯固定下来。

## 维护目标

- 和上游 `Signal-Server` 版本建立清晰映射
- 补丁尽量少、尽量短命
- 中英文文档和脚本保持一致
- 每次升级都能快速证明“这套东西现在还能跑”

## 推荐的维护节奏

### 每次上游发新版本时

1. 新建版本分支
2. 更新 `versions/current.env`
3. 新增 `versions/<tag>.env`
4. 重新拉上游并应用补丁
5. 跑 `./scripts/dev-up.sh --smoke-test`
6. 如果桌面端在范围内，再跑 `./scripts/desktop-up.sh`
7. 更新中英文文档

### 每次补丁变动时

1. 记录为什么必须改
2. 确认是否可以通过配置替代
3. 重新跑 smoke test
4. 如果改到桌面端，再验证 standalone 启动

## 建议固定的验收项

- `signal-server` admin health 正常
- verification session 创建成功
- captcha 提交成功
- verification code 请求成功
- verification code 校验成功
- `dynamic-config` 与对象存储仍能正常读取
- Desktop 至少还能启动到本地开发入口

## 文档维护规则

- README 与 docs 要同步
- 中文和英文版本尽量同一次提交一起更新
- `docs/plans/` 只放本地计划稿，不纳入 Git
- 任何“本地替代”都要写清楚失去的能力边界

## 不建议做的事情

- 把上游源码直接整份 vendoring 进仓库
- 用大量长生命周期 patch 代替配置和文档
- 让 `main` 积累过多未经验证的版本实验
- 把本地 demo 成功误当成生产可用
