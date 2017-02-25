#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Network Adapter Checking Settings
	.Description
      	Checking that all Network Adapter has an IPv4 from a DHCP.
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
         2016-12-06 - Script created (PHo)
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
    
    $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where { $_.IpEnabled -eq $true }  

    ForEach ($NetworkAdapter in $NetworkAdapters) {
 
		$NetAdapterName = (Get-NetAdapter -InterfaceIndex $NetworkAdapter.InterfaceIndex).Name
		$Message = "Settings on NetworkAdapter $NetAdapterName "
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
 
        $Message = " - Enable DHCP"
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
        $NetworkAdapter.EnableDHCP() | Out-Null 

		$Message = " - Reset DNS Adresses to DHCP"
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
		Set-DnsClientServerAddress –InterfaceIndex $NetworkAdapter.InterfaceIndex -ResetServerAddresses
		
        $Message = " - Release IP"
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
        $NetworkAdapter.ReleaseDHCPLease() | Out-Null   

        $Message = " - Renewing IP Addresses"
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
        $NetworkAdapter.RenewDHCPLease() | Out-Null
				
		Start-Sleep -Seconds 30
		
		$NewIPAdress = (Get-NetIPAddress -InterfaceIndex $NetworkAdapter.InterfaceIndex).IPAddress
		
        $Message = " - New IP Address is ""$($NewIPAdress)"" "
        Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
    
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