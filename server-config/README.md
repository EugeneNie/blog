# 服务器侧配置备忘（日常维护与重建都看这里）

博客跑在一台**阿里云轻量应用服务器**上（公网 IP `8.130.75.245`，地域乌兰察布），
域名 `eugenenie.top`、ICP 备案、这台机器**都在同一个阿里云账号下**。

> 踩过的坑记一笔：曾一度以为机器在一个"注册手机号已停用、无法登录"的旧账号里，
> 后来在**轻量应用服务器控制台**确认机器就在平时用的账号里。
> 原因是轻量实例**不会出现在 ECS 控制台**，所以"ECS 列表里查不到"并不代表账号不对。
> 另外轻量实例的元数据里 `instance-id` 是 `i-` 开头、`instance-type` 是 `ecs.` 开头，
> 那是底层 ECS 的信息，不能据此判断产品类型——要看控制台。

## 现状

| 项目 | 值 |
| --- | --- |
| 产品 | 阿里云轻量应用服务器（2核2G，单块 40G 系统盘） |
| 系统 | Alibaba Cloud Linux 3（OpenAnolis Edition），内核 5.10.134-19.8 |
| 面板 | 宝塔面板（8888 端口，已加随机安全入口 + 面板 SSL；入口记录在服务器 `/www/server/panel/data/admin_path.pl`） |
| Web 服务 | 宝塔自带的 nginx（`/www/server/nginx`） |
| 站点根目录 | `/www/wwwroot/eugenenie.top`，属主 `www:www` |
| HTTPS 证书 | 宝塔自动申请续期（Let's Encrypt，HTTP 校验），路径 `/www/server/panel/vhost/cert/eugenenie.top/` |
| 部署方式 | 本机计划任务自动提交 → GitHub Actions 构建 → `rsync --delete` 推到站点根目录 |

## 日常维护清单

- **到期前续费**：轻量控制台 → 服务器列表 → 看"到期时间"；域名 `eugenenie.top` 到期日 **2026-10-27**，也要记得续
- **快照**：轻量控制台 → 服务器详情 → 快照。建议顺手开"自动快照策略"（例如每天一次、保留 7 天），这是最省事的灾备
- **面板入口**：SSH 里 `bt default` 查面板地址和用户名，`bt 5` 改密码，直接输 `bt` 看完整菜单
- **SSH 策略**：远程只允许密钥登录，仅 `127.0.0.1` 保留密码登录（供宝塔面板终端应急）；要改回密码登录得编辑 `/etc/ssh/sshd_config`
- **发文章**：改完保存即可（本机计划任务每 5 分钟自动提交推送）；想立刻上线就运行 `.\publish.ps1`

## 这两个 nginx 配置文件是干什么的

- `nginx-vhost.conf` —— 站点主配置。**关键点**：`location / { try_files $uri $uri/ =404; }`。
  宝塔默认是 `try_files $uri $uri/ /index.html;`，那会让所有死链返回首页并带 200 状态码（假 200），
  搜索引擎和访客都会以为旧页面还在。
- `nginx-extension-custom.conf` —— 放在宝塔的 `vhost/nginx/extension/<域名>/` 目录里，
  作用是给 HTML 加 `no-cache`（静态资源仍走长缓存）。放这里的好处是：在面板里改站点设置时不会被覆盖。

## 万一要重建（换机器 / 重装）

1. 新机器装宝塔面板，建站：域名 `eugenenie.top`，根目录 `/www/wwwroot/eugenenie.top`
2. 把 `nginx-vhost.conf` 的内容写进 `/www/server/panel/vhost/nginx/eugenenie.top.conf`；
   在 `extension/eugenenie.top/` 下放 `nginx-extension-custom.conf`；然后 `nginx -t && nginx -s reload`
3. `dnf install -y rsync`，并把部署公钥加进 `/root/.ssh/authorized_keys`（公钥见仓库根 `README.md`）
4. GitHub 仓库 Secrets 里更新 `SSH_HOST`（新机器 IP），按需更新 `SSH_PORT` / `SSH_USER` / `SSH_PATH`
5. 域名 A 记录指向新 IP；在宝塔里一键申请 HTTPS 证书
6. 推一次代码，或在 Actions 页面点 **Run workflow** 验证

同账号内换服务器时，记得在备案系统里做一次「变更备案 → 更换服务器实例」。
