#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Citrix PVS Import vDisk (BETA)
	.Description
        Importiert die zuvor erstelle vDisk.
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
         2016-12-XX - Script created (PHo)
#>

Begin {
#-----------------------------------------------------------[Pre-Initialisations]------------------------------------------------------------

#-----------------------------------------------------------[Functions]------------------------------------------------------------

# Function Add-PVSDevice
function Add-PVSvDisk() {
<#
    .SYNOPSIS
     ! Noch Offen !
    .DESCRIPTION
     ! Noch Offen !
    .PARAMETER IDFName
     ! Noch Offen !
    .EXAMPLE
     ! Noch Offen !
    .NOTES
     AUTHOR: Patrik Horn
     LASTEDIT: 28.03.2015
     VERSION: 1.00
    .LINK
     http://www.hornpa.de
#>
    [CmdletBinding(SupportsShouldProcess=$True)]
    param(
        [string]$Computername = $env:COMPUTERNAME,
        [Parameter(Mandatory=$True,Position=1)]
        [string]$SiteName,
        [Parameter(Mandatory=$True,Position=2)]
        [string]$StoreName,
        [Parameter(Mandatory=$True,Position=3)]
        [string]$vDiskName
    )

    # Variable
    $MCLI = "C:\Program Files\Citrix\Provisioning Services\MCLI.exe"

    # Check if Path exists
    $CheckingPath = Invoke-Command -ComputerName $Computername -ScriptBlock {
        Test-Path $using:MCLI
    } -Authentication Default
    # IF not exit abort function
    IF (!($CheckingPath)){
        $Msg = "Cloud not find ""$MCLI"" on ""$Computername"" "
        Write-Host "Error: $Msg" -ForegroundColor Red
        $Result = $Msg
        Return $Result
        Break
    }

    # Add vDisk to Store
    $Result = Invoke-Command -ComputerName $Computername -ScriptBlock {
        &"$using:MCLI" add diskLocator -r diskLocatorName=$using:vDiskName,siteName=$using:SiteName,storename=$using:StoreName
    } -Authentication Default

    #Return
    Return $Result

}

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
    
    # Varibalen
    $CTX_PVS_Server = $Settings_Global.Settings.Global.PVSServer
    $CTX_PVS_SiteName = $Settings_Global.Settings.Global.PVSStiteName
    $CTX_PVS_StoreName = $Settings_Global.Settings.Global.PVSStoreName
    $CTX_PVS_Path = $Settings_Global.Settings.Global.PVSStoreUNCPath  

    # To Do
    Add-PVSvDisk -Computername Z013SPWMK1CPVS2 -SiteName $CTX_PVS_SiteName -StoreName $CTX_PVS_StoreName -vDiskName $CTX_PVS_VHDName

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