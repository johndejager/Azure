<#
    .SYNOPSIS
    Create local network and VPN Connection.
    .DESCRIPTION
    This script will create a local network connection an a VPN Connection.
    .PARAMETER SubscriptionId
    Enter the subscriptionid of the customer.
    .PARAMETER lntwkName
    Enter the name of the local network, for example JohnsHome.
    .PARAMETER lntwResourceGroup
    Enter the name of the resource group where the local network connection will be created.
    .PARAMETER lntwIpAddress
    Enter the public IP of the local network.
    .PARAMETER -lntwAddressPrefixes
    Enter the subnet of the local network, for example 192.168.100.0/24 or multiple in this format '192.168.100.0/24','192.168.101.0/24'.
    .PARAMETER vpnGatewayName
    Enter the name of the VPN Gateway
    .PARAMETER vpnGatewayResourceGroup
    Enter the name of the resource group where the VPN Gateway is created.
    .PARAMETER sharedKey
    Enter a strong pre shared key
    .EXAMPLE
    Create-Azure-VPN.ps1 -SubscriptionId 1234-5678-9013-4455 lntwkName JohnsHome '
    -lntwResourceGroup rg-publicjohnny-vnet-01 -lntwIpAddress 8.8.8.8 '
    -lntwAddressPrefixes 192.168.100.0/24 -vpnGatewayName gw01 -vpnGatewayResourceGroup rg-gw01 -sharedKey strongkey
#>


param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$lntwkName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$lntwkResourceGroup,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$lntwkIpAddress,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [array]$lntwkAddressPrefixes,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$vpnGateWayName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$vpnGateWayResourceGroup,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$sharedKey

)

Set-AzContext -SubscriptionId $SubscriptionId

$Location = 'West Europe'
$vpnName = $lntwkName + '-to-Azure'

$deployParamsLntwk = @{
    Name = $lntwkName
    ResourceGroupName = $lntwkResourceGroup
    Location = $Location
    GatewayIpAddress = $lntwkIpAddress
    AddressPrefix = $lntwkAddressPrefixes
}
$deployParamsLntwk
New-AzLocalNetworkGateway @deployParamsLntwk

# Get Vnet Gateway and Local Network Connection
$gateway1 = Get-AzVirtualNetworkGateway -Name $vpnGateWayName -ResourceGroupName $vpnGateWayResourceGroup
$local = Get-AzLocalNetworkGateway -Name $lntwkName -ResourceGroupName $lntwkResourceGroup


$deployParamsVpn = @{
    Name = $vpnName
    ResourceGroupName = $vpnGateWayResourceGroup
    Location = $Location
    VirtualNetworkGateway1 = $gateway1
    LocalNetworkGateway2 = $local 
    ConnectionType = 'IPsec'
    ConnectionProtocol = 'IKEv2' 
    RoutingWeight = 10
    SharedKey = $sharedKey
}

# Create the VPN connection
New-AzVirtualNetworkGatewayConnection @deployParamsVpn

