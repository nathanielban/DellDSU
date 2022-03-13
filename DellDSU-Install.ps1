<#	
	.NOTES
	===========================================================================
	 Created on:   	03/13/21
	 Created by:   	Nathaniel Bannister
	 Organization: 	Command N
	 Filename:     	DellDSU-Install.ps1
	===========================================================================
	.DESCRIPTION
		Dell EMC System Update - Install Script. Installs the current version of Dell EMC System Update from the web. 
#>

#Force TLS 1.2 on older systems
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Parameters
$localWorkingDir = "C:\Temp\"
$installerPath = $localWorkingDir + $FileName
#WebRequest Parameters
$DownloadURL = "https://dl.dell.com/FOLDER08033837M/1/Systems-Management_Application_D0JW4_WN64_1.9.3.0_A00.EXE"
$FileName = "Systems-Management_Application_D0JW4_WN64_1.9.3.0_A00.EXE"
#Because of Dell's CDN we now have to provide a user agent or requests will get denied with a 403.
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36";

#Pull information about DSU install from registry:
$software = "DELL EMC System Update";
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $software })
$installedVersion = $installed.DisplayVersion

#Create working directory if it doesn't exist:
Write-Host "Creating Working Directory if it doesn't exist already ($localWorkingDir):"
if(!(Test-Path C:\Deploy)){New-Item -Path "c:\" -Name "Deploy" -ItemType "directory"}

#Install DSU if it's not installed, upgrade it if it is:
If(-Not $installed) {
	Write-Host $software" is NOT installed."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $installerPath -UserAgent $UserAgent
    Write-Host "Installing Dell EMC System Update"
    Start-Process $installerPath  -ArgumentList "/S" -Wait

} else {
	Write-Host "$software $installedVersion is installed."
    If($installedVersion -lt $currentVersion){
        Write-Host "Current Version is not installed - Updating."
        Invoke-WebRequest -Uri $DownloadURL -OutFile $installerPath -UserAgent $UserAgent
        Write-Host "Installing Dell EMC System Update..."
        Start-Process $installerPath  -ArgumentList "/S" -Wait
        Write-Host "Update Complete."
    }
}
Write-Host "Current version of $software is installed."