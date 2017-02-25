#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Network Adapter Rename
	.Description
      	Ändert den Default Pfad.
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
         2016-12-02 - Bug fixing PVS Duplicate Nic in Hyper-V (FI detection "LAN-Legacy") and some error messages (PHo)
		 2016-10-04 - Added Legacy Sufix to Network Name (PHo)
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
    
    $Networks = $Settings_Global.Settings.Networks.Network

    Foreach ($Network in $Networks) {
    
		Write-Verbose "Check for Network: $Network"
		$NetAdapter = Get-NetIPAddress | Where-Object{$_.IPAddress.ToString() -match $Network.IP} | Get-NetAdapter
	              
        # Checking for all founded Adapter
        Foreach($Element in $NetAdapter){

            # Checking if Legacy Adapter and FI envirmont /or/ Checking if Legacy Adapter /or/ else 
            IF (($Element.InterfaceDescription -like "Intel*Fast-Ether*") -and ($env:USERDNSDOMAIN -like "*dpk1*")) {
                $LegacyName = "LAN-Legacy"
				$NetAdapter_Name = $LegacyName
                }Elseif($Element.InterfaceDescription -like "Intel*Fast-Ether*"){
                $NetAdapter_Name = $Network.Name + "_Legacy"
                }Else{
                $NetAdapter_Name = $Network.Name
            }

            # Rename Adapter
            Get-NetAdapter -Name $Element.Name | Rename-NetAdapter -NewName $NetAdapter_Name

            # Disable IPv6 Protocol
            Disable-NetAdapterBinding -Name $NetAdapter_Name -ComponentID ms_tcpip6

            #Enable DNS Register
            Get-NetIPConfiguration -InterfaceAlias $NetAdapter_Name | Get-NetConnectionProfile | Set-DnsClient -RegisterThisConnectionsAddress:$true
			
            $Message = "LAN Adapter gefunden, $($NetAdapter_Name)"

            Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
			
            # Checking network type
            Switch ($Network.Type){
                PVS {

                    #Disable LAN-PVS NetworkAdapter Bindings
                    Disable-NetAdapterBinding -Name $NetAdapter_Name -ComponentID ms_msclient, ms_server, ms_pacer,ms_rspndr, ms_lltdio

                    #Disable LAN-PVS DNS Register
                    Get-NetIPConfiguration -InterfaceAlias $NetAdapter_Name | Get-NetConnectionProfile | Set-DnsClient -RegisterThisConnectionsAddress:$false

                    #Disable LAN-PVS Offload / Only Support on no Legacy Nics
                    IF (!($Element.InterfaceDescription -like "Intel*Fast-Ether*")){
                        Disable-NetAdapterChecksumOffload -Name $NetAdapter_Name -IpIPv4 -TcpIPv4 -TcpIPv6 -UdpIPv4 -UdpIPv6
                    }

                    $Message = "PVS Adapter gefunden, $($NetAdapter_Name)"

                    Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info

                    }

            } 
			
			# Legacy Support
			IF ($NetAdapter_Name -like $LegacyName){
			
				#Disable LAN-PVS NetworkAdapter Bindings
				Disable-NetAdapterBinding -Name $NetAdapter_Name -ComponentID ms_msclient, ms_server, ms_pacer,ms_rspndr, ms_lltdio

				#Disable LAN-PVS DNS Register
				Get-NetIPConfiguration -InterfaceAlias $NetAdapter_Name | Get-NetConnectionProfile | Set-DnsClient -RegisterThisConnectionsAddress:$false

				#Disable LAN-PVS Offload / Only Support on no Legacy Nics
				IF (!($Element.InterfaceDescription -like "Intel*Fast-Ether*")){
					Disable-NetAdapterChecksumOffload -Name $NetAdapter_Name -IpIPv4 -TcpIPv4 -TcpIPv6 -UdpIPv4 -UdpIPv6
				}

				$Message = "PVS Adapter gefunden, $($NetAdapter_Name)"

				Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
			
			}

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