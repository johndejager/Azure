<#
    .SYNOPSIS
    Create Azure Landing Zone (ALZ) for a new customer.
    .DESCRIPTION
    Create Azure Landing Zone (ALZ) for a new customer based on the Unica Cloud Solutions (UCS) naming convention.
    .PARAMETER SubscriptionId
    Enter the subscriptionid of the customer.
    .PARAMETER customerAbbreviation
    Enter the abbreviation for the customer.
    .PARAMETER VnetAddressSpace
    Enter the Address space for the VNET, should be atleast /22
    .EXAMPLE
    Deploy-Alz.ps1 -SubscriptionId 1234-5678-9013-4455 -custabbr ucs -VnetAddressSpace 10.232.0.0/22 -vpnGateway $true
#>
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$customerAbbreviation,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VnetAddressSpace,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$vpnGateWay

)

Set-AzContext -SubscriptionId $SubscriptionId

# Create naming standards based on customer abbreviation
$location = 'westeurope'
$VnetResourceGroup = "rg-$($customerAbbreviation)-vnet-01"
$VnetName = "$($customerAbbreviation)-vnet-01"
$DefaultSubnetName = "DefaultSubnet"
$DefaultSubnetNSGName = "nsg-" + $DefaultSubnetName
$AVDSubnetName = "AVDSubnet"
$AVDSubnetNSGName = "nsg-" + $AVDSubnetName
$bit = (($VnetAddressSpace).Split('/'))[0].Split(".")
$GatewaySubnetSpace = $bit[0] + "." + $bit[1]  + "." + $bit[2] + "." + "0" + "/27"
$DefaultSubnetSpace = $bit[0] + "." + $bit[1]  + "." + "1" + "." + "0" + "/24"
$AVDSubnetSpace = $bit[0] + "." + $bit[1]  + "." + "2" + "." + "0" + "/24"
$rsvResourceGroup = "rg-$($customerAbbreviation)-rsv-01"
$rsvNameLRS = "rsv-$($customerAbbreviation)-lrs"
$rsvNameGRS = "rsv-$($customerAbbreviation)-grs"

# Create VNET
New-AzResourceGroup -Name $VnetResourceGroup -Location $Location 
$vnet = New-AzVirtualNetwork -Name $VnetName -Location $location -ResourceGroupName $VnetResourceGroup -AddressPrefix $VnetAddressSpace

# Create NSGs
$DefaultNSG = New-AzNetworkSecurityGroup -Name $DefaultSubnetNSGName -ResourceGroupName $VnetResourceGroup -location $location
$AVDNSG = New-AzNetworkSecurityGroup -Name $AVDSubnetNSGName -ResourceGroupName $VnetResourceGroup -location $location

# Create Subnet Configs
Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name GatewaySubnet -AddressPrefix $GatewaySubnetSpace 
Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $DefaultSubnetName -AddressPrefix $DefaultSubnetSpace -NetworkSecurityGroup $DefaultNSG
Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $AVDSubnetName  -AddressPrefix $AVDSubnetSpace -NetworkSecurityGroup $AVDNSG

# Set VNET
Set-AzVirtualNetwork -VirtualNetwork $vnet

# Create Recovery Service Vaults
New-AzResourceGroup -Name $rsvResourceGroup -Location $Location 
$rsvLRS = New-AzRecoveryServicesVault -ResourceGroupName $rsvResourceGroup -Name $rsvNameLRS -Location $location 
Set-AzRecoveryServicesBackupProperty -Vault $rsvLRS -BackupStorageRedundancy LocallyRedundant
$rsvGRS = New-AzRecoveryServicesVault -ResourceGroupName $rsvResourceGroup -Name $rsvNameGRS -Location $location
Set-AzRecoveryServicesBackupProperty -Vault $rsvGRS -BackupStorageRedundancy GeoRedundant

If ($vpnGateWay) {
    Write-Host "Creating VPN Gateway"
    $vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $VnetResourceGroup 
    $vnetGWName = "$($customerAbbreviation)-vnetgw-01"
    $vnetGWPIPName = "$($vnetGWName)-pip" 
    $subnet = Get-AzVirtualNetworkSubnetConfig -name 'GatewaySubnet' -VirtualNetwork $vnet
    $ngwpip = New-AzPublicIpAddress -Name $vnetGWPIPName -ResourceGroupName $VnetResourceGroup -Location $location -AllocationMethod Dynamic
    $ngwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name ngwipconfig -SubnetId $subnet.Id -PublicIpAddressId $ngwpip.Id
    New-AzVirtualNetworkGateway -ResourceGroupName $VnetResourceGroup -Name $vnetGWName -Location $location -IpConfigurations $ngwipconfig -GatewayType "Vpn" -VpnType "RouteBased" -GatewaySku "Basic" 
}
else {
    Write-Host "No need to create VPN Gateway." 
}


