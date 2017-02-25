####################################################################
$PSM_Name = "PSWrapper - PowerShell Module"
$PSM_Version =  "1.00"
$PSM_Date =  "10.05.2016"
$PSM_Autor =  "Patrik Horn"
$PSM_URL = "http://www.hornpa.de"
$PSM_History ={
Version 1.00 - Release
}
####################################################################
Write-Verbose "PSM Module: $PSM_Name "
Write-Verbose "PSM Version: $PSM_Version "
Write-Verbose "PSM Date: $PSM_Date "
Write-Verbose "PSM Autor: $PSM_Autor "
Write-Verbose "PSM URL: $PSM_URL "
Write-Verbose "PSM History: $PSM_History "
####################################################################
Write-Verbose "Loading Functions..."
# -------------------------------------------------------------------
function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Test-Transcribing {
	$externalHost = $host.gettype().getproperty("ExternalHost",
		[reflection.bindingflags]"NonPublic,Instance").getvalue($host, @())

	try {
	    $externalHost.gettype().getproperty("IsTranscribing",
		[reflection.bindingflags]"NonPublic,Instance").getvalue($externalHost, @())
	} catch {
             write-warning "This host does not support transcription."
         }
}
# -------------------------------------------------------------------
Write-Verbose "Finished"