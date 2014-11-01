<#
Name: Cluster_NICinfo.ps1

Purpose: Go through the selected cluster and gather all the NIC driver and firmware information. 

Execution: Cluster_NICinfo.ps1

Creator: Kyle Ruddy	
Date: 10/30/2014
#>

#Setting global variables
$output = @()

#Output the available clusters to choose from
Get-Cluster | select Name
Write-Host ""

#Ask for the desired cluster to gather VMHost NIC information
$InputCluster = Read-Host "What cluster should the VMs in the CSV be moved to?" 

#Gather available VMHosts
$vmhosts = Get-Cluster $InputCluster -ErrorAction Stop | Get-VMHost | where {$_.State -eq 'Maintenance' -or $_.State -eq 'Connected'} | sort Name

#Loop through each VMHost gathering information
foreach ($vmh in $vmhosts) {
#Null variables which will be reused in the loop
$esxcli = $niclist = $null

#Connect to the vmhost via esxcli and then pull its NICs
$esxcli = $vmh | Get-EsxCli
$niclist = $esxcli.network.nic.list()

#Loop through each NIC gathering information
foreach ($nic in $niclist) {
#Null variables which will be reused in the loop
$tempvar = $driverinfo = $null

#Gather NIC information from the DriverInfo selection
$driverinfo = $esxcli.network.nic.get($nic.Name).DriverInfo

#Feed NIC information into a variable to be displayed later
$tempvar = "" | select VMHost,Nic,Driver,DV,FV
$tempvar.VMHost = ($vmh.Name).Split('.')[0]
$tempvar.Nic = $nic.Name
$tempvar.Driver = $driverinfo.Driver
$tempvar.DV = $driverinfo.Version
$tempvar.FV = $driverinfo.FirmwareVersion

#Add the above variable to variable that's to be the final result
$output += $tempvar
}

}

#Display NIC information from all available VMHosts
$output | select VMHost,NIC,Driver,@{Name='Driver Version';Expression={$_.DV}},@{Name='Firmware Version';Expression={$_.FV}}
