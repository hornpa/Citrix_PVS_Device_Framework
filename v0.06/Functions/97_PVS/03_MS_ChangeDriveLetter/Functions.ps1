#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Change Drive Letter
	.Description
      	Ändert den Luafwerksbuchstaben.
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
      	 2016-08-05 - Script created (PHo)
#>

param([string]$LastDriveLetter)
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
    
    [string]$LastDriveLetter = $Settings_Global.Settings.Global.LastDriveLetter

    $Local_Disk_Drives = Get-WmiObject win32_logicaldisk -filter 'DriveType=5' | Sort-Object -property DeviceID -Descending

    Foreach ($Local_Disk_Drive in $Local_Disk_Drives) {

        Write-Verbose "Found CDROM drive on $($_.DeviceID)"
        $a = mountvol $Local_Disk_Drive.DeviceID /l

        # Get all avaiable Drive Letters and use the first one
        $UseDriveLetter = Get-ChildItem function:[d-$LastDriveLetter]: -Name | Where-Object { (New-Object System.IO.DriveInfo($_)).DriveType -eq 'NoRootDirectory' } | Sort-Object -Descending | Select-Object -First 1

        If ($UseDriveLetter -ne $null -AND $UseDriveLetter -ne "") {
            Write-Verbose "$UseDriveLetter is available to use"
            Write-Verbose "Changing $($Local_Disk_Drive.DeviceID) to $UseDriveLetter"
            mountvol $Local_Disk_Drive.DeviceID /d
            $a = $a.Trim()
            mountvol $UseDriveLetter $a
            }else{
            Write-Verbose "No available drive letters found."
        }

    }

    # Check Partion E
    $Local_HDD_Drives = Get-WmiObject win32_logicaldisk -filter 'DriveType=3' | Where-Object { ($_.DeviceID -notlike 'C:') -and ($_.DeviceID -notlike 'X:') }

    Foreach ($Local_HDD_Drive in $Local_HDD_Drives) {

        Write-Verbose "Found HDD drive on $($_.DeviceID)"

        # Get all avaiable Drive Letters and use the first one
        $UseHDDLetter = Get-ChildItem function:[d-$LastDriveLetter]: -Name | Where-Object { (New-Object System.IO.DriveInfo($_)).DriveType -eq 'NoRootDirectory' } | Sort-Object | Select-Object -First 1

        If ($UseHDDLetter -ne $null -AND $UseHDDLetter -ne "") {

            Write-Verbose "$UseHDDLetter is available to use"
            Write-Verbose "Changing $($Local_HDD_Drive.DeviceID) to $UseHDDLetter"

            Get-Partition -DriveLetter $($Local_HDD_Drive.DeviceID).TrimEnd(":") | Set-Partition -NewDriveLetter $UseHDDLetter.TrimEnd(":")

            }else{

            Write-Verbose "No available drive letters found."

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