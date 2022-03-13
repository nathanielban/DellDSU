<#	
	.NOTES
	===========================================================================
	 Created on:   	03/13/21
	 Created by:   	Nathaniel Bannister
	 Organization: 	Command N
	 Filename:     	DellDSU-CheckCompliance.ps1
	===========================================================================
	.DESCRIPTION
		Dell EMC Command Update - Update Compliance Check Script. Compares system to Dell's current baseline and returns counts of missing update types for external use.
#>

#Pull information about DSU install from registry:
$software = "DELL EMC System Update";
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $software })
$installedVersion = $installed.DisplayVersion
$DSUPath = $installed.InstallLocation
#Set working directory and name of compliance report JSON:
$WorkingDirectory = "C:\Temp\"
$complianceJSON = "compliance.json"
$complianceJSONPath = $WorkingDirectory + $complianceJSON
#Set maximum age of cached compliance inventory file:
$maximumInventoryAge = (Get-Date).AddMinutes(-30) #30m ago

if (!(Test-Path "$DSUPath\DSU.exe") -or ($null -ne $installed)) {
    Write-Host "DSU NOT FOUND"
    Break
} else {
       
    Write-Host "$software $installedVersion is installed."

    if(!(Test-Path $complianceJSONPath) -or ((Get-Item $complianceJSONPath).CreationTime -lt $maximumInventoryAge)){
        Write-Host "Inventory file is missing or stale, generating fresh report..."
        if((Test-Path $complianceJSONPath)){
            #Remove stale compliance file if it exists.
            Remove-Item $complianceJSONPath -Force
        }
        Start-Process "$DSUPath\DSU.exe" -ArgumentList "--compliance --output=$complianceJSONPath --output-format=JSON" -Wait
        $creationTime = (Get-item $complianceJSONPath).creationtime
        $filesize = [math]::Round((Get-Item $complianceJSONPath).length/1KB)
        Write-Host "New inventory file generated, proceeding... `n"
        Write-Host "Inventory File:" $complianceJSONPath
        Write-Host $filesize "KB file generated @" ($creationTime) "`n"
    } else{
        
        $creationTime = (Get-item $complianceJSONPath).creationtime
        $filesize = [math]::Round((Get-Item $complianceJSONPath).length/1KB)
        Write-Host "Recent inventory file found, proceeding with cached file... `n"
        Write-Host "Inventory File:" $complianceJSONPath
        Write-Host $filesize "KB file generated @" ($creationTime) "`n"
 
    }
      
    $compliance = Get-Content $complianceJSONPath | ConvertFrom-Json
    $updateableComponents =  $compliance.SystemUpdateCompliance.UpdateableComponent
}

$complianceStatus = $compliance.SystemUpdateCompliance.BaseLineInformation.ComplianceStatus
$complianceExitStatusMessage = $compliance.SystemUpdateCompliance.InvokerInfo.StatusMessage
$complianceExitStatusCode = $compliance.SystemUpdateCompliance.InvokerInfo.ExitStatus

Write-Host "Compliance report result:" $complianceExitStatusMessage "Exit Code: " $complianceExitStatusCode
if ($complianceStatus -eq $true) {
    Write-Host "System is currently compliant with baseline."
} else {
    Write-Host "System is *NOT* currently compliant with baseline."
}

#All Updates
$Updates = ($updateableComponents | Where-Object { $_.complianceStatus -eq $False })
$UpdatesCount = $Updates.name.count
Write-Host "Updates: " $UpdatesCount
#Urgent Updates
$UrgentUpdates = ($updateableComponents | Where-Object { $_.criticality -eq "Urgent" -and $_.complianceStatus -eq $False })
$UrgentUpdatesCount = $UrgentUpdates.name.count
Write-Host "Critical Updates: " $UrgentUpdatesCount
#App Updates
$AppUpdates = ($updateableComponents | Where-Object { $_.componentTypeDisplay -eq "APPLICATION" -and $_.complianceStatus -eq $False })
$AppUpdatesCount = $AppUpdates.name.count
Write-Host "App Updates" $AppUpdatesCount
#BIOS Updates
$BIOSUpdates = ($updateableComponents | Where-Object { $_.componentTypeDisplay -eq "BIOS" -and $_.complianceStatus -eq $False })
$BIOSUpdatesCount = $BIOSUpdates.name.count
Write-Host "BIOS Updates" $BIOSUpdatesCount
#Driver Updates
$DriverUpdates = ($updateableComponents | Where-Object { $_.componentTypeDisplay -eq "DRIVER" -and $_.complianceStatus -eq $False })
$DriverUpdatesCount = $DriverUpdates.name.count
Write-Host "Driver Updates" $DriverUpdatesCount
#Firmware Updates
$FirmwareUpdates = ($updateableComponents | Where-Object { $_.componentTypeDisplay -eq "FIRMWARE" -and $_.complianceStatus -eq $False })
$FirmwareUpdatesCount = $FirmwareUpdates.name.count
Write-Host "Firmware Updates" $FirmwareUpdatesCount