' Launcher for auto-publish.ps1 -- starts it with NO console window at all.
'
' Why this file exists:
'   When Task Scheduler runs powershell.exe directly, Windows first creates a
'   console window in the interactive session; "-WindowStyle Hidden" only takes
'   effect once powershell is already running, so the window flashes and vanishes.
'   wscript.exe is a GUI-subsystem program and never creates a console, so asking
'   it to launch powershell with window style 0 keeps the console hidden from the
'   very start. No flash.
'
' IMPORTANT: keep this file ASCII-only.
'   Windows Script Host reads .vbs as ANSI, not UTF-8. Non-ASCII comments get
'   mis-decoded under a CJK code page, which can swallow line breaks and silently
'   break the script (it then exits 0 without doing anything). Chinese notes about
'   this launcher live in README.md instead.
'
' Run manually:  wscript.exe D:\blog\auto-publish-hidden.vbs
'
' To revert to the original behaviour, point the scheduled task action back at:
'   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\blog\auto-publish.ps1"

Option Explicit

Dim sh, repo, script, cmd
repo = "D:\blog"

Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = repo

script = repo & "\auto-publish.ps1"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """"

' third argument False = do not wait for powershell to finish
sh.Run cmd, 0, False
