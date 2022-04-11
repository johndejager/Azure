<#
  .SYNOPSIS
    Cleanup resources in a subscription
  .DESCRIPTION
    This script will remove all resources in a specific subscription.
  .PARAMETER subscriptionId
    SubscriptionId of the subscription where resources will be removed.
  .EXAMPLE
    ./cleanup-Subscription.ps1 -subscriptionId 371ceb6e-2775-41b9-8905-2cfd8f31238a
#>
<#
=======================================================================================
AUTHOR:  John de Jager
DATE:    25/03/2022
Version: 1.0
Comment: bulk remove resources in a subscription.
=======================================================================================
#>
Param(
    [Parameter(Mandatory = $True)] $subscriptionId
)


$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
Set-AzContext -Subscription $subscription.Name


Get-AzResourceGroup | Remove-AzResourceGroup -Force





