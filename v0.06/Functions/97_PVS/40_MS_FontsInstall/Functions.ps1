#Requires -Version 3.0
#Requires -RunAsAdministrator 
#Requires -Modules hp_Log

<#
    .SYNOPSIS
        Microsoft Fonts Install
	.Description
      	Installiert alle Fonts aus einem Ordner welcher in der XML definiert wurde.
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
    
    $Result = @()
    $Force = $true
    $FONTS_Path = $Settings_Global.Settings.Global.FontsPath

    IF ([string]::IsNullOrEmpty($FONTS_Path))
    {
        # Null or Empty
        $Message =  "Es wurde kein Pfad in der XML hinterlegt"
        Write-Log_hp -Path $LogPS -Message $Message -Component $scriptName_Sub -Status Info
    }
    Else
    {

        # has a Value
        $FONTS_DIR= Get-ChildItem -Path $FONTS_Path -Recurse -Include *.ttf, *.otf
        $FONTS = 0x14

        $objShell =  New-Object -ComObject Shell.Application
        $objFolder = $objShell.NameSpace($FONTS)

        Foreach ($Font in $FONTS_DIR)
        {

            $Result_tmp_fontname = $Font.Name
    
            $Msg = "Font: $Result_tmp_fontname "
            Write-Log_hp -Path $LogPS -Value "$Msg" -Component $scriptName_Sub -Severity 1

            IF (Test-Path -Path "C:\Windows\Fonts\$($Font.Name)")
            {

                # Font exist

                IF ($Force)
                {
        
                    $Msg = "Force aktiviert, wird gelöscht vor installation!"
                    Write-Log_hp -Path $LogPS -Value "$Msg" -Component $scriptName_Sub -Severity 1
                    Remove-Item "C:\Windows\Fonts\$($Font.Name)"
                    $Result_tmp_force = $Msg

                }
                Else
                {
        
                    $Msg = " - Ist bereits installiert!"
                    Write-Log_hp -Path $LogPS -Value "$Msg" -Component $scriptName_Sub -Severity 2
                    $Result_tmp_lastaction = $Msg

                }

            }
            Else
            {
        
                # Font don't exist
    
                $objFolder.CopyHere($Font.FullName)
                $Msg = " - Wird installiert..."
                Write-Log_hp -Path $LogPS -Value "$Msg" -Component $scriptName_Sub -Severity 1
                $Result_tmp_lastaction = $Msg

            }

            #region Füge ergbniss zum Array hinzu
            $Result_tmp = New-Object PSObject -Property @{
                "FontName" = "$Result_tmp_fontname";
                "Letzte Aktion" = "$Result_tmp_lastaction";
                "Force?" = "$Result_tmp_force";
            }
            $Result += $Result_tmp
            #endregion
    
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