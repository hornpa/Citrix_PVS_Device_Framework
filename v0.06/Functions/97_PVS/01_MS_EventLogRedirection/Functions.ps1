#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Eventlog Redirection
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
    
	$CTX_PVS_Static_Cache = $Settings_Global.Settings.Global.EventLogRedirection

	$RegKeyApp = "HKLM:\SYSTEM\CurrentControlSet\services\eventlog\application"
	$RegKeySec = "HKLM:\SYSTEM\CurrentControlSet\services\eventlog\security"
	$RegKeySys = "HKLM:\SYSTEM\CurrentControlSet\services\eventlog\System"

	$RegKeyAppValue = $CTX_PVS_Static_Cache+"\Application.evtx"
	$RegKeySecValue = $CTX_PVS_Static_Cache+"\Security.evtx"
	$RegKeySysValue = $CTX_PVS_Static_Cache+"\System.evtx"

    # Set Registry Keys
    Try{
        
	    Set-ItemProperty -Path $RegKeyApp -Name "File" -Value $RegKeyAppValue -Type String -ErrorAction Stop
	    Set-ItemProperty -Path $RegKeySec -Name "File" -Value $RegKeySecValue -Type String -ErrorAction Stop
	    Set-ItemProperty -Path $RegKeySys -Name "File" -Value $RegKeySysValue -Type String -ErrorAction Stop

	    Set-ItemProperty -Path $RegKeyApp -Name "Flags" -Value 1 -Type DWORD -ErrorAction Stop
	    Set-ItemProperty -Path $RegKeySec -Name "Flags" -Value 1 -Type DWORD -ErrorAction Stop
	    Set-ItemProperty -Path $RegKeySys -Name "Flags" -Value 1 -Type DWORD -ErrorAction Stop

        $Message =  "Die Einstellungen für $scriptName_Sub wurden gesetzt."

        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info

        }Catch{

        $ErrorMessage = "Die Einstellungen fuer $scriptName_Sub konnten nicht gesetzt werden!"  + [System.Environment]::NewLine + `
                        "$($Error)"

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