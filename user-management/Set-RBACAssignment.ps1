<#
.SYNOPSIS
    Manages Azure RBAC role assignments for users and service principals.

.DESCRIPTION
    Assigns or removes Azure RBAC roles for users across Resource Groups
    following least-privilege principles. Logs all changes for audit purposes.

.PARAMETER UserEmail
    The email address of the user to assign the role to.

.PARAMETER RoleName
    The Azure RBAC role to assign (e.g. Reader, Contributor, Owner).

.PARAMETER ResourceGroupName
    The Resource Group to scope the role assignment to.

.PARAMETER Action
    Whether to Add or Remove the role assignment.

.EXAMPLE
    .\Set-RBACAssignment.ps1 -UserEmail "user@company.com" -RoleName "Reader" -ResourceGroupName "rg-myproject-dev" -Action "Add"

.NOTES
    Author: Navya Kanchisamudram
    Version: 1.0
    Requires: Az PowerShell module
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$UserEmail,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Reader", "Contributor", "Owner", "Storage Blob Data Reader", "Key Vault Secrets User")]
    [string]$RoleName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Add", "Remove")]
    [string]$Action
)

Write-Host "RBAC Management Script" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "User:           $UserEmail" -ForegroundColor White
Write-Host "Role:           $RoleName" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Action:         $Action" -ForegroundColor White
Write-Host "=================================================" -ForegroundColor Cyan

# Get the user object
try {
    $user = Get-AzADUser -UserPrincipalName $UserEmail
    if ($null -eq $user) {
        Write-Host "User not found: $UserEmail" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error finding user: $_" -ForegroundColor Red
    exit 1
}

# Get the resource group scope
$scope = "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName"

if ($Action -eq "Add") {
    # Check if assignment already exists
    $existing = Get-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName $RoleName -Scope $scope

    if ($existing) {
        Write-Host "Role already assigned. No changes made." -ForegroundColor Yellow
    } else {
        New-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName $RoleName -Scope $scope
        Write-Host "Successfully assigned '$RoleName' to $UserEmail" -ForegroundColor Green
    }
} elseif ($Action -eq "Remove") {
    # Check if assignment exists before removing
    $existing = Get-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName $RoleName -Scope $scope

    if ($null -eq $existing) {
        Write-Host "Role assignment not found. No changes made." -ForegroundColor Yellow
    } else {
        Remove-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName $RoleName -Scope $scope
        Write-Host "Successfully removed '$RoleName' from $UserEmail" -ForegroundColor Green
    }
}

# Log the action
$logEntry = [PSCustomObject]@{
    Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    UserEmail         = $UserEmail
    RoleName          = $RoleName
    ResourceGroup     = $ResourceGroupName
    Action            = $Action
    PerformedBy       = (Get-AzContext).Account.Id
}

$logPath = ".\RBAC-Audit-Log-$(Get-Date -Format 'yyyyMM').csv"
$logEntry | Export-Csv -Path $logPath -NoTypeInformation -Append
Write-Host "Action logged to: $logPath" -ForegroundColor Cyan