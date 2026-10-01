' 启动器：以完全隐藏的方式运行 auto-publish.ps1。
'
' 为什么需要这个文件：
'   计划任务每 5 分钟直接调 powershell.exe 时，Windows 会先在你的桌面会话里
'   创建一个控制台窗口，"-WindowStyle Hidden" 是在 powershell 进程启动之后才
'   生效的，所以窗口会闪一下再消失。
'   wscript.exe 属于 GUI 子系统程序，本身不会创建控制台窗口，因此由它去拉起
'   powershell 时设置窗口样式为 0（隐藏），黑框就完全不会出现。
'
' 手动运行：双击本文件，或在命令行执行  wscript.exe D:\blog\auto-publish-hidden.vbs

Option Explicit

Dim sh, repo, script, cmd
repo = "D:\blog"

Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = repo

script = repo & "\auto-publish.ps1"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """"

' 第三个参数 False = 不等待脚本结束，wscript 立即退出
sh.Run cmd, 0, False
