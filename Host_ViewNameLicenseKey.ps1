$SIview = Get-View ServiceInstance
$LMView = Get-View $SIview.Content.LicenseManager
$LAMView = Get-View $LMView.LicenseAssignmentManager
$output = @()
$vmhosts = Get-VMHost
 
Foreach ($vmh in $vmhosts) {
$output += $LAMView.QueryAssignedLicenses($vmh.ExtensionData.Config.Host.Value) 
}

$output | select @{Name='Host Name';Expression={$_.EntityDisplayName}},@{Name='License';Expression={$_.AssignedLicense.LicenseKey}}
