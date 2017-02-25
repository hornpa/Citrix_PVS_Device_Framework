#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Spooler Redirection
	.Description
      	Ändert den Default Pfad.
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
    Write-Host "Function: $($scriptName_Sub)" -ForegroundColor Green
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Process {
    IF ($scriptRunning  -like 1){
	####################################################################
	## Code Section - Start
	####################################################################
    
    $CTX_PVS_SpoolerDirectory = $Settings_Global.Settings.Global.PrintSpoolerRedirection

	$RegKeySpooler = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print"
	$RegKeySpooler2 = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers"

	$RegKeySpoolerValue = $CTX_PVS_SpoolerDirectory
	$RegKeySpoolerValue2 = $CTX_PVS_SpoolerDirectory

    # Set Registry Keys
    Try{
        
	    Set-ItemProperty -Path $RegKeySpooler -Name "DefaultSpoolDirectory" -Value $RegKeySpoolerValue -Type String -ErrorAction Stop
	    Set-ItemProperty -Path $RegKeySpooler2 -Name "DefaultSpoolDirectory" -Value $RegKeySpoolerValue2 -Type String -ErrorAction Stop

        $Message =  "Die Einstellungen für $scriptName_Sub wurden gesetzt."

        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info

        }Catch{

        $ErrorMessage = "Die Einstellungen für $scriptName_Sub konnten nicht gesetzt werden!"  + [System.Environment]::NewLine + `
                        "$($error)"
        Write-Log_hp -Path $LogPS -Message $ErrorMessage -Component $scriptName_Sub -Status Error

    }

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