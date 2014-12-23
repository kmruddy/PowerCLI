<#
Name: View_PoolAlerts.ps1

Purpose: This is go through the pools and provide a bit more of an intelligent report on pool status 
         and available desktops per pool then email out the results if the healthchecks fail.

Required: While logged into a View Connection Server with PowerCLI installed

Execution: View_PoolAlerts.ps1

Creator: Kyle Ruddy	
Date: 12/20/2014
#>

#Add in required snapins 
if (!(Get-PSSnapin -Name 'VMware.View*' -ErrorAction silentlycontinue)) {Add-PSSnapin VMware.View*}

#Setting global variables
$Output = @()
$ReadyDesktops = @()
$emailbit = $false
$desktopthreshold = 0.90

#Setting Email Variables
$mailrelay = 'mailrelay.domain.local'
$subject = 'View Pool Alert'
$from = 'Connection Server <connectionserver@domain.local>'
$to = 'View Admins <viewadmins@domain.com>'
$cc = 'Other Admins <otheradmins@domain.com>'

#LDAP - Setting path, connecting, searching path and grabbing all the LDAP Information
$LDAPpath = 'LDAP://localhost:389/OU=Servers,DC=vdi,DC=vmware,DC=int'
$LDAPconnect = New-Object DirectoryServices.DirectoryEntry $LDAPpath
$Searching = New-Object DirectoryServices.DirectorySearcher
$Searching.SearchRoot = $LDAPconnect
$ViewDesks = $Searching.FindAll() 

#Colleting and exporting pertitant information on desktops within the environment
$ViewDesks | %{
$tempvar = "" | select Name,DirtyBit
$tempvar.Name = $_.Properties."pae`-displayname" | select -First 1
if ($_.Properties."pae`-dirtyfornewsessions" -eq $null) {$tempvar.DirtyBit = "0"}
else {$tempvar.DirtyBit = $_.Properties."pae`-dirtyfornewsessions" | select -First 1}
$ReadyDesktops += $tempvar
}

#Collect Pool Information
$Pools = Get-Pool | sort pool_id | where {$_.enabled -eq $true} #| select -First 1

#Loop through each pool, collecting desktop information
foreach ($pool in $Pools) {
$tempout = "" | select Pool,PoolState,ProvisionState,Available,Headroom,TotalDesktops
$counter = 0
$PoolSessions = $PoolDesktops = $NoSession = @()

#Gathering Desktops and Connected sessions for the specified pool
Get-DesktopVM -Pool_id $pool.pool_id -ErrorAction SilentlyContinue | %{$PoolDesktops += $_.HostName}
Get-RemoteSession -Pool_id $pool.pool_id -ErrorAction SilentlyContinue | %{$PoolSessions += $_.DNSName}

#Doing a diff to remove all desktops without an active session
Compare-Object $PoolDesktops ($PoolSessions | sort) | %{$NoSession += $_.InputObject}

#Performing a loop through the desktops to ensure the 'dirty for nwe sessions' bit hasn't been turned on
foreach ($desk in $NoSession) {

#Finding desktops that are 'dirty for new sessions' as declared by LDAP
$tempdesk = $ReadyDesktops | where {$_.Name -eq ($desk.Split(".")[0]) -and $_.DirtyBit -eq '0'}

#Populating the actual available desktops
if ($tempdesk -ne $null) {$counter += 1}

}

#Adding pool based information to a variable which will be combined with other pools
$tempout.Pool = $pool.pool_id
$tempout.PoolState = $pool.enabled
$tempout.ProvisionState = $pool.provisionEnabled
$tempout.Available = [string]$counter
$tempout.Headroom = [string]$pool.headroomCount
$tempout.TotalDesktops = [string](($pool.machineDNs).Split(';')).Count

#Validating against the pool level health checks and making modifications to the output if required
if ($pool.enabled -ne $true) {$emailbit = $true; $tempout.PoolState = '**' + $pool.enabled + '**'}
if ($pool.provisionEnabled -ne $true) {$emailbit = $true; $tempout.ProvisionState = '**' + $pool.provisionEnabled + '**'}
if ($counter -lt ([int]($pool.headroomCount) * $desktopthreshold)) {$emailbit = $true; $tempout.Headroom = '**' + [string]$pool.headroomCount + '**'}

#Sending the gathered data into a global variable
$Output += $tempout

}

#Detecting if the email bit was flipped, indicating an alert is to be sent.
if ($emailbit -eq $true) {
#Output the information about all the pools
$body = "Please be aware, there may be an issue in the View environment that needs to be investigated.`r`r"
$body += $Output | ft -autosize | out-string

#Send email to concerned parties
Send-MailMessage -Body ($body) -From $from -SmtpServer $mailrelay -Subject $subject -To $to -cc $cc
}
