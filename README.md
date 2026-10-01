# 我的博客（Hugo + PaperMod）

## 日常写作流程

```powershell
hugo new content posts/新文章.md   # 新建文章，写在 content/posts/ 下
hugo server -D                     # 本地预览：http://localhost:1313
```

预览没问题后，提交并推送，剩下的交给 GitHub Actions：

```powershell
git add .
git commit -m "新增文章：xxx"
git push
```

### 三种发布方式

| 方式 | 你要做什么 | 什么时候上线 |
| --- | --- | --- |
| 自动（默认已开启） | **什么都不用做**，改完保存即可 | 文件停止修改 3 分钟后自动提交，约 1 分钟后上线 |
| 立即发布 | 运行 `.\publish.ps1` | 立刻提交推送，约 1 分钟上线 |
| 手动 | `git add . && git commit -m "..." && git push` | 同上 |

自动发布的原理：Windows 计划任务 `BlogAutoPublish` 每 5 分钟运行一次 `auto-publish.ps1`，检测到博客有改动、且本地构建通过时，自动 `git commit + push`。带上这些保护：文件刚改过会再等一轮（避免提交写了一半的文章）、源文件超过 10MB 不自动提交、本地构建失败不推送。

任务实际执行的命令是 `wscript.exe "D:\blog\auto-publish-hidden.vbs"`，由这个 VBS 启动器再以隐藏方式拉起 `auto-publish.ps1`。

> **为什么要多一层 VBS 启动器？**
> 计划任务是以「只在用户登录时运行」的方式配置的，直接调用 `powershell.exe` 时，Windows 会先在当前桌面会话里创建控制台窗口，`-WindowStyle Hidden` 要等 PowerShell 进程起来之后才生效，所以会看到黑框一闪而过（每 5 分钟一次）。
> `wscript.exe` 属于 GUI 子系统程序，本身不会创建控制台窗口；由它以窗口样式 `0`（隐藏）去拉起 PowerShell，控制台窗口从创建那一刻就是隐藏的，不会再闪。
>
> **注意：`auto-publish-hidden.vbs` 必须保持纯 ASCII 内容。** Windows Script Host 按 ANSI（本机为 GBK）读取 `.vbs`，UTF-8 中文注释会被解码成乱码，甚至吃掉换行符，导致脚本静默失效（退出码 0 但什么都没做）。中文说明一律写在本 README 里。`auto-publish.ps1` 带 UTF-8 BOM，PowerShell 能正确识别，不受此限制。
>
> 想改回原来的直接调用方式，把计划任务的操作改回 `powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\blog\auto-publish.ps1"` 即可（黑框会重新出现）。

日志在 `%LOCALAPPDATA%\blog-auto-publish.log`；不想用自动发布了就执行：

```powershell
Unregister-ScheduledTask -TaskName BlogAutoPublish -Confirm:$false
```

注意：自动发布需要**这台电脑开机并登录**；电脑关着的时候改动不会被推上去。

## 自动化是怎么工作的

`.github/workflows/deploy.yml` 定义了这条流水线：

1. 推送到 `main` 分支（或手动触发）时自动开始；
2. 检出代码，并拉取 `themes/PaperMod` 子模块（主题固定在同一版本，保证构建结果稳定）；
3. 用 Hugo extended 0.166.0 执行 `hugo --minify --gc`，生成 `public/`；
4. 通过 SSH 连上阿里云服务器：先校验站点目录 → 把旧站点打包备份 → `rsync --delete` 把 `public/` 同步到网站根目录（属主设为 `www:www`，和宝塔保持一致）。

几个安全设计：

- `rsync --delete` 会删掉网站根目录里多余的文件，但以 `.` 开头的隐藏文件（`.well-known/`、`.user.ini` 等）都保留，不影响 HTTPS 证书续签和面板配置；
- 如果 `SSH_PATH` 指向的目录既没有 `index.html` 也不是空目录，流水线直接中止，避免误删别的目录；
- 每次部署前会打包一份 `blog-backup-<时间戳>.tgz` 放在站点目录的上一级，保留最近 5 份。

服务器侧的前提条件（本机已配好，换机器时注意）：`rsync` 已安装（`dnf install -y rsync`）、`root` 已授权 `blog-ci-deploy` 公钥、宝塔站点属主是 `www:www`。

本地预览和 CI 构建用的是同一个 Hugo 版本，结果一致。

## 一次性配置

### 1. 服务器上授权部署公钥

把本机 `C:\Users\kk\.ssh\blog-deploy-ed25519.pub` 的内容（一整行）追加到服务器的 `/root/.ssh/authorized_keys`。
用宝塔面板的话，打开 **终端** 执行：

```bash
mkdir -p /root/.ssh && chmod 700 /root/.ssh
echo "公钥内容粘贴到这里" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### 2. 仓库里配置 Secrets

仓库 **Settings → Secrets and variables → Actions → New repository secret**，需要这几项：

| 名称 | 值 |
| --- | --- |
| `SSH_HOST` | 服务器 IP，例如 `8.130.75.245` |
| `SSH_PORT` | SSH 端口，默认 `22` |
| `SSH_USER` | 登录用户，宝塔 CentOS 一般是 `root` |
| `SSH_PATH` | 网站根目录，宝塔默认是 `/www/wwwroot/eugenenie.top` |
| `SSH_PRIVATE_KEY` | 本机 `C:\Users\kk\.ssh\blog-deploy-ed25519` 的全部内容（含 BEGIN/END 两行） |

配好之后改点东西 `git push`，或到 Actions 页面点 **Run workflow** 手动跑一次验证。

### 3. 本地关联远程仓库（已完成）

```powershell
git remote add origin https://github.com/EugeneNie/blog.git
git push -u origin main
```

## 出问题怎么回滚

```bash
cd /www/wwwroot/eugenenie.top
tar xzf ../blog-backup-20260929-153000.tgz   # 换成实际备份文件名
```

备份在站点目录的上一级，`ls ../blog-backup-*.tgz` 可以看到全部。

## 常用命令

```powershell
hugo server -D                          # 本地预览（含草稿）
hugo server --disableFastRender         # 样式没刷新时用这个
hugo --minify --gc                      # 本地构建，输出到 public/
git submodule update --remote --merge themes/PaperMod   # 升级主题到最新版
```

> `themes/dream/`、`themes/hugo-PaperMod-master/` 是之前留下的备用/解压副本，已在 `.gitignore` 中忽略，不会提交。
