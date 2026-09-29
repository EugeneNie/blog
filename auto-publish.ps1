<#
  自动发布：由 Windows 计划任务每 5 分钟调用一次。

  逻辑：检测到博客有改动 → 等文件停止修改 3 分钟（避免提交写了一半的文章）
        → 本地构建校验 → 自动 commit + push
        → 推送后 GitHub Actions 会自动构建并部署到阿里云服务器。

  手动运行一次：
      powershell -ExecutionPolicy Bypass -File D:\blog\auto-publish.ps1
  临时忽略"文件刚改过"的判断（立刻提交）：
      powershell -ExecutionPolicy Bypass -File D:\blog\auto-publish.ps1 -Force
  想关掉自动发布：
      Unregister-ScheduledTask -TaskName BlogAutoPublish -Confirm:$false

  日志：%LOCALAPPDATA%\blog-auto-publish.log
#>
param(
    [int]$SettleMinutes = 3,   # 文件停止修改多久之后才提交
    [int]$MaxFileMB = 10,      # 源文件超过这个大小就不自动提交，避免误传大文件
    [switch]$Force
)

$ErrorActionPreference = 'Continue'
$repo = $PSScriptRoot
Set-Location -LiteralPath $repo
$logFile = Join-Path $env:LOCALAPPDATA 'blog-auto-publish.log'

function Write-Log([string]$msg) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
}

function Resolve-Exe([string]$name, [string]$fallback) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if (Test-Path -LiteralPath $fallback) { return $fallback }
    return $null
}

$git  = Resolve-Exe 'git'  'D:\Git\cmd\git.exe'
$hugo = Resolve-Exe 'hugo' 'D:\hugo\hugo.exe'
if (-not $git -or -not $hugo) {
    Write-Log '找不到 git 或 hugo，已跳过这次自动发布'
    return
}

# 1) 有没有改动？没有就安静退出（不写日志，免得刷屏）
$status = & $git status --porcelain 2>&1
if ($LASTEXITCODE -ne 0) { Write-Log "git status 失败：$status"; return }
if (-not $status) { return }

# 只关注博客源文件，避免把临时文件、大文件顺手带走
$sourceDirs = @('content', 'static', 'layouts', 'assets', 'data', 'i18n', 'archetypes')
$files = @()
foreach ($d in $sourceDirs) {
    $p = Join-Path $repo $d
    if (Test-Path -LiteralPath $p) {
        $files += Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue
    }
}
$files += Get-ChildItem -LiteralPath $repo -File -Filter '*.toml' -ErrorAction SilentlyContinue
$files += Get-ChildItem -LiteralPath $repo -File -Filter '*.md' -ErrorAction SilentlyContinue

# 2) 刚改过的文件先等等，避免提交写了一半的文章
$threshold = (Get-Date).AddMinutes(-1 * $SettleMinutes)
$recent = $files | Where-Object { $_.LastWriteTime -gt $threshold } | Select-Object -First 1
if ($recent -and -not $Force) {
    Write-Log ('检测到改动，但 {0} 刚刚被修改过，等下一轮再提交' -f $recent.Name)
    return
}

# 3) 大文件保护
$big = $files | Where-Object { $_.Length -gt ($MaxFileMB * 1MB) } | Select-Object -First 1
if ($big) {
    Write-Log ('发现超过 {0}MB 的源文件（{1}），为避免误传已跳过，请手动处理' -f $MaxFileMB, $big.Name)
    return
}

# 4) 本地构建校验，失败就不推送（线上保持旧版本）
$buildOut = & $hugo --minify --gc 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Log "本地构建失败，已跳过本次自动提交：`r`n$buildOut"
    return
}

# 5) 提交并推送（非交互，凭据用 Windows 凭据管理器里已保存的 GitHub 登录）
$env:GIT_TERMINAL_PROMPT = '0'
$msg = 'auto: 更新博客 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
& $git add -A | Out-Null
$commitOut = & $git commit -q -m $msg 2>&1
if ($LASTEXITCODE -ne 0) { Write-Log "提交失败：$commitOut"; return }

$pushOut = & $git push 2>&1
if ($LASTEXITCODE -ne 0) { Write-Log "推送失败（检查网络或 GitHub 凭据）：$pushOut"; return }

Write-Log "已自动提交并推送：$msg"
