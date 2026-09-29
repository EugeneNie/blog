# 一键发布：本地先构建校验，再提交推送到 GitHub，剩下的由 Actions 自动部署
param(
    [string]$Message = "更新博客 $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
)

Set-Location -LiteralPath $PSScriptRoot

Write-Host "1/3 本地构建校验（hugo --minify --gc）..." -ForegroundColor Cyan
& hugo --minify --gc
if ($LASTEXITCODE -ne 0) {
    Write-Host "构建失败，已中止，没有提交任何内容。" -ForegroundColor Red
    exit 1
}

Write-Host "2/3 暂存改动..." -ForegroundColor Cyan
& git add -A
$changes = & git status --porcelain
if (-not $changes) {
    Write-Host "没有需要提交的改动，结束。" -ForegroundColor Yellow
    exit 0
}
$changes | ForEach-Object { "  $_" }

Write-Host "3/3 提交并推送..." -ForegroundColor Cyan
& git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "提交失败，已中止。" -ForegroundColor Red
    exit 1
}

& git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "推送失败，请检查远程仓库地址和登录凭据。" -ForegroundColor Red
    exit 1
}

Write-Host "已推送，GitHub Actions 会自动构建并部署。" -ForegroundColor Green
