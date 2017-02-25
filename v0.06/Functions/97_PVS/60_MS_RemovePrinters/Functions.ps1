#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Remove Printers
	.Description
      	Entferne alle Drucker welcher in der XML definiert wurde.
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
         2017-01-25 - Script created (PHo)
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
    
	$Printers = $Settings_Global.Settings.PrinterRemove.PrinterName

	Foreach ($Printer in $Printers)
	{
		
		$PrinterName = $Printer
		
		Write-Verbose "Removing Printer $($PrinterName)..."

		Try
		{
		
			Remove-Printer $PrinterName -ErrorAction Stop
			$Message = "Printer $PrinterName wurde erfolgreich enfternt."
			Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
			
		}
		Catch
		{
		
			$Message = "Printer $PrinterName wurde nicht erfolgreich enfternt, bitte Prüfen!"
			Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Warning
			
		}

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