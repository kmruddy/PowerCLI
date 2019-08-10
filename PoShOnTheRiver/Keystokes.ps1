# Import Set-VMKeystrokes Function - https://github.com/lamw/vghetto-scripts/blob/master/powershell/VMKeystrokes.ps1
. .\Set-VMKeystrokes.ps1

# Set VM variable
$tmpcos = Get-VM -Name tmpcos01
$tmpcos | Select-Object -Property Name,@{Name="NetAdapterConnection";Expression={(Get-NetworkAdapter -VM $_).ConnectionState.Connected}},@{Name="ToolsStatus";Expression={$_.ExtensionData.Guest.ToolsStatus}}

# Login to VM
Set-VMKeystrokes -VMName $tmpcos -StringInput "user" -ReturnCarriage $true
Set-VMKeystrokes -VMName $tmpcos -StringInput "VMware1!" -ReturnCarriage $true

# Show Mounts
Set-VMKeystrokes -VMName $tmpcos -StringInput "df -h" -ReturnCarriage $true

# Show IP Config
Set-VMKeystrokes -VMName $tmpcos -StringInput "ip link show" -ReturnCarriage $true
