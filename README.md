# SharePoint Online Site Creation Script
This PowerShell script automates the creation of SharePoint Online Team and Communication sites in a target tenant, using site metadata provided in a CSV file.

The script connects to your tenant via PnP.PowerShell, checks for existing sites, creates missing ones with a defined naming convention, and logs the outcome to a CSV report for auditing and review.

# Features
- Auto-installs and imports PnP.PowerShell if not present.

- Authenticates securely with Azure AD using interactive login and client ID.

- Transforms source site URLs and names with a configurable prefix.

- Supports:

  - Group-connected Team Sites

  - Communication Sites

- Skips already existing sites.

- Logs success, type, and any errors per site to a structured report.

# Prerequisites
- PowerShell 5.1 or newer

- PnP.PowerShell module (auto-installed if missing)

- Azure AD App Registration with delegated permissions

- Permissions:

  - SharePoint Admin in the target tenant

  - Consent granted to the app for PnP PowerShell scope
 
# Folder Structure
Place these files together:
-  SharePointSiteCreation.ps1      # This script
-  source_sites.csv                # Your input list of source sites
-  report_output.csv               # Output report (created after run)

# Supported "Site Type" values:
- Group Work Site or Team channel → Team Site (group-connected)
- Modern Team Site → Communication Site

# Configuration
Open SharePointSiteCreation.ps1 and update the following section:
```powershell
$targetTenant    = "https://yourtenant-admin.sharepoint.com"
$clientID        = "your-client-id-guid"
$sourceHostName  = "source.sharepoint.com"
$targetHostName  = "target.sharepoint.com"
$PreFix          = "MIG_"
```
# Troubleshooting
## 🧰 Troubleshooting

| **Issue**                          | **Solution**                                                                 |
|-----------------------------------|------------------------------------------------------------------------------|
| Error creating site               | Check if the site already exists, or validate the site type.                |
| CSV not processed                 | Ensure headers match exactly: `Site Display Name`, `Site URL`, `Site Type`. |
| PnP.PowerShell not installing     | Run `Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force` manually. |
| Site not created with correct URL | Check your `$sourceHostName`, `$targetHostName`, and `$PreFix` values.      |
| Permissions error                 | Ensure you're logging in with an admin account. |


