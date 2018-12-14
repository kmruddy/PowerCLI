function Get-CISTag {
<#  
.SYNOPSIS  
    Gathers tag information from the CIS REST API endpoint
.DESCRIPTION 
    Will provide a list of tags
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag name which should be retreived
.PARAMETER Category
    Tag category name which should be retreived
.PARAMETER Id
    Tag ID which should be retreived 
.EXAMPLE
	Get-CISTag
    Retreives all tag information 
.EXAMPLE
	Get-CISTag -Name tagName
    Retreives the tag information based on the specified name

#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')] 
	param(
	[Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true)]
    [String]$Category,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [String]$Id
  	)

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
        if ($PSBoundParameters.ContainsKey("Id")) {
            $tagOutput = $tagSvc.get($Id)
        } else {
            $tagArray = @()
            $tagIdList = $tagSvc.list() | Select-Object -ExpandProperty Value
            foreach ($t in $tagIdList) {
                $tagArray += $tagSvc.get($t)
            }
            if ($PSBoundParameters.ContainsKey("Name")) {
                $tagOutput = $tagArray | Where {$_.Name -eq $Name}
            } elseif ($PSBoundParameters.ContainsKey("Category")) { 
                $tagCatid = Get-CISTagCategory -Name $Category | Select-Object -ExpandProperty Id
                $tagIdList = $tagSvc.list_tags_for_category($tagCatid)
                $tagArray2 = @()
                foreach ($t in $tagIdList) {
                    $tagArray2 += $tagSvc.get($t)
                }
                $tagOutput = $tagArray2
            } else {
                $tagOutput = $tagArray
            }
        }
        $tagOutput | Select-Object Id, Name, Description
    }

}

function New-CISTag {
<#  
.SYNOPSIS  
    Creates a new tag from the CIS REST API endpoint
.DESCRIPTION 
    Will create a new tag
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag name which should be created
.PARAMETER CategoryID
    Category ID where the new tag should be associated
.PARAMETER Description
    Description for the new tag
.EXAMPLE
    New-CISTag -Name tagName -CategoryID categoryIDstring -Description "Tag Descrition"
    Creates a new tag based on the specified name

#>
[CmdletBinding(SupportsShouldProcess = $True)] 
    param(
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
    [String]$CategoryID,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [String]$Description
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
        $tagCreateHelper = $tagSvc.Help.create.create_spec.Create()
        $tagCreateHelper.name = $Name
        $tagCreateHelper.category_id = $CategoryID
        $tagCreateHelper.description = $Description
        $tagNewId = $tagSvc.create($tagCreateHelper)
        Get-CISTag -Id $tagNewId
    }

}

function Get-CISTagCategory {
<#  
.SYNOPSIS  
    Gathers tag category information from the CIS REST API endpoint
.DESCRIPTION 
    Will provide a list of tag categories
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag category name which should be retreived 
.PARAMETER Id
    Tag category ID which should be retreived
.EXAMPLE
    Get-CISTagCategory
    Retreives all tag category information 
.EXAMPLE
    Get-CISTagCategory -Name tagCategoryName
    Retreives the tag category information based on the specified name

#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')] 
    param(
    [Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [String]$Id
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagCatSvc = Get-CisService -Name com.vmware.cis.tagging.category
        if ($PSBoundParameters.ContainsKey("Id")) {
            $tagCatOutput = $tagCatSvc.get($Id)
        } else {
            $tagCatArray = @()
            $tagCatIdList = $tagCatSvc.list() | Select-Object -ExpandProperty Value
            foreach ($tc in $tagCatIdList) {
                $tagCatArray += $tagCatSvc.get($tc)
            }
            if ($PSBoundParameters.ContainsKey("Name")) {
                $tagCatOutput = $tagCatArray | Where {$_.Name -eq $Name}
            } else {
                $tagCatOutput = $tagCatArray
            }
        }
        $tagCatOutput | Select-Object Id, Name, Description, Cardinality
    }

}

function New-CISTagCategory {
<#  
.SYNOPSIS  
    Creates a new tag category from the CIS REST API endpoint
.DESCRIPTION 
    Will create a new tag category
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag category name which should be created 
.PARAMETER Description
    Tag category ID which should be retreived
.PARAMETER Cardinality
    Tag category ID which should be retreived
.PARAMETER AssociableTypes
    Tag category ID which should be retreived    
.EXAMPLE
    New-CISTagCategory -Name NewTagCategoryName -Description "New Tag Category Description" -Cardinality "Single" -AssociableTypes "VM"
    Retreives all tag information 
#>
[CmdletBinding(SupportsShouldProcess = $True)] 
    param(
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
    [String]$Description,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [ValidateSet("Single","Multiple")]
    [String]$Cardinality = "Single",
    [Parameter(Mandatory=$false,Position=3,ValueFromPipelineByPropertyName=$true)]
    [ValidateSet("All", "Cluster", "Datacenter", "Datastore", "DatastoreCluster", "DistributedPortGroup", "DistributedSwitch", "Folder", "ResourcePool", "VApp", "VirtualPortGroup", "VirtualMachine", "VM", "VMHost")]
    [String]$AssociableTypes = "All"
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagCatSvc = Get-CisService -Name com.vmware.cis.tagging.category
        $tagCatCreateHelper = $tagCatSvc.Help.create.create_spec.Create()
        $tagCatCreateHelper.Name = $Name
        $tagCatCreateHelper.Description = $Description
        $tagCatCreateHelper.Cardinality = $Cardinality
        $tagCatCreateHelper.AssociableTypes = $AssociableTypes
        $tagCatNewId = $tagCatSvc.create($tagCatCreateHelper)
        Get-CISTagCategory -Id $tagCatNewId
    }

}

function Get-CISTagAssignment {
<#  
.SYNOPSIS  
    Displays a list of the tag assignments from the CIS REST API endpoint
.DESCRIPTION 
    Will provide a list of the tag assignments
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER CategoryId
    Tag category ID which should be referenced
.PARAMETER ObjectId
    Object ID which should be retreived
.PARAMETER ObjectType
    Object Type which should be retreived
.EXAMPLE
    Get-CISTagAssignment 
    Retreives all tag assignment information
.EXAMPLE
    Get-CISTagAssignment -ObjectId 'vm-11' -ObjectType 'VirtualMachine'
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')] 
    param(
    [Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$CategoryId,
    [Parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true)]
    [String]$ObjectId,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [ValidateSet("Cluster", "Datacenter", "Datastore", "DatastoreCluster", "DistributedPortGroup", "DistributedSwitch", "Folder", "ResourcePool", "VApp", "VirtualPortGroup", "VirtualMachine", "VM", "VMHost")]
    [String]$ObjectType
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagOutput = @()
        $tagAssocSvc = Get-CisService -Name com.vmware.cis.tagging.tag_association
        if ($PSBoundParameters.ContainsKey("CategoryId")) {
            $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
            $tagIdOutput = $tagSvc.list_tags_for_category($CategoryId)          
        } elseif ($PSBoundParameters.ContainsKey("ObjectId") -and $PSBoundParameters.ContainsKey("ObjectType")) {
            $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
            $objObject.id = $ObjectId
            $objObject.type = $ObjectType
            $tagIdOutput = $tagAssocSvc.list_attached_tags($objObject)
        } else {
            $tagCategories = Get-CISTagCategory | Sort-Object -Property Name
            $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
            $tagIdOutput = @()
            foreach ($tagCat in $tagCategories) {
                $tagIdOutput += $tagSvc.list_tags_for_category($tagCat.id)
            }
        }
        $tagReference = Get-CISTag

        if ($ObjectId -and $ObjectType) {
            foreach ($tagId in $tagIdOutput) {
                $tagAttObj = @()
                $tagAttObj += $tagAssocSvc.list_attached_objects($tagId) | where {$_.type -eq $ObjectType -and $_.id -eq $ObjectId}
                foreach ($obj in $tagAttObj) {
                    if ($obj.type -eq "VirtualMachine" -or $obj.type -eq 'VM') {
                        $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                        $objName = $vmSvc.get($obj.Id) | Select-Object -ExpandProperty Name
                    }
                    else {$objName = 'Object Not Found'}                
                    $tempObject = "" | Select-Object Tag, Entity
                    $tempObject.Tag = $tagReference | where {$_.id -eq $tagId} | Select-Object -ExpandProperty Name
                    $tempObject.Entity = $objName
                    $tagOutput += $tempObject
                }
            }
        } else {
            foreach ($tagId in $tagIdOutput) {
                $tagAttObj = @()
                $tagAttObj += $tagAssocSvc.list_attached_objects($tagId)
                foreach ($obj in $tagAttObj) {
                    if ($obj.type -eq "VirtualMachine" -or $obj.type -eq 'VM') {
                        $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                        $objName = $vmSvc.get($obj.Id) | Select-Object -ExpandProperty Name
                    }
                    else {$objName = 'Object Not Found'}                
                    $tempObject = "" | Select-Object Tag, Entity
                    $tempObject.Tag = $tagReference | where {$_.id -eq $tagId} | Select-Object -ExpandProperty Name
                    $tempObject.Entity = ""
                    $tagOutput += $tempObject
                }
            }
        }
        return $tagOutput
    }
}

function New-CISTagAssignment {
<#  
.SYNOPSIS  
    Displays a list of the tag assignments from the CIS REST API endpoint
.DESCRIPTION 
    Will provide a list of the tag assignments
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER CategoryId
    Tag category ID which should be referenced
.PARAMETER ObjectId
    Object ID which should be retreived
.PARAMETER ObjectType
    Object Type which should be retreived
.EXAMPLE
    Get-CISTagAssignment 
    Retreives all tag assignment information
.EXAMPLE
    Get-CISTagAssignment -ObjectId 'vm-11' -ObjectType 'VirtualMachine'
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')] 
    param(
    [Parameter(Mandatory=$True,Position=0,ValueFromPipelineByPropertyName=$true)]
    $TagId,
    [Parameter(Mandatory=$True,Position=1,ValueFromPipelineByPropertyName=$true)]
    $ObjectId,
    [Parameter(Mandatory=$True,Position=2,ValueFromPipelineByPropertyName=$true)]
    [ValidateSet("Cluster", "Datacenter", "Datastore", "DatastoreCluster", "DistributedPortGroup", "DistributedSwitch", "Folder", "ResourcePool", "VApp", "VirtualPortGroup", "VirtualMachine", "VM", "VMHost")]
    [String]$ObjectType
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagAssocSvc = Get-CisService -Name com.vmware.cis.tagging.tag_association
        if ($TagId -is [array] -and $ObjectId -isnot [array]) {
            $objObject = $tagAssocSvc.help.attach_multiple_tags_to_object.object_id.create()
            $objObject.id = $ObjectId
            $objObject.type = $ObjectType
            $tagIdList = $tagAssocSvc.help.attach_multiple_tags_to_object.tag_ids.create()
            foreach ($tId in $TagId) {
                $tagIdList.add($tId) | Out-Null
            }
            $tagAssocSvc.attach_multiple_tags_to_object($objObject,$tagIdList) | Out-Null
        } elseif ($TagId -isnot [array] -and $ObjectId -is [array]) {
            $objList = $tagAssocSvc.help.attach_tag_to_multiple_objects.object_ids.create()
            foreach ($obj in $ObjectId) {
                $objObject = $tagAssocSvc.help.attach_tag_to_multiple_objects.object_ids.element.create()
                $objObject.id = $obj
                $objObject.type = $ObjectType
                $objList.add($objObject) | Out-Null
            }
            $tagAssocSvc.attach_tag_to_multiple_objects($TagId,$objList) | Out-Null
        } elseif ($TagId -isnot [array] -and $ObjectId -isnot [array]) {
            $objObject = $tagAssocSvc.help.attach.object_id.create()
            $objObject.id = $ObjectId
            $objObject.type = $ObjectType
            $tagAssocSvc.attach($TagId,$objObject) | Out-Null
        } else {Write-Output "Multiple tags with multiple objects are not a supported call."}

    }
}