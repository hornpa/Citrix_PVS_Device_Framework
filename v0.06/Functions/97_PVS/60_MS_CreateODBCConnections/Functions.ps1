#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Create ODBC Connections
	.Description
      	Creates ODBC Connections from a XML File.
    .NOTES
		Author: 
         Patrik Horn
		Link:	
         www.hornpa.de
		History:
      	 2016-09-23 - Script created (PHo)
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
    
	$Connetions = $Settings_Global.Settings.ODBC.Connection

	Foreach ($Connetion in $Connetions){
		
		Write-Verbose "Running $($ODBC_Name)..."

		Write-Verbose "Check Platform..."
		Switch -Wildcard ($Connetion.Platform){
			"32"{
				Write-Verbose "Platform is 32-Bit"
				$ODBC_Platform = "32-bit"
				$RegistryPath = "HKLM:\SOFTWARE\Wow6432Node\ODBC\ODBC.INI\"
			}
			"64"{
				Write-Verbose  "Platform is 36-Bit"
				$ODBC_Platform = "64-bit"
				$RegistryPath = "HKLM:\SOFTWARE\ODBC\ODBC.INI\"
			}
			Default{
				Write-Verbose "Fehler die Platform wurde nicht erkannt, bitte Prüfen!"
				Exit
			}
		}

		Write-Verbose "Check DsnType..."
		Switch -Wildcard ($Connetion.DsnType){
			"System"{
				Write-Verbose "DsnType is System"
				$ODBC_DnsType = "System"
			}
			"User"{
				Write-Verbose  "DsnType is User"
				$ODBC_DnsType = "User"
			}
			Default{
				Write-Verbose "Fehler der Type wurde nicht erkannt, bitte Prüfen!"
				Exit
			}
		}


		Write-Verbose "Check Driver..."
		$ODBC_DriverName = $Connetion.Driver
		IF (Get-OdbcDriver -Name $ODBC_DriverName -Platform $ODBC_Platform){
			Write-Verbose "Driver available"
			}Else{
			Write-Verbose "Driver not available"
			Exit
		}

		Write-Verbose "Settings Variables"
		$ODBC_Name = $Connetion.Name
		$ODBC_Databases = $Connetion.Database
		$ODBC_Server = $Connetion.Server
		$ODBC_AnsiNPW = $Connetion.AnsiNPW
		$ODBC_LastUser = $Connetion.LastUser
		$ODBC_Description = $Connetion.Description

		$ODBC_Reg_Path = $RegistryPath+$ODBC_Name

		Write-Verbose "Creating ODBC Connection..."
		Try{
			Add-OdbcDsn -Name $ODBC_Name -DriverName $ODBC_DriverName -DsnType $ODBC_DnsType -Platform $ODBC_Platform -ErrorAction Stop
			Set-ItemProperty -Path $ODBC_Reg_Path -Name Database -Value $ODBC_Databases -ErrorAction Stop
			Set-ItemProperty -Path $ODBC_Reg_Path -Name Server -Value $ODBC_Server -ErrorAction Stop
			Set-ItemProperty -Path $ODBC_Reg_Path -Name Description -Value $ODBC_Description -ErrorAction Stop
			Set-ItemProperty -Path $ODBC_Reg_Path -Name LastUser -Value $ODBC_LastUser -ErrorAction Stop
			Set-ItemProperty -Path $ODBC_Reg_Path -Name AnsiNPW -Value $ODBC_AnsiNPW -ErrorAction Stop
			Set-ItemProperty -Path $ODBC_Reg_Path -Name Trusted_Connection -Value "No" -ErrorAction Stop
			$Message = "ODBC Verbindung $ODBC_Name wurde erfolgreich angelegt."
			Write-Log_hp -Path $LogPS -Message "$Message" -Component $scriptName_Sub -Status Info
			}Catch{
			$Message = "ODBC Verbindung $ODBC_Name wurde nicht angelegt, bitte werte Prüfen!"
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
	Write-Log_hp -Path $LogPS -Value "Elapsed Time: $ElapsedTimePS_Sub Seconds" -Component $scriptName_Sub -Severity 1
}