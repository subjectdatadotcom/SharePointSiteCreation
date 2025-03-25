<#
.SYNOPSIS
This script automates the creation of SharePoint Online sites in a target tenant using data from a CSV file.

.DESCRIPTION
The script connects to a target SharePoint Online tenant using the PnP PowerShell module and reads site details from a CSV file (`source_sites.csv`).

For each entry in the CSV file, the script:
- Generates a new site name and alias with a defined prefix.
- Constructs a target URL based on the source URL and configured tenant hostname.
- Checks whether the target site already exists.
- If it exists, logs its information to the report.
- If it does not exist:
  - Creates a new modern Team site (group-connected) or Communication site based on the source site type.
  - Logs success or failure along with error messages (if any).

All processed site details are exported to a report (`report_output.csv`) for auditing and tracking purposes.

.NOTES
- The `PnP.PowerShell` module must be installed and imported.
- Authentication to SharePoint Online uses `-Interactive` login with a registered Azure AD App Client ID.
- The `source_sites.csv` file must be located in the same directory as the script.
- The output report will be saved in the same directory as the script.

.AUTHOR
SubjectData

.EXAMPLE
.\SharePointSiteCreation.ps1
This will connect to the target tenant and process all entries in 'source_sites.csv', creating the corresponding sites if they do not already exist, and saving results to 'report_output.csv'.
#>

# Ensure PnP.PowerShell module is installed
if (-not (Get-Module -ListAvailable -Name "PnP.PowerShell")) {
    Write-Host "PnP.PowerShell module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name "PnP.PowerShell" -Scope CurrentUser -Force
}

Import-Module PnP.PowerShell


# Get directory of the script
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$myDir = "$myDir\"

# === CONFIGURATION ===
$sourceCsvPath = $myDir + "source_sites.csv"           # Input CSV
$outputCsvPath = $myDir + "report_output.csv"          # Output report CSV
$targetTenant = "https://yourtenant-admin.sharepoint.com"  # Update with your target SharePoint admin url
$clientID = "your-client-id-guid"                           # Azure AD App Client ID
$sourceHostName = "source.sharepoint.com"                   # Source SharePoint hostname
$targetHostName = "target.sharepoint.com"              # Target SharePoint hostname
$PreFix = "MIG_"                                            # Prefix for new sites

# Connect to the SharePoint tenant
Connect-PnPOnline -Url $targetTenant -Interactive -ClientId $ClientID

# Read source CSV
$sourceSites = Import-Csv -Path $sourceCsvPath

# Initialize report
$report = @()

foreach ($site in $sourceSites) {
    $sourceSiteURL = $site.'Site URL'
    $sourceSiteType = $site.'Site Type'
    $siteName = $site.'Site Display Name'
    $targetSiteName = $PreFix + $siteName
    $targetSiteAlias = $PreFix + ($sourceSiteURL.Split("/")[-1])

    # Transform URL
    $targetSiteURL = $sourceSiteURL -replace $sourceHostName, $targetHostName
    $pattern = "(/sites/)(.+)"
    $targetSiteURL = [regex]::Replace($targetSiteURL, $pattern, {
        param($match)
        return "/sites/" + $prefix + $match.Groups[2].Value
    })

    # Check if target site already exists
    $existingSite = Get-PnPTenantSite -Url $targetSiteURL -ErrorAction SilentlyContinue

    if ($existingSite) {
        Write-Host "Site already exists: $targetSiteURL" -ForegroundColor Magenta
        $targetSiteType = $existingSite.Template
        $errorMessage = ""
    } else {
        try {
            if ($sourceSiteType -eq "Group Work Site" -or $sourceSiteType -eq "Team channel") {
                # Create Group-connected Team site
                $newSite = New-PnPSite -Type TeamSite -Title $targetSiteName -Alias ($targetSiteAlias -replace "\s", "")
                $targetSiteType = (Get-PnPTenantSite -Url $newSite).Template
            }
            elseif ($sourceSiteType -eq "Modern Team Site") {
                # Create Communication site
                $newSite = New-PnPSite -Type CommunicationSite -Title $targetSiteName -Url $targetSiteURL
                $targetSiteType = (Get-PnPTenantSite -Url $newSite).Template
            }
            else {
                throw "Unknown site type: $sourceSiteType"
            }

            Write-Host "Created site: $targetSiteURL" -ForegroundColor Green
            $errorMessage = ""
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Host "Error creating site: $errorMessage" -ForegroundColor Red
            $targetSiteType = "Failed"
        }
    }

    # Add to report
    $report += [PSCustomObject]@{
        "Source Site Name" = $siteName
        "SourceSiteURL"    = $sourceSiteURL
        "Source Site Type" = $sourceSiteType
        "Target Site Name" = $targetSiteName
        "TargetSiteURL"    = $targetSiteURL
        "Target Site Type" = $targetSiteType
        "Error Message"    = $errorMessage
    }
}

# Export to CSV
$report | Export-Csv -Path $outputCsvPath -NoTypeInformation
Invoke-Item $outputCsvPath

Write-Host "Site migration completed. Report saved to: $outputCsvPath"
