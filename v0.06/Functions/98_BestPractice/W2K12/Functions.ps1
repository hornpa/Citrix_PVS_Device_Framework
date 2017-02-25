#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Best Practice - W2K12
	.Description
      	Best Practice Setting
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
      	 2016-08-05 - Script created (PHo)
#>

Begin {
#-----------------------------------------------------------[Pre-Initialisations]------------------------------------------------------------

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#-----------------------------------------------------------[Main-Initialisations]------------------------------------------------------------

	Write-Verbose "Function: Clear Error Variable Count"
	$Error.Clear()
	Write-Verbose "Function: Get PowerShell Start Date"
	$StartPS_Sub = (Get-Date)
	Write-Verbose "Set Variable with MyInvocation"
	$scriptDirectory_Sub = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
	$scriptName_Sub = (Get-Help "$scriptDirectory_Sub\Functions.ps1").SYNOPSIS
    $scriptRunning = ($Settings_Global.Settings.Functions | select -ExpandProperty childnodes | Where-Object {$_.Name -like ($scriptName_Sub -replace " ","")} ).'#text'	
	Write-Verbose "Function Name: $scriptName_Sub"
	Write-Verbose "Function Directory: $scriptDirectory_Sub"
    Write-Host "Running: Function $($scriptName_Sub)" -ForegroundColor Green
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Process {
    IF ($scriptRunning  -like 1){
	####################################################################
	## Code Section - Start
	####################################################################
    
    Write-Verbose "Disable Services"
    Set-Service BITS -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service FDResPub -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service CscService -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service wuauserv -StartupType Disable -ErrorAction SilentlyContinue

    Write-Verbose "Disable Scheduled Tasks"
    Disable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag" | Out-Null
    Disable-ScheduledTask -TaskName "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" | Out-Null
    Disable-ScheduledTask -TaskName "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" | Out-Null
    Disable-ScheduledTask -TaskName "\Microsoft\Windows\Windows Error Reporting\QueueReporting" | Out-Null
    Disable-ScheduledTask -TaskName "\Microsoft\Windows\Autochk\Proxy" | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "AitAgent" | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "ProgramDataUpdater" | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Consolidator" | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "KernelCeipTask" | Out-Null
    #Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Uploader" | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "UsbCeip" | Out-Null

    Write-Verbose "Citrix Best Practise"
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name NtfsDisableLastAccessUpdate -Value 00000001 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name DisableTaskOffload -Value 00000001 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name ServicesPipeTimeout -Value 180000 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Windows" -Name ErrorMode -Value 00000002 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoRemoteRecursiveEvents -Value 00000001 -Type DWord
    # Disable WindowsErrorReporting
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name DisablePasswordChange -Value 00000001 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name ClearPageFileAtShutdown -Value 00000000 -Type DWord
    # Default User anpassungen / Sollte auch per GPO gesetzt werden, da diese Einstellungen nur für neu Profile gesetzt werden!
    Set-ItemProperty -Path "Microsoft.PowerShell.Core\Registry::HKU\.DEFAULT\Control Panel\Desktop" -Name ScreenSaveActive -Value 0 -Type DWord
    Set-ItemProperty -Path "Microsoft.PowerShell.Core\Registry::HKU\.DEFAULT\Control Panel\Desktop" -Name AutoEndTaskss -Value 1 -Type String
    Set-ItemProperty -Path "Microsoft.PowerShell.Core\Registry::HKU\.DEFAULT\Control Panel\Desktop" -Name WaittoKillAppTimeout -Value 20000 -Type String
    # Disable Automatic Maintance
    # Kann nur mittels PSEXEC angehalten, da alle andere wege keine Berechtigung besitzen
    #& "$scriptDirectory\Files\psexec.exe" \\localhost -s schtasks /change /tn "\Microsoft\Windows\TaskScheduler\Maintenance Configurator" /disable
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\TaskScheduler\" -TaskName "Idle Maintenance" | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\TaskScheduler\" -TaskName "Manual Maintenance" | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\TaskScheduler\" -TaskName "Regular Maintenance" | Out-Null
    
	####################################################################
	## Code Section - End
	####################################################################
    }Else{
        $Message =  "Function wird nicht ausgefuehrt laut XML Datei."  + [System.Environment]::NewLine + `
                    "$scriptName_Sub Wert lautet $scriptRunning."
        Write-Log_hp -Path $LogPS -Message $Message -Component $scriptName_Sub -Status Warning
    }
}

#-----------------------------------------------------------[End]------------------------------------------------------------

End {
	Write-Verbose "Function: Get PowerShell Ende Date"
	$EndPS_Sub = (Get-Date)
	Write-Verbose "Function: Calculate Elapsed Time"
	$ElapsedTimePS_Sub = (($EndPS_Sub-$StartPS_Sub).TotalSeconds)
	Write-Log_hp -Path $LogPS -Message "Elapsed Time: $ElapsedTimePS_Sub Seconds" -Component $scriptName_Sub -Status Info
}