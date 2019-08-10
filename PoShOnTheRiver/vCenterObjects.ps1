# .NET Object
Get-VM -Name tmpwin01

# .NET Object
Get-VM -Name tmpwin01 | Format-List

# vSphere Object
Get-VM -Name tmpwin01 | Select-Object -ExpandProperty ExtensionData
Get-View -ViewType VirtualMachine -Filter @{Name='tmpwin01'}

# Performance Comparisons
Measure-Command {Get-VM -Name tmpwin01} | Select-Object -Property TotalSeconds
Measure-Command {Get-View -ViewType VirtualMachine -Filter @{Name='tmpwin01'}} | Select-Object -Property TotalSeconds

# Performance Comparisons - Property Isolation
Measure-Command {Get-VM -Name tmpwin01 | Select-Object -Property Name} | Select-Object -Property TotalSeconds
Measure-Command {Get-View -ViewType VirtualMachine -Filter @{Name='tmpwin01'} -Property Name | Select-Object -Property Name} | Select-Object -Property TotalSeconds

# Performance Comparisons - At Scale
Measure-Command {Get-VM} | Select-Object -Property TotalSeconds
Measure-Command {Get-View -ViewType VirtualMachine} | Select-Object -Property TotalSeconds

# Performance Comparisons - Property Isolation
Measure-Command {Get-VM | Select-Object -Property Name} | Select-Object -Property TotalSeconds
Measure-Command {Get-View -ViewType VirtualMachine -Property Name | Select-Object -Property Name} | Select-Object -Property TotalSeconds
