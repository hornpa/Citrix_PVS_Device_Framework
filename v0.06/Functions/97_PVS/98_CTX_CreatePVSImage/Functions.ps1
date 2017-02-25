#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Citrix PVS Create vDisk
	.Description
      	Erstellt eine VHD/VHDX Image.
        Getestet auf Hyper mit
         Generation 1 VMs: Funktioniert sowohl VHD und VHDX
         Generation 2 VMs: Funktioniert nicht!
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
		 2017-01-10 - Supporting now PVS Target Device LTSR versions and Added Prefix for RSSAW and RSSIA Images (PHo)
         2016-12-XX - Some code clean up (PHo)
         2016-11-XX - Add XML Setting for vhd or vhdx formart (PHo)
         2016-10-05 - Some Major Code changes (PHo)
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
    
    # Varibalen
    $Registry_FI_Serverschichten = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\VRZ_AppCfg\Daten\Serverschichten"
    $CTX_PVS_Server = $Settings_Global.Settings.Global.PVSServer
    $CTX_PVS_StoreName = $Settings_Global.Settings.Global.PVSStoreName
    $CTX_PVS_Path = $Settings_Global.Settings.Global.PVSStoreUNCPath  
    $CTX_PVS_TargetDeivce = "Provisioning Services Target Device" 
    $CTX_PVS_P2PVS = "$env:ProgramFiles\Citrix\Provisioning Services\P2PVS.exe"
    $CTX_PVS_Volume = $env:SystemDrive

	#Setting VHD Name
	Switch -Wildcard ($env:COMPUTERNAME){
        
        *TK111* {
        
            Write-Verbose "Computer is SAW"
			$CTX_PVS_VHDName = "RSSAW_"+($Registry_FI_Serverschichten.Release)+"-"+(Get-Date -Format yyyy-MM-dd_HH-mm)
			$CTX_PVS_VHDName = $CTX_PVS_VHDName.Replace(".","_")

        }
    
        *TK112* {
        
            Write-Verbose "Computer is SIA"
			$CTX_PVS_VHDName = "RSSIA_"+($Registry_FI_Serverschichten.Release)+"-"+(Get-Date -Format yyyy-MM-dd_HH-mm)
			$CTX_PVS_VHDName = $CTX_PVS_VHDName.Replace(".","_")

        }
		
		Default {
		
			Write-Verbose "No FI System"
			$CTX_PVS_VHDName = (Get-Date -Format yyyy-MM-dd_HH-mm)
			$CTX_PVS_VHDName = $CTX_PVS_VHDName.Replace(".","_")

		}

    }
	
    # Entweder P2Vhdx für vhdx Ausgabe oder P2Vhd für vhd Ausgabe 
    Switch -Wildcard ($Settings_Global.Settings.Global.PVSVHDFormat){
        vhd { $CTX_PVS_VHD_Type = "P2Vhd" }
        vhdx { $CTX_PVS_VHD_Type = "P2Vhdx" }
    }

    # Run PVS Imaging
    IF ( ($InstalledPrograms| ? {$_.DisplayName -like "*$CTX_PVS_TargetDeivce*"}) -and (Test-Path -Path $CTX_PVS_P2PVS) ){

        $Message =  "VHD Destinantion: $CTX_PVS_Path"
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info

        $Para = "$CTX_PVS_VHD_Type ""$CTX_PVS_VHDName"" "+$CTX_PVS_Path+" /AutoFit $CTX_PVS_Volume"
        $Process = Start-Process $CTX_PVS_P2PVS -Wait -ArgumentList $Para

        }Else{

        $Message =  "Citrix Target Device Installation konnte nicht gefunden werden!"
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Warning


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