<#
Script name:   vCenter_AddQuickStats.ps1
Created on:    11/07/2015
Author:        Kyle Ruddy
Purpose:       Automated workaround for vCenter 6.0 per http://kb.vmware.com/kb/2061008
History:       
#>

#If statement to check if there is a vCenter connection already established
if (!($global:DefaultVIServer)) {Write-Warning "No vCenter Connection found. Connect to a vCenter and try running the script again."}
else {
#If statement to check whether or not the vpxd.quickStats.HostStatsCheck setting exists. If so, it sets the option to false. If not, it creates the parameter.
if (Get-AdvancedSetting -Entity $global:DefaultVIServer -Name "config.vpxd.quickStats.HostStatsCheck") {Get-AdvancedSetting -Entity $global:DefaultVIServer -Name "config.vpxd.quickStats.HostStatsCheck" | Set-AdvancedSetting -Value $false -Confirm:$false | Out-Null}
else {New-AdvancedSetting -Entity $global:DefaultVIServer -Name "config.vpxd.quickStats.HostStatsCheck" -Value $false -Type VIServer -Confirm:$false | Out-Null}

#If statement to check whether or not the vpxd.quickStats.ConfigIssues setting exists. If so, it sets the option to false. If not, it creates the parameter.
if (Get-AdvancedSetting -Entity $global:DefaultVIServer -Name "config.vpxd.quickStats.ConfigIssues") {Get-AdvancedSetting -Entity $global:DefaultVIServer -Name "config.vpxd.quickStats.ConfigIssues" | Set-AdvancedSetting -Value $false -Confirm:$false | Out-Null}
else {New-AdvancedSetting -Entity $global:DefaultVIServer -Name "config.vpxd.quickStats.ConfigIssues" -Value $false -Type VIServer -Confirm:$false | Out-Null}

#Output to let the user know it's time to restart the vCenter services.
Write-Host "Quick Stat parameter options have been set. Please restart vCenter services in order for them to take effect."
}
