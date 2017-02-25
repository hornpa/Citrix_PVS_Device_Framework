#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Install Programs
	.Description
      	Install all Program from a specific path. It search for "Deploy-Application.ps1"
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
		 2017-01-09 - Added support for PSWrapper.ps1 (PHO)
         2016-11-02 - Added Bypass to install (PHo)
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
    Write-Host "Function: $($scriptName_Sub)" -ForegroundColor Green
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Process {
    IF ($scriptRunning  -like 1){
	####################################################################
	## Code Section - Start
	####################################################################

    Switch -Wildcard ($env:COMPUTERNAME){
        
        *TK111* {
        
            Write-Verbose "Computer is SAW"
            $Path = $Settings_Global.Settings.Global.ProgamInstallPathSAW

        }
    
        *TK112* {
        
            Write-Verbose "Computer is SIA"
            $Path = $Settings_Global.Settings.Global.ProgamInstallPathSIA

        }
		
		Default {
        
            Write-Verbose "Computer is SIA"
            $Path = $Settings_Global.Settings.Global.ProgamInstallPath

        }

    }

	Write-Verbose "Unblock Files..."
	$UnblockFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.ps1" | Unblock-File
	
    Write-Verbose "Path: $Path"
    $InstallPrograms = Get-ChildItem -Path $Path -Include Deploy-Application.ps1,PSWrapper.ps1 -Recurse | Sort-Object Directory
    $InstallPrograms_Summary = $InstallPrograms.Count
    $InstallPrograms_Current = 0

    Foreach ($InstallProgram in $InstallPrograms){
        $Program = Split-Path (Split-Path (Split-Path $InstallProgram.FullName)) -Leaf
        $Version = Split-Path (Split-Path $InstallProgram.FullName) -Leaf
        Write-Verbose " Runing... $($InstallProgram.FullName) ..."
        $Message =  "Installiere... "  + [System.Environment]::NewLine + `
                    "Program: $Program" + [System.Environment]::NewLine + `
                    "Version: $Version" + [System.Environment]::NewLine + ` 
                    "Pfad: $($InstallProgram.FullName)"
        Write-Progress -Activity $scriptName_Sub -Status $Program -PercentComplete ([math]::Round((100*$InstallPrograms_Current)/$InstallPrograms_Summary))     
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info -NoOutput
        Start-Process -Wait PowerShell.exe -ArgumentList "-ExecutionPolicy Bypass -File ""$($InstallProgram.FullName)"""
        $InstallPrograms_Current++
        Start-Sleep 1
    }

	Write-Host "Load list with Installed Programs, can take some minutes!" -ForegroundColor Cyan
    $InstalledPrograms_x64 = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
    $InstalledPrograms_x86 = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* 
    $InstalledPrograms = $InstalledPrograms_x64 + $InstalledPrograms_x86
    #$InstalledPrograms = Get-WmiObject -Class Win32_Product

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