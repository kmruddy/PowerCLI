# Establish VM Variable and Show Network Connectivity
$Guest = Get-VM -Name "tmpwin01"
$Guest | Select-Object -Property Name,@{Name="NetAdapterConnection";Expression={(Get-NetworkAdapter -VM $_).ConnectionState.Connected}},@{Name="ToolsStatus";Expression={$_.ExtensionData.Guest.ToolsStatus}}


# Pull disk information from VM's guest OS
Invoke-VMScript -vm $Guest -ScriptText "Get-PSDrive -Name C" -ScriptType PowerShell

# Configure Reusable Variables
$Disk = "Hard Disk 1"
$Volume = "C"
$DiskSize = 100

# Update VM Object's Hard Disk
$objDisk = Get-HardDisk -VM $Guest -Name $disk
$objDisk | Set-HardDisk -CapacityGB $DiskSize -Confirm:$false

# Create a scriptblock to invoke DiskPart via Batch
$scriptBlock = @"
echo rescan > c:\diskpart.txt
echo select vol $Volume >> c:\diskpart.txt
echo extend >> c:\diskpart.txt
diskpart.exe /s c:\diskpart.txt
"@

# Invoke diskpart on the VM's guest OS
Invoke-VMScript -vm $Guest -ScriptText $scriptBlock -ScriptType BAT

# Pull disk information from VM's guest OS
Invoke-VMScript -VM 'WinApplications01' -ScriptText "Get-PSDrive -Name C" -ScriptType Powershell