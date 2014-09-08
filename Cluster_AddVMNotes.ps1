<#
Script name:   Cluster_AddVMNotes.ps1
Created on:    9/07/2014
Author:        Kyle Ruddy
Purpose:       Adding notes to VMs by specific cluster.
History:       
#>

#Cluster Operations
Get-Cluster | sort Name | Select Name
Write-Host ""
$InputCluster = Read-Host "Cluster Name"
$cluster = Get-Cluster $InputCluster

#Collecting VMs that do not already contain notes
$nonotevms = $cluster | Get-VM | where {$_.Notes -eq ""} | sort Name 

#Loop through VMs with no notes to add notes
foreach ($vm in $nonotevms) {

#Collect the desired note
$tempnotes = Read-Host "$vm`tWhat should the notes read?"

#Set note on the VM
if ($tempnotes -ne '') {$vm | Set-VM -Notes $tempnotes -Confirm:$false | Out-Null}
}
