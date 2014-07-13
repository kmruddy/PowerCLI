<#
Script name:   Cluster_RecreateOrphans.ps1
Created on:    7/07/2014
Author:        Kyle Ruddy
Purpose:       Removing and re-creating orphaned VMs
History:       
#>

#Cluster Operations
Get-Cluster | sort Name | Select Name
Write-Host ""
$InputCluster = Read-Host "Cluster Name"
$cluster = Get-Cluster $InputCluster
$randvmhost = $cluster | Get-VMHost | where {$_.ConnectionState -eq 'Connected'} | Get-Random

#Gather orphaned VMs 
$orphanlist = $cluster | Get-VM | where {$_.ExtensionData.Summary.OverallStatus -eq 'gray'} | select -First 1

#Loop through orphaned VMs
foreach ($orphan in $orphanlist) {
#Null variables within the loop
$vmx = $PlacedVM = $RP = $BlueFolder = $null

#Gather existing VM information prior to removal
$vmx = ($orphan.Extensiondata.LayoutEx.File | where {$_.Name -like '*.vmx'}).Name
$RP = Get-ResourcePool -Id $orphan.ExtensionData.ResourcePool
$BlueFolder = Get-Folder -Id $orphan.ExtensionData.Parent

if ($vmx -ne $null) {
#Remove orphaned VM
$orphan | Remove-VM -Confirm:$false | Out-Null
Start-Sleep -Seconds 5

#Add VM back
New-VM -VMHost $randvmhost -VMFilePath $vmx
$PlacedVM = $cluster | Get-VM $orphan.Name
if ($RP.Name -ne "Resources") {$PlacedVM | Move-VM -Location $RP -Confirm:$false | Out-Null}
if ($BlueFolder.Name -ne "vm") {$PlacedVM | Move-VM -Location $BlueFolder -Confirm:$false | Out-Null}
$PlacedVM | Start-VM -Confirm:$false | Out-Null
} 
else {Write-Host $orphan.Name"- No vmx file found. Skipped"}
}
