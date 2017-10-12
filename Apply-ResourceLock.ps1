<#
    .SYNOPSIS
    This script will apply locks to all resources in the passed resource groups

    .DESCRIPTION
    This script will grab all resources in the passed resource groups and apply locks to these resources.
    Please ensure this is run with a user account that has Owner permissions.
        
    .PARAMETER subscriptionID
    Target Azure subscription ID

    .PARAMETER targetResourceGroup 
    Array of Azure resource groups

    .PARAMETER lockType
    allowed values include CanNotDelete and ReadOnly    
#>

param(
  [Parameter(Mandatory = $True)]
  [string]$subscriptionId,
  [Parameter(Mandatory = $True)]
  [string[]]$targetResourceGroups,
  [Parameter(Mandatory = $True)]
  [ValidateSet("CanNotdelete","ReadOnly")]
  [string]$lockType
)

$resourceGroupObjects = @()

##########################
## Connect to Azure
##########################
Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId $subscriptionId


##########################
## Fucnctions
##########################
function Get-Resources($resourceGroup){
  Find-AzureRmResource -ResourceGroupNameEquals $resourceGroup.ResourceGroupName
}

function Get-ResourceGroup($resourceGroup){
  $resourceGroupObject = Get-AzureRmResourceGroup -Name $resourceGroup 

  if(!($resourceGroupObject)){
    Write-Host "Resource Group not found:$($resourceGroup)"
  }

  return $resourceGroupObject
}

function Apply-Lock($resources){
  foreach($resource in $resources){
    New-AzureRmResourceLock -LockLevel $lockType -LockName "$($lockType)$($resource.name)" `
                            -ResourceName $resource.name `
                            -ResourceType $resource.Resourcetype `
                            -ResourceGroupName $resource.ResourceGroupName `
                            -Force `
  }
}


##########################
## Main
##########################

foreach($resourceGroup in $targetResourceGroups){
  $resourceGroupObjects += Get-ResourceGroup -resourceGroup $resourceGroup
}


foreach($resourceGroupObj in $resourceGroupObjects){
  $resources = Get-Resources -resourceGroup $resourceGroupObj

  if(!($resources)){
    Write-Host "Resource Group $($resourceGroupObj.ResourceGroupName) is empty"
  }
  else{
    foreach($resource in $resources){
      Write-Output "Resource name: $($resource.Name)"
      Write-Output "Resource type: $($resource.ResourceType)`n"
    }

    do{
      $input = Read-Host -Prompt "would you like to apply a $($lockType) lock all resource above? [Y]Yes, [any key]No"
    }
    until($input)
  }
  if($input -like 'y'){
    Write-Host "Locking Resources in $($resourceGroupObj.ResourceGroupName)"
    Apply-Lock -resources $resources

  }
  else{
    Write-Host "Lock update canceled on $($resourceGroupObj.ResourceGroupName)"
  }
}







