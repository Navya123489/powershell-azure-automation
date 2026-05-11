<#
.SYNOPSIS
    Identifies unused Azure resources to reduce costs.

.DESCRIPTION
    Scans an Azure subscription for commonly unused resources including
    empty Resource Groups, unattached Managed Disks, and unassociated
    Public IP addresses. Exports findings to a CSV report.

.PARAMETER SubscriptionId
    The Azure Subscription ID to scan.

.EXAMPLE
    .\Get-UnusedResources.ps1 -SubscriptionId "your-subscription-id"

.NOTES
    Author: Navya Kanchisamudram
    Version: 1.0
    Requires: Az PowerShell module
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
)

# Set the subscription context
Set-AzContext -SubscriptionId $SubscriptionId

Write-Host "Scanning for unused resources in subscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$unusedResources = @()

# Check 1 — Empty Resource Groups
Write-Host "`nChecking for empty Resource Groups..." -ForegroundColor Yellow
$resourceGroups = Get-AzResourceGroup
foreach ($rg in $resourceGroups) {
    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
    if ($resources.Count -eq 0) {
        Write-Host "Empty Resource Group found: $($rg.ResourceGroupName)" -ForegroundColor Red
        $unusedResources += [PSCustomObject]@{
            ResourceType = "Resource Group"
            ResourceName = $rg.ResourceGroupName
            Location     = $rg.Location
            Issue        = "Empty - no resources inside"
            EstimatedSaving = "Low"
        }
    }
}

# Check 2 — Unattached Managed Disks
Write-Host "`nChecking for unattached Managed Disks..." -ForegroundColor Yellow
$disks = Get-AzDisk
foreach ($disk in $disks) {
    if ($disk.DiskState -eq "Unattached") {
        Write-Host "Unattached disk found: $($disk.Name) - Size: $($disk.DiskSizeGB)GB" -ForegroundColor Red
        $unusedResources += [PSCustomObject]@{
            ResourceType    = "Managed Disk"
            ResourceName    = $disk.Name
            Location        = $disk.Location
            Issue           = "Unattached - not connected to any VM"
            EstimatedSaving = "$($disk.DiskSizeGB)GB disk storage"
        }
    }
}

# Check 3 — Unassociated Public IP Addresses
Write-Host "`nChecking for unassociated Public IP addresses..." -ForegroundColor Yellow
$publicIPs = Get-AzPublicIpAddress
foreach ($ip in $publicIPs) {
    if ($null -eq $ip.IpConfiguration) {
        Write-Host "Unassociated Public IP found: $($ip.Name)" -ForegroundColor Red
        $unusedResources += [PSCustomObject]@{
            ResourceType    = "Public IP Address"
            ResourceName    = $ip.Name
            Location        = $ip.Location
            Issue           = "Unassociated - not attached to any resource"
            EstimatedSaving = "~$3-4/month per IP"
        }
    }
}

# Summary
Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "Scan complete. Total unused resources found: $($unusedResources.Count)" -ForegroundColor Cyan

if ($unusedResources.Count -gt 0) {
    # Export to CSV
    $reportPath = ".\Unused-Resources-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $unusedResources | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green
} else {
    Write-Host "No unused resources found. Subscription is clean." -ForegroundColor Green
}