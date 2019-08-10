# Connect to vCenter Server
Connect-VIServer -Server tpa-vcsa-01.cpbu.lab

# Show VM Count
Get-VM | Measure-Object | Select-Object -Property Count

# Retreive Snapshot
Get-Snapshot -VM kr-tpa-01

# Retreive Snapshot details
Get-Snapshot -VM kr-tpa-01 | Format-Table -Property VM,Name,Created,SizeGB

# Retreive All Snapshots
Get-VM | Get-Snapshot

# Testing Performance
Measure-Command -Expression {Get-VM | Get-Snapshot}
Measure-Command -Expression {Get-Snapshot -VM (Get-VM)}

# Quick Snapshot Report 
Get-Snapshot -VM (Get-VM) | Format-Table -Property VM,Name,Created,SizeGB

# Quick Snapshot Report Over 10GB
Get-Snapshot -VM (Get-VM) | Where-Object {$_.SizeGB -gt 10} | Format-Table -Property VM,Name,Created,SizeGB

# Clean Up Snapshot Report
Get-Snapshot -VM (Get-VM) | Where-Object {$_.SizeGB -gt 10} | Format-Table -Property VM,Name,Created,@{Name='SizeGB';Expression={"{0:n2}" -f $_.SizeGB}}