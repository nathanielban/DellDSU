<#	
	.NOTES
	===========================================================================
	 Created on:   	03/13/21
	 Created by:   	Nathaniel Bannister
	 Organization: 	Command N
	 Filename:     	DellDSU-InstallUpdatesSilently.ps1
	===========================================================================
	.DESCRIPTION
		Dell EMC System Update - Update Install Script. Install all updates currently out of compliance with Dell's baseline.
#>

#Pull information about DSU install from registry:
$software = "DELL EMC System Update";
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $software })
$installedVersion = $installed.DisplayVersion
$DSUPath = $installed.InstallLocation
#Configure automatic restarts after patching:
[datetime]$RestartTime = $RestartTime
[datetime]$CurrentTime = Get-Date
[int]$WaitSeconds = ( $RestartTime - $CurrentTime ).TotalSeconds

#Some thoughts on future improvements:
#dsu --component-type=<component type values 
#FRMW (Firmware)
#BIOS (BIOS)
#APAC (Application)
#APP (Application)
#DRVR (Drivers)
#I.E. --component-type=BIOS

if (!(Test-Path "$DSUPath\DSU.exe") -or ($null -ne $installed)) {
    Write-Host "DSU NOT FOUND"
    Break
} else {
    Write-Host "$software $installedVersion is installed."

    $WorkingDirectory = "C:\Temp\"
    $logFile = "DSU-Update-Log.log"
    $logFilePath = $WorkingDirectory + $logFile

    #https://www.dell.com/support/manuals/en-us/system-update/dsu_1.9/non-interactive-update?guid=guid-bb85da2f-f030-4452-a8e9-77f04ae1fea5&lang=en-us
    Start-Process 'C:\Program Files\Dell\DELL EMC System Update\DSU.exe' -ArgumentList "--non-interactive --apply-upgrades --output-log-file=$logFilePath --log-level=4" -Wait

    Write-Host "Updates installed successfully, please reboot ASAP or system will restart automatically at: " $RestartTime "or in approximately " $WaitSeconds " seconds!"
    shutdown -r -t $WaitSeconds
}