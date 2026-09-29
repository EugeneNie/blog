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

也可以直接运行 `.\publish.ps1`（会先本地构建一次做校验，再自动提交推送）。

## 自动化是怎么工作的

`.github/workflows/deploy.yml` 定义了这条流水线：

1. 推送到 `main` 分支（或手动触发）时自动开始；
2. 检出代码，并拉取 `themes/PaperMod` 子模块（主题固定在同一版本，保证构建结果稳定）；
3. 用 Hugo extended 0.166.0 执行 `hugo --minify --gc`，生成 `public/`；
4. 把 `public/` 作为 Pages 产物上传，并发布到 GitHub Pages。

本地预览、CI 构建用的是同一个 Hugo 大版本，结果一致。

## 首次配置（只需要做一次）

1. 在 GitHub 上新建一个仓库（建议 `blog`，或直接用 `<你的用户名>.github.io`）。
2. 本地关联远程仓库并推送：

   ```powershell
   git remote add origin https://github.com/<你的用户名>/<仓库名>.git
   git push -u origin main
   ```

3. 打开仓库 **Settings → Pages**，把 **Source** 选为 **GitHub Actions**。
4. 自定义域名 `eugenenie.top`：
   - **Settings → Pages → Custom domain** 填 `eugenenie.top`，保存并勾选 **Enforce HTTPS**；
   - 在阿里云 DNS（`dns9.hichina.com` / `dns10.hichina.com`）添加解析：
     - `A` 记录，主机记录 `@`，指向 `185.199.108.153`、`185.199.109.153`、`185.199.110.153`、`185.199.111.153`；
     - `CNAME` 记录，主机记录 `www`，指向 `<你的用户名>.github.io`。
   - 域名验证通过后会自动签发 HTTPS 证书，`static/CNAME` 里已经写好了域名。

## 常用命令

```powershell
hugo server -D                          # 本地预览（含草稿）
hugo server --disableFastRender         # 样式没刷新时用这个
hugo --minify --gc                      # 本地构建，输出到 public/
git submodule update --remote --merge themes/PaperMod   # 升级主题到最新版
```

> `themes/dream/`、`themes/hugo-PaperMod-master/` 是之前留下的备用/解压副本，已在 `.gitignore` 中忽略，不会提交。
