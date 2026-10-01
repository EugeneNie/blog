Option Explicit
Dim sh, rc, errMsg
Set sh = CreateObject("WScript.Shell")

On Error Resume Next
sh.CurrentDirectory = "D:\blog"
errMsg = Err.Description
On Error GoTo 0
WScript.Echo "CurrentDirectory err: [" & errMsg & "]"

On Error Resume Next
rc = sh.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""Start-Sleep -Seconds 1; 'x' | Out-File -Encoding ASCII D:\blog\_wsh_probe.txt""", 0, True)
errMsg = Err.Description & " (0x" & Hex(Err.Number) & ")"
On Error GoTo 0

WScript.Echo "Run rc: [" & rc & "]"
WScript.Echo "Run err: [" & errMsg & "]"
WScript.Echo "probe file exists: " & CreateObject("Scripting.FileSystemObject").FileExists("D:\blog\_wsh_probe.txt")
