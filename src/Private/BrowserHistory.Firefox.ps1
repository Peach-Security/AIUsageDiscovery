# BrowserHistory.Firefox.ps1 - Firefox browser history scanning

function Get-FirefoxHistory {
    <#
    .SYNOPSIS
    Parse Firefox browser history for AI usage indicators.

    .DESCRIPTION
    Scans Firefox browser history SQLite database (places.sqlite) for URLs matching known AI tools.
    Firefox uses a different database schema than Chromium-based browsers.
    Supports multiple profiles and handles locked database files.

    .PARAMETER DaysBack
    Number of days of history to scan. Default is 90.

    .PARAMETER AllUsers
    Scan all users on the system instead of just the current user.
    Requires elevated/admin permissions.

    .EXAMPLE
    Get-FirefoxHistory -DaysBack 30

    .EXAMPLE
    Get-FirefoxHistory -AllUsers
    #>
    [CmdletBinding()]
    param(
        [int] $DaysBack = 90,

        [switch] $AllUsers
    )

    Write-Verbose "Starting Firefox history scan..."
    $findings = @()

    # Get AI tool patterns
    $aiPatterns = Get-AIToolPatterns

    # Get Firefox profile paths
    $profiles = Get-BrowserProfilePaths -Browser 'Firefox' -AllUsers:$AllUsers

    if ($profiles.Count -eq 0) {
        Write-Verbose "No Firefox profiles found."
        return $findings
    }

    Write-Verbose "Found $($profiles.Count) Firefox profile(s)"

    foreach ($profile in $profiles) {
        Write-Verbose "Scanning Firefox profile: $($profile.ProfileName)"

        # Query the places database
        # Firefox stores URLs in moz_places with visits in moz_historyvisits
        $query = @"
SELECT 
    p.url,
    p.title,
    p.visit_count,
    p.last_visit_date
FROM moz_places p
WHERE p.last_visit_date IS NOT NULL
    AND p.url NOT LIKE 'place:%'
ORDER BY p.last_visit_date DESC
"@

        $historyEntries = Invoke-SQLiteQuery -DatabasePath $profile.HistoryPath -Query $query

        if ($historyEntries.Count -eq 0) {
            Write-Verbose "No history entries found in profile: $($profile.ProfileName)"
            continue
        }

        Write-Verbose "Found $($historyEntries.Count) history entries in profile: $($profile.ProfileName)"

        foreach ($entry in $historyEntries) {
            $url = $entry.url
            if (-not $url) { continue }

            # Check against each AI pattern
            foreach ($pattern in $aiPatterns) {
                if ($url -match $pattern.Pattern) {
                    # Convert timestamp
                    $timestamp = $null
                    if ($entry.last_visit_date) {
                        try {
                            $timestamp = Convert-FirefoxTimestamp -Timestamp ([long]$entry.last_visit_date)
                            
                            # Filter by DaysBack
                            $cutoffDate = (Get-Date).AddDays(-$DaysBack)
                            if ($timestamp -lt $cutoffDate) {
                                continue
                            }
                        }
                        catch {
                            Write-Verbose "Failed to parse timestamp for URL: $url"
                        }
                    }

                    $findings += [PSCustomObject]@{
                        Browser    = 'Firefox'
                        Username   = $profile.Username
                        Profile    = $profile.ProfileName
                        Tool       = $pattern.Name
                        Category   = $pattern.Category
                        Url        = $url
                        Title      = $entry.title
                        VisitCount = [int]$entry.visit_count
                        Timestamp  = $timestamp
                    }

                    # Only match first pattern per URL
                    break
                }
            }
        }
    }

    Write-Verbose "Firefox scan complete. Found $($findings.Count) AI-related entries."
    return $findings
}
