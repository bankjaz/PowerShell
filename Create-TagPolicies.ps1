<#
    .SYNOPSIS
    Resource Group Tag Policy Script

    .DESCRIPTION
    This script will grab all resource groups in a subscription and create policies with the append option for each resource group
        
    .PARAMETER subscriptionID
    Target Azure subscription ID
 
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $True)]
  [string]$subscriptionId
)

#Tag Policy Name
$polName = "TagPolicy"


##########################
## Connect to Azure
##########################
Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId $subscriptionId


##########################
## Functions
##########################
function Get-ResourceGroups(){
  return Get-AzureRmResourceGroup 
}

function Verify-Policy($polName){
  $pol = Get-AzureRmPolicyDefinition -Name $polName
  return $pol
}

function Get-Policy($polName){
  return Get-AzureRmPolicyDefinition -Name $polname
}

function Add-Policy($policy, $resourceGroup, $tags){
  foreach($tag in $tags.GetEnumerator()){
      New-AzureRmPolicyAssignment -Name "$($policy.name)_$($tag.Name)" `
                                  -Scope $resourceGroup.resourceID `
                                  -PolicyDefinition $policy `
                                  -PolicyParameterObject @{"tagName"=$tag.Name; "tagValue"=$tag.Value}
  }

}

function Get-Tag($resourceGroup){
  return (Get-AzureRmResourceGroup -Name $resourceGroup.ResourceGroupName).Tags
}



##########################
## Main
##########################

#$resourceGroups = Get-ResourceGroup

if(!(Verify-Policy -polName $polName)){
  Write-Output "Tagging Policy name not found"
  exit
}
else{
  $policy = Get-Policy -polName $polName
}

foreach($resourceGroup in $resourceGroups){
  $tags = Get-Tag -resourceGroup $resourceGroup
  Write-Output "Resource Group - $($resourceGroup.ResourceGroupName) contains the following tags:"
  Write-Output $tags `n
  do{
    $input = Read-Host -Prompt "Would you like to apply policies for these tags? [Y]Yes, [any key]No"
  }
  until($input)
  if($input -like 'y'){
    Write-Host "Assigning Policies on $($resourceGroup.ResourceGroupName)"
    Add-Policy -resourceGroup $resourceGroup -tags $tags -policy $policy
  }
  else{
    Write-Host "Policy Assignment canceled on $($resourceGroup.ResourceGroupName)"
  }
}


