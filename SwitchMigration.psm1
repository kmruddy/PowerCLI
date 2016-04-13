function Move-VMHostToDVS {
<#  
.SYNOPSIS  
    Takes a VMHost's standard vSwitch and creates a distributed vSwitch then migrates all VMs and Uplinks

.DESCRIPTION 
    Migrates a host from an existing standard vSwitch to a distributed vSwitch, including VMs and uplinks

.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com

.PARAMETER vmhost
	The FQDN or IP of your VMHost

.PARAMETER vsswitch
	The name of the standard virtual switch 

.EXAMPLE
	PS> Move-VMHostToDVS -vmhost vmhost01 -vss vSwitch1
#>
[CmdletBinding()] 
	param(
		[Parameter(Mandatory=$true,Position=0)]
		[String]$vmhost,
		[Parameter(Mandatory=$true,Position=1)]
		[String]$vsswitch
  	)

	Process {

	$vmh = Get-VMHost -Name $vmhost
    $vss = $vmh | Get-VirtualSwitch -Name $vsswitch -Standard -ErrorAction SilentlyContinue
    if (!$vmh) {
        Write-Warning "$vmhost - VMHost can't be found.";exit}
    elseif (!$vmh) {Write-Warning "$vmhost - VMHost can't be found.";exit}
    elseif ($vss.nic.count -lt 2) {Write-Warning "$vss - $vmhost has less than 2 uplinks.";exit}
    elseif ((Get-VDSwitch -Name $vsswitch -ErrorAction SilentlyContinue)) {Write-Warning "$vsswitch - a distributed switch of this name already exists.";exit}
    else {

            
            $activenics = $vss.ExtensionData.Spec.Policy.NicTeaming.NicOrder.ActiveNic
            $stbynics = $vss.ExtensionData.Spec.Policy.NicTeaming.NicOrder.StandbyNic

            $dvs = New-VDSwitch -Name $vss.Name -Mtu $vss.Mtu -NumUplinkPorts ($vss.nic.count) -Location ($vmh | Get-Datacenter) -Confirm:$false
            
            Add-VDSwitchVMHost -VMHost $vmh -VDSwitch $dvs -Confirm:$false
            if ($activenics.count -gt 1) {
                Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $dvs -VMHostPhysicalNic (Get-VMHostNetworkAdapter -VMHost $vmh -Physical -Name ($activenics | select -last 1)) -Confirm:$false}
            elseif ($stbynics.count -gt 1) {Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $dvs -VMHostPhysicalNic (Get-VMHostNetworkAdapter -VMHost $vmh -Physical -Name ($stbynics | select -last 1)) -Confirm:$false}
            else {Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $dvs -VMHostPhysicalNic (Get-VMHostNetworkAdapter -VMHost $vmh -Physical -Name ($stbynics)) -Confirm:$false}
            
            $vspgs = $vss | Get-VirtualPortGroup -Standard
            foreach ($pg in $vspgs) {
                $vdpg = $null

                if ($pg.VlanId -eq 4095) {
                    New-VDPortgroup -VDSwitch $dvs -Name $pg.Name -VlanTrunkRange "1-4094" -Confirm:$false | Out-Null}
                else {New-VDPortgroup -VDSwitch $dvs -Name $pg.Name -VlanId $pg.vlanid -Confirm:$false | Out-Null}
                $vdpg = $dvs | Get-VDPortgroup -Name $pg.Name
                $pg | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $vdpg -Confirm:$false | Out-Null

            }
            
            $oldvss = Get-VirtualSwitch -Name $vss.Name -VMHost $vmh -Standard
            $oldactivenics = $oldvss.ExtensionData.Spec.Policy.NicTeaming.NicOrder.ActiveNic
            $oldstbynics = $oldvss.ExtensionData.Spec.Policy.NicTeaming.NicOrder.StandbyNic

            foreach ($avnic in $oldactivenics) {Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $dvs -VMHostPhysicalNic (Get-VMHostNetworkAdapter -VMHost $vmh -Physical -Name $avnic) -Confirm:$false}
            foreach ($svnic in $oldstbynics) {Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $dvs -VMHostPhysicalNic (Get-VMHostNetworkAdapter -VMHost $vmh -Physical -Name $svnic) -Confirm:$false}
                
    }

	} # End of process
} # End of function

function Move-VMHostToVSS {
<#  
.SYNOPSIS  
    Takes a VMHost's distributed vSwitch and creates a standard vSwitch then migrates all VMs and Uplinks

.DESCRIPTION 
    Migrates a host from an existing distributed vSwitch to a standard vSwitch, including VMs and uplinks

.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com

.PARAMETER vmhost
	The FQDN or IP of your VMHost

.PARAMETER dvswitch
	The name of the distributed virtual switch 

.EXAMPLE
	PS> Move-VMHostToVSS -vmhost vmhost01 -dvs vSwitch1
#>
[CmdletBinding()] 
	param(
		[Parameter(Mandatory=$true,Position=0)]
		[String]$vmhost,
		[Parameter(Mandatory=$true,Position=1)]
		[String]$dvswitch
  	)

	Process {

	$vmh = Get-VMHost -Name $vmhost
    $dvs = $vmh | Get-VDSwitch -Name $dvswitch -ErrorAction SilentlyContinue
    if (!$vmh) {
        Write-Warning "$vmhost - VMHost can't be found.";exit}
    elseif (!$vmh) {Write-Warning "$vmhost - VMHost can't be found.";exit}
    elseif ($dvs.NumUplinkPorts -lt 2) {Write-Warning "$vss - $vmhost has less than 2 uplinks.";exit}
    elseif ((Get-VirtualSwitch -Name $dvswitch -Standard -ErrorAction SilentlyContinue)) {Write-Warning "$dvswitch - a standard switch of this name already exists.";exit}
    else {

        $uplinks = $dvs | Get-VMHostNetworkAdapter -VMHost $vmh
        $pgs = Get-VDPortgroup -VDSwitch $dvs.name | ?{$_.IsUplink -eq $false}

        $vss = New-VirtualSwitch -VMHost $vmh -Name $dvs.Name -Mtu $dvs.Mtu
       
        Remove-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter ($uplinks | select -Last 1) -Confirm:$false
        Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic ($uplinks | select -Last 1) -VirtualSwitch $vss -Confirm:$false

        foreach ($pg in $pgs) {
            $vspg = $null

            if ($pg.VlanConfiguration.VlanType -eq "Vlan") {
                $vss | New-VirtualPortGroup -Name $pg.Name -VLanId $pg.VlanConfiguration.VlanId -Confirm:$false | Out-Null}
            elseif ($pg.VlanConfiguration.VlanType -eq "Trunk") {$vss | New-VirtualPortGroup -Name $pg.Name -VLanId 4095 -Confirm:$false | Out-Null}
            else {$vss | New-VirtualPortGroup -Name $pg.Name -Confirm:$false | Out-Null}
            Start-Sleep -Seconds 2
            $vspg = $vss | Get-VirtualPortGroup -Name $pg.Name -Standard
            $pg | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $vspg -Confirm:$false | Out-Null
            
        }

        $olduplinks = $dvs | Get-VMHostNetworkAdapter -VMHost $vmh
        foreach ($uplink in $olduplinks) {
            Remove-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $uplink -Confirm:$false
            Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $uplink -VirtualSwitch $vss -Confirm:$false
        }

    }

	} # End of process
} # End of function
