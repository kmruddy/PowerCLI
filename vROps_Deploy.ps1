<#
Name: vROps_Deploy.ps1

Purpose: This script is used to deploy vROps VMs.
		 This is done by: 
		 Gathering requisite information to deploy the OVA
		 Deploy the OVA
		 Configuring the VM to appropriate size
		 Assigning the proper portgroup
		 Passing network configuration

Execution: ./vROps_Deploy.ps1

Creator: Kyle Ruddy
#>

#Gathering OVA name and location and verifying the content
$name = Read-Host "What should the OVA be named?"
if (!$name) {Write-Host "No name found.`n";Exit}
$ova = Read-Host "Where is the OVA located?"
if ((Get-Item $ova).Name -notlike "*.ova") {Write-Host "No OVA found.`n";Exit}

#Gathering information regarding the size of the OVA being deployed in a menu format
Write-Host "`nAppliance Size."
$amenu = @{}
$a=1
Write-Host "$a. Small (less than 2000 VMs)"
$amenu.Add($a,"Small")
$a++
Write-Host "$a. Medium (between 2000 and 4000 VMs)"
$amenu.Add($a,"Medium")
$a++
Write-Host "$a. Large (greater than 4000 VMs)"
$amenu.Add($a,"Large")
$a++
Write-Host "$a. Standard Remote Collector (less than 4000 VMs)"
$amenu.Add($a,"Standard")
$a++
Write-Host "$a. Large Remote Collector (greater than 4000 VMs)"
$amenu.Add($a,"LargeRC")

[int]$aans = Read-Host 'Enter desired storage format'
if ($aans -eq '0' -or $aans -gt $a) {Write-Host -ForegroundColor Red  -Object "Invalid selection.`n";Exit}
$aselection = $amenu.Item($aans)

#Setting variables in relation to the above response
if ($aselection -eq 'Small') {$cpu=4;$ram=16}
elseif ($aselection -eq 'Medium') {$cpu=8;$ram=32}
elseif ($aselection -eq 'Large') {$cpu=16;$ram=48}
elseif ($aselection -eq 'Standard') {$cpu=2;$ram=4}
elseif ($aselection -eq 'LargeRC') {$cpu=4;$ram=16}

#Gathering information regarding the cluster of the OVA being deployed in a menu format and grabbing the cluster output
$cluster = Get-cluster | sort Name
if (!$cluster) {Write-Host "No cluster found.`n";Exit}
if ($cluster -is [System.Array]) {
Write-Host "`nCluster selection."
$cmenu = @{}
for ($i=1;$i -le $clusters.count; $i++) {
    Write-Host "$i. $($clusters[$i-1].name)"
    $cmenu.Add($i,($clusters[$i-1].name))
    }
[int]$cans = Read-Host 'Enter desired cluster'
if ($cans -eq '0' -or $cans -gt $i) {Write-Host -ForegroundColor Red  -Object "Invalid selection.`n";Exit}
$cluster = get-cluster ($cmenu.Item($cans))
}

#Gathering information regarding the hard disk format of the OVA being deployed in a menu format
Write-Host "`nStorage Format."
$smenu = @{}
$f=1
Write-Host "$f. Thick Provision Lazy Zeroed"
$smenu.Add($f,"Thick")
$f++
Write-Host "$f. Thick Provision Eager Zeroed"
$smenu.Add($f,"EagerZeroedThick")
$f++
Write-Host "$f. Thin Provision"
$smenu.Add($f,"Thin")

[int]$sans = Read-Host 'Enter desired storage format'
if ($sans -eq '0' -or $sans -gt $f) {Write-Host -ForegroundColor Red  -Object "Invalid selection.`n";Exit}
$hdformat = $smenu.Item($sans)

#Gathering IP information and verifying a DNS entry exists
$ip = (Resolve-DnsName -Name $name).IPAddress
if (!$ip) {Write-Host "No IP address found in DNS.`n";Exit}

#Creating variables dependant on above input including VMhost, Resource Pool and Datastore
$vmh = $cluster | Get-VMHost -State Connected | Get-Random
$rp = $cluster | Get-ResourcePool | where {$_.Name -ne 'Resources'} | sort Name
if ($rp -is [System.Array]) {
#Resource pool was determined to be an array. Gathering information regarding the desired resource pool
Write-Host "`nResoure Pool selection."
$rmenu = @{}
for ($i=1;$i -le $rp.count; $i++) {
    Write-Host "$i. $($rp[$i-1].name)"
    $rmenu.Add($i,($rp[$i-1].name))
    }
[int]$rans = Read-Host 'Enter desired resource pool.'
if ($rans -eq '0' -or $rans -gt $i) {Write-Host -ForegroundColor Red  -Object "Invalid selection.`n";Exit}
$rselection = $rmenu.Item($rans)
$rp = $cluster | get-resourcepool $rselection
}

$ds = Get-DatastoreCluster *$cluster* | sort -Descending -Property FreeSpaceGB | select -First 1
if (!$ds) {
	  $clustName = $cluster.Name
      $datastores = Get-Datastore *$clustName* | Where-Object {$_.Name -cnotlike "ISO"} | sort -Descending -Property FreeSpaceMB
	  $ds = $datastores | select -First 1 
	}

#Creating the VM based off the above information
Import-VApp -Name $name -Source $ova -VMHost $vmh -Location $rp -Datastore $ds -DiskStorageFormat $hdformat -Confirm:$false | Out-Null

#Allowing the previous task to finalize
Start-Sleep -Seconds 20

#Gathering variable information on the recently provisioned VM
$vm = $vmh | Get-VM $name

#Setting the approriate sizes on the deployed VM
$vm | Set-VM -MemoryGB $ram -NumCpu $cpu -Confirm:$false | Out-Null

#Gathering information to pass to the VM
$subnet = "255.255.255.0"
$ipsplit = $ip.split('.')
$vlanid = $ipsplit[2]
$gateway = $ipsplit[0] + "." + $ipsplit[1] + "." + $ipsplit[2] + ".254"
$DNS = "x.x.x.x,x.x.x.x"

#Gathering the required portgroup information and assigning the VM to the proper portgroup
$pg = Get-VMHost $vm.VMHost | Get-VDSwitch | Get-VDPortgroup | where {$_.VlanConfiguration.VlanId -eq $vlanid}
$vm | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $pg -Confirm:$false | Out-Null

# Reconfigure the vApp with Name and IP details.
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.changeVersion = $VM.ExtensionData.Config.ChangeVersion
$spec.vAppConfig = New-Object VMware.Vim.VmConfigSpec
$spec.vAppConfig.property = New-Object VMware.Vim.VAppPropertySpec[] (6)
$spec.vAppConfig.ipAssignment = New-Object VMware.Vim.VAppIPAssignmentInfo
$spec.vAppConfig.ipAssignment.ipAllocationPolicy = "fixedPolicy"

$spec.vAppConfig.property[0] = New-Object VMware.Vim.VAppPropertySpec
$spec.vAppConfig.property[0].operation = "edit"
$spec.vAppConfig.property[0].info = New-Object VMware.Vim.VAppPropertyInfo
$spec.vAppConfig.property[0].info.key = 2
$spec.vAppConfig.property[0].info.value = $gateway

$spec.vAppConfig.property[1] = New-Object VMware.Vim.VAppPropertySpec
$spec.vAppConfig.property[1].operation = "edit"
$spec.vAppConfig.property[1].info = New-Object VMware.Vim.VAppPropertyInfo
$spec.vAppConfig.property[1].info.key = 3
$spec.vAppConfig.property[1].info.value = $DNS

$spec.vAppConfig.property[2] = New-Object VMware.Vim.VAppPropertySpec
$spec.vAppConfig.property[2].operation = "edit"
$spec.vAppConfig.property[2].info = New-Object VMware.Vim.VAppPropertyInfo
$spec.vAppConfig.property[2].info.key = 4
$spec.vAppConfig.property[2].info.value = $IP

$spec.vAppConfig.property[3] = New-Object VMware.Vim.VAppPropertySpec
$spec.vAppConfig.property[3].operation = "edit"
$spec.vAppConfig.property[3].info = New-Object VMware.Vim.VAppPropertyInfo
$spec.vAppConfig.property[3].info.key = 5
$spec.vAppConfig.property[3].info.value = $subnet

$Reconfig = $VM.ExtensionData
$Reconfig.ReconfigVM_Task($spec) | Out-Null

Write-Host $name" has been deployed."
