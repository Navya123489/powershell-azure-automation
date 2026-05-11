# powershell-azure-automation
PowerShell scripts for Azure operational automation — incident response, reporting and user management


# PowerShell Azure Automation

Production-grade PowerShell scripts for Azure operational 
automation, built following enterprise DevOps practices.

## Scripts

### incident-response/
| Script | Purpose |
|---|---|
| `Get-VMHealth.ps1` | Checks health status of all VMs in a Resource Group. Exports CSV report. |

### reporting/
| Script | Purpose |
|---|---|
| `Get-UnusedResources.ps1` | Scans subscription for unused resources to reduce costs. |

### user-management/
| Script | Purpose |
|---|---|
| `Set-RBACAssignment.ps1` | Assigns or removes Azure RBAC roles following least-privilege principles. |

## How to use

```powershell
# VM Health Check
.\incident-response\Get-VMHealth.ps1 -ResourceGroupName "rg-myproject-dev"

# Unused Resources Report
.\reporting\Get-UnusedResources.ps1 -SubscriptionId "your-sub-id"

# RBAC Assignment
.\user-management\Set-RBACAssignment.ps1 -UserEmail "user@company.com" `
  -RoleName "Reader" -ResourceGroupName "rg-myproject-dev" -Action "Add"
```

## Requirements
- PowerShell 7+
- Az PowerShell module (`Install-Module -Name Az`)
- Azure subscription with appropriate permissions

## Author
Navya Kanchisamudram — Azure Administrator (AZ-104)
