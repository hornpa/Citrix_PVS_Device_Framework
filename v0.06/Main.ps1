#Requires -Version 3.0
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
        Citrix Device Framework
	.Description
      	open
    .NOTES
		Author:
		 Patrik Horn (PHo)
		Link:
         www.hornpa.de
		History:
		 2017-01-XX - v0.06 - Update Function PageFile, Add Function for Fonts install, Add Function for Remove Printers (PHo)
		 2017-01-XX - v0.05 - Update Function CreatePVSImage, Update Load settings file depend on domain (PHo)
         2016-12-XX - v0.04 - Update Function Network Rename (PHo)
         2016-11-XX - v0.03 - Add Write-Progess, some code changes, 
							  update get-installedprograms from wmi to regedit, 
							  added Debug modus for main.ps1 and now its possible do disable some function in the xml setting file (PHo)
         2016-09-XX - v0.02 - Add Function for ODBC Connenctions, some code changes (PHo)
      	 2016-08-01 - v0.01 - Script created (PHo)
#>

Begin {
#-----------------------------------------------------------[Pre-Initialisations]------------------------------------------------------------

	#Set Error Action to Silently Continue
	$ErrorActionPreference = 'Stop'

	#Set Verbose Output
	$VerbosePreference = "SilentlyContinue" # Continue = Shows Verbose Output / SilentlyContinue = No Verbose Output

	#Get Start Time
	$StartPS = (Get-Date)

	#Set Enviorements
	Write-Verbose "Set Variable with MyInvocation"
	$scriptName_PS = Split-Path $MyInvocation.MyCommand -Leaf
	$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    $scriptHelp = Get-Help "$scriptDirectory\$scriptName_PS" -Full
    $scriptName_SYNOPSIS = $scriptHelp.SYNOPSIS
    $scriptName_NOTES =  $scriptHelp.alertSet.alert.text
    $scriptDebug = 0 # 0 = Disabled / 1 = Enabled
	
	# Load the Windows Forms assembly
	Add-Type -Assembly System.Windows.Forms

	#Check Log Folder
	Write-Verbose "Log Variables"
	$LogPS = "$env:windir\Logs\Scripts\"+(Get-Date -Format yyyy-MM-dd_HHmm)+"_"+$scriptName_SYNOPSIS+".log"
	IF (!(Test-Path (Split-Path $LogPS))){
		Write-Verbose "Create Log Folder"
		New-Item (Split-Path $LogPS) -Type Directory | Out-Null
	}

#-----------------------------------------------------------[Functions]------------------------------------------------------------

	#Load all PowerShell Modules
	Write-Verbose "Load PowerShell Modules..."
	Foreach ($PSModule in (Get-ChildItem ($scriptDirectory+"\PSM") -Recurse -Filter "*.psm1")){
		Import-Module $PSModule.FullName -Force
		Write-Verbose "---"
	}

#-----------------------------------------------------------[Main-Initialisations]------------------------------------------------------------

    ## Host Output
    $WelcomeMessage =   "##################################"  + [System.Environment]::NewLine + `
                        " $scriptName_SYNOPSIS"  + [System.Environment]::NewLine + `
                        " "  + [System.Environment]::NewLine + `
                        " $scriptName_NOTES"+ [System.Environment]::NewLine + `
                        "##################################"
                        
    Write-Host $WelcomeMessage -ForegroundColor Gray

    ## Load Preq
	Write-Host "Load Environments" -ForegroundColor Cyan
	$Language = (Get-Culture).Name
    $OS = Get-WmiObject -Class win32_operatingsystem
	$Services = Get-Service
	Write-Host "Load Setting File..." -ForegroundColor Cyan
    $SettingFileName = "Settings_"+$env:USERDOMAIN + ".xml"
    Write-Verbose "Checking if File exits"
    IF (Test-Path -Path $scriptDirectory\$SettingFileName)
    {
        [XML]$Settings_Global = Get-Content -Path "$scriptDirectory\$SettingFileName"
        Write-Host "Load successfully Setting File ""$SettingFileName"" "
    }
    Else
    {
        Write-Host "Settings File ""$SettingFileName"" could not found, exit script in 20 seconds" -Foreground Red
        Start-Sleep -Seconds 20
        Exit
    }
	Write-Host "Load list with Installed Programs, can take some minutes!" -ForegroundColor Cyan
    $InstalledPrograms_x64 = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
    $InstalledPrograms_x86 = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* 
    $InstalledPrograms = $InstalledPrograms_x64 + $InstalledPrograms_x86
	Write-Host "Load Functions List" -ForegroundColor Cyan
	$LoadFunctions_PVS = Get-ChildItem -Path "$scriptDirectory\Functions\97_PVS" -Include "Functions.ps1" -Recurse
    $LoadFunctions_Costum = Get-ChildItem -Path "$scriptDirectory\Functions\99_Costum" -Include "Functions.ps1" -Recurse
    ## Unblock all ps1 Files in Directory
    $UnblockFiles = Get-ChildItem -Path $scriptDirectory -Recurse -Filter "*.ps1" | Unblock-File
    ## Progressbar (LoadFunction + LoadFunction + 1[Section Bestpractice])
    $ProgressBar_Summary = $LoadFunctions_PVS.Count + $LoadFunctions_Costum.Count + 1
    $ProgressBar_Current = 0
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------


Process {
	####################################################################
	## Code Section - Start
	####################################################################

    #Run Functions AV
    $Msg_Section = "Section Best Practices"
    $ProgressBar_Current++
    Write-Host $Msg_Section -ForegroundColor Cyan 
    Switch -Wildcard ($OS.Version) {
            10.* {
                # Test Phase
                $Msg_Status = "Windows 10"
                Write-Verbose $Msg_Status
                Write-Progress -Activity $Msg_Section -Status $Msg_Status -PercentComplete ([math]::Round((100*$ProgressBar_Current)/$ProgressBar_Summary))
                IF ($scriptDebug -like 0){
                ."$scriptDirectory\Functions\98_BestPractice\W10\Functions.ps1"
                }
            }
            6.2* {
                # Test Phase
                $Msg_Status = "Windows 8.1"
                Write-Verbose $Msg_Status
                Write-Progress -Activity $Msg_Section -Status $Msg_Status -PercentComplete ([math]::Round((100*$ProgressBar_Current)/$ProgressBar_Summary))
                IF ($scriptDebug -like 0){
                ."$scriptDirectory\Functions\98_BestPractice\W81\Functions.ps1"
                }
            }
            6.3* {
                $Msg_Status = "Windows 2012 R2"
                Write-Verbose $Msg_Status
                Write-Progress -Activity $Msg_Section -Status $Msg_Status -PercentComplete ([math]::Round((100*$ProgressBar_Current)/$ProgressBar_Summary))
                IF ($scriptDebug -like 0){
                ."$scriptDirectory\Functions\98_BestPractice\W2K12\Functions.ps1"
                }
            }
    }

    #Run Functions PVS
    $Msg_Section = "Section PVS"
    Write-Host $Msg_Section -ForegroundColor Cyan 
    Foreach ($Function in $LoadFunctions_PVS){
        $FunctionName = Split-Path (Split-Path $Function.FullName) -Leaf
        $Msg_Status = " Running... $FunctionName"
        Write-Verbose $Msg_Status 
        $ProgressBar_Current++
        Write-Progress -Activity $Msg_Section -Status $Msg_Status -PercentComplete ([math]::Round((100*$ProgressBar_Current)/$ProgressBar_Summary))
        IF ($scriptDebug -like 0){
        .($Function.FullName)
        }
    }

    #Run Functions Costum
    $Msg_Section = "Section Costum"
    Write-Host $Msg_Section -ForegroundColor Cyan 
    Foreach ($Function in $LoadFunctions_Costum){
        $FunctionName = Split-Path (Split-Path $Function.FullName) -Leaf
        $Msg_Status = " Running... $FunctionName"
        Write-Verbose $Msg_Status 
        $ProgressBar_Current++
        Write-Progress -Activity $scriptName_SYNOPSIS -Status $Msg -PercentComplete ([math]::Round((100*$ProgressBar_Current)/$ProgressBar_Summary))
        IF ($scriptDebug -like 0){
        .($Function.FullName)
        }
    }

	####################################################################
	## Code Section - End
	####################################################################
}

#-----------------------------------------------------------[End]------------------------------------------------------------

End {
    #End Skript
    Write-Verbose "Get PowerShell Ende Date"
    $EndPS = (Get-Date)
	$ElapsedTimePS = (($EndPS-$StartPS).TotalSeconds)
    Write-Log_hp -Path $LogPS -Value "Elapsed Time: $ElapsedTimePS Seconds" -Component $scriptName_PS -Severity 1
}