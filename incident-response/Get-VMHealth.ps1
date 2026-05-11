<#
.SYNOPSIS
    Checks the health status of all VMs in a Resource Group.

.DESCRIPTION
    Retrieves all Virtual Machines in a specified Azure Resource Group
    and reports their current power state. Flags any VMs that are 
    not in a running state for investigation.

.PARAMETER ResourceGroupName
    The name of the Azure Resource Group to check.

.EXAMPLE
    .\Get-VMHealth.ps1 -ResourceGroupName "rg-myproject-dev"

.NOTES
    Author: Navya Kanchisamudram
    Version: 1.0
    Requires: Az PowerShell module
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName
)

# Connect to Azure (comment out if already connected)
# Connect-AzAccount

Write-Host "Checking VM health in Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Get all VMs in the resource group
$vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Status

if ($vms.Count -eq 0) {
    Write-Host "No VMs found in Resource Group: $ResourceGroupName" -ForegroundColor Yellow
    exit
}

$healthReport = @()

foreach ($vm in $vms) {
    $powerState = $vm.PowerState

    # Determine health status
    if ($powerState -eq "VM running") {
        $status = "Healthy"
        $colour = "Green"
    } else {
        $status = "Needs Attention"
        $colour = "Red"
    }

    Write-Host "VM: $($vm.Name) | State: $powerState | Status: $status" -ForegroundColor $colour

    # Add to report
    $healthReport += [PSCustomObject]@{
        VMName     = $vm.Name
        PowerState = $powerState
        Status     = $status
        Location   = $vm.Location
        CheckedAt  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Summary: $($healthReport.Count) VMs checked" -ForegroundColor Cyan
Write-Host "Healthy: $(($healthReport | Where-Object Status -eq 'Healthy').Count)" -ForegroundColor Green
Write-Host "Needs Attention: $(($healthReport | Where-Object Status -eq 'Needs Attention').Count)" -ForegroundColor Red

# Export report to CSV
$reportPath = ".\VM-Health-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$healthReport | Export-Csv -Path $reportPath -NoTypeInformation
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan