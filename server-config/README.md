# 服务器侧配置备忘（换机器时照这个搬）

现在这台博客服务器是阿里云 ECS `i-0jl6476iznsm9py1czng`（8.130.75.245，乌兰察布），
它属于一个可能已经无法登录的阿里云账号（注册手机号已停用），所以把服务器侧的必要配置留档在这里。
万一机器到期被回收，照下面重建即可，博客内容本身全在这个 GitHub 仓库里，不会丢。

## 现状

| 项目 | 值 |
| --- | --- |
| 系统 | Alibaba Cloud Linux 3（OpenAnolis Edition） |
| 面板 | 宝塔面板（8888 端口，安全入口记录在服务器 `/www/server/panel/data/admin_path.pl`） |
| Web 服务 | 宝塔自带的 nginx（`/www/server/nginx`） |
| 站点根目录 | `/www/wwwroot/eugenenie.top`，属主 `www:www` |
| HTTPS 证书 | 宝塔自动申请续期（Let's Encrypt，HTTP 校验），路径 `/www/server/panel/vhost/cert/eugenenie.top/` |
| 部署方式 | GitHub Actions 构建 → `rsync --delete` 推到站点根目录，见 `.github/workflows/deploy.yml` |

## 这两个文件是干什么的

- `nginx-vhost.conf` —— 站点主配置。**关键点**：`location / { try_files $uri $uri/ =404; }`。
  宝塔默认是 `try_files $uri $uri/ /index.html;`，那会让所有死链返回首页并带 200 状态码（假 200），
  搜索引擎和访客都会以为旧页面还在。
- `nginx-extension-custom.conf` —— 放在宝塔的 `vhost/nginx/extension/<域名>/` 目录里，
  作用是给 HTML 加 `no-cache`（静态资源仍走长缓存）。放这里的好处是：在面板里改站点设置时不会被覆盖。

## 换新机器要做的 6 步

1. 新机器装宝塔面板，建站：域名 `eugenenie.top`，根目录 `/www/wwwroot/eugenenie.top`
2. 把 `nginx-vhost.conf` 的内容写进 `/www/server/panel/vhost/nginx/eugenenie.top.conf`；
   在 `extension/eugenenie.top/` 下放 `nginx-extension-custom.conf`；然后 `nginx -t && nginx -s reload`
3. `dnf install -y rsync`，并把部署公钥加进 `/root/.ssh/authorized_keys`（公钥见仓库 `README.md`）
4. GitHub 仓库 Secrets 里更新 `SSH_HOST`（新机器 IP），按需更新 `SSH_PORT` / `SSH_USER` / `SSH_PATH`
5. 域名 A 记录指向新 IP；在宝塔里一键申请 HTTPS 证书
6. 推一次代码，或在 Actions 页面点 **Run workflow** 验证

## 如果连域名也拿不回来

域名是在同一个阿里云账号下注册的（`eugenenie.top`，到期日 **2026-10-27**）。
真要换域名，需要改的地方一共三处：`hugo.toml` 里的 `baseURL`、GitHub 仓库的 `SSH_*` Secrets（不用改）、
以及服务器上的 nginx 配置和证书。其余的自动化流程都不用动。

## 推荐迁移路线：域名和 ICP 备案都在自己的账号里

背景：博客服务器属于一个无法登录的旧阿里云账号（注册手机号已停用），
但 `eugenenie.top` 的域名和 ICP 备案都在当前可用的账号里。所以迁移只是"换一台机器"，
备案主体、接入商都不变，在备案系统里做 **变更备案 / 更换服务器实例** 就行（同账号内通常很快）。

1. **先续费域名**：`eugenenie.top` 到期日 2026-10-27（.top），建议一次续 2–3 年。
2. **在当前账号买新服务器**：轻量应用服务器，大陆地域（乌兰察布/张家口/北京），2核2G、3M 带宽、包年；
   镜像选「系统镜像 → Alibaba Cloud Linux 3」。**不要选宝塔应用镜像**——静态博客用不到面板，
   少一个面板就少一个公网攻击面。（想要图形界面也可以后面再装。）
3. **备案里把服务器换过去**：控制台 → 备案 → 变更备案 → 更换服务器实例。
   备案期间域名仍解析到老服务器，站点不断。
4. **新机器初始化**（照本目录的配置做）：
   - `dnf install -y nginx rsync`；建站点目录 `/www/wwwroot/eugenenie.top`，属主 `nginx:nginx`
   - 落地站点配置（参考 `nginx-vhost.conf` 的规则：`try_files $uri $uri/ =404` + HTML 不缓存）
   - 给 `root` 加 CI 部署公钥（公钥见仓库根 `README.md`）
5. **改 CI Secrets**：`SSH_HOST` 换成新 IP，路径不同则一并改 `SSH_PATH`。
6. **验证**：Actions 里 Run workflow；检查首页 200、死链 404、HTML 带 `Cache-Control: no-cache`。

切换顺序：新机器先跑起来（DNS 还没切时用 `curl -H "Host: eugenenie.top"` 本地验证）
→ 切 DNS → 申请 HTTPS 证书并配置自动续期 → 观察几天 → 老机器随它到期。
