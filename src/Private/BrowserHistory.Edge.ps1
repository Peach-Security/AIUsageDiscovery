# BrowserHistory.Edge.ps1 - Microsoft Edge browser history scanning

function Get-EdgeHistory {
    <#
    .SYNOPSIS
    Parse Edge browser history for AI usage indicators.

    .DESCRIPTION
    Scans Microsoft Edge browser history SQLite database for URLs matching known AI tools.
    Edge is Chromium-based, so it uses the same database structure as Chrome.
    Supports multiple profiles and handles locked database files.

    .PARAMETER DaysBack
    Number of days of history to scan. Default is 90.

    .PARAMETER AllUsers
    Scan all users on the system instead of just the current user.
    Requires elevated/admin permissions.

    .EXAMPLE
    Get-EdgeHistory -DaysBack 30

    .EXAMPLE
    Get-EdgeHistory -AllUsers
    #>
    [CmdletBinding()]
    param(
        [int] $DaysBack = 90,

        [switch] $AllUsers
    )

    Write-Verbose "Starting Edge history scan..."
    $findings = @()

    # Get AI tool patterns
    $aiPatterns = Get-AIToolPatterns

    # Get Edge profile paths
    $profiles = Get-BrowserProfilePaths -Browser 'Edge' -AllUsers:$AllUsers

    if ($profiles.Count -eq 0) {
        Write-Verbose "No Edge profiles found."
        return $findings
    }

    Write-Verbose "Found $($profiles.Count) Edge profile(s)"

    foreach ($profile in $profiles) {
        Write-Verbose "Scanning Edge profile: $($profile.ProfileName)"

        # Query the history database (same schema as Chrome)
        $query = @"
SELECT url, title, visit_count, last_visit_time
FROM urls
WHERE last_visit_time > 0
ORDER BY last_visit_time DESC
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
                    if ($entry.last_visit_time) {
                        try {
                            $timestamp = Convert-ChromiumTimestamp -Timestamp ([long]$entry.last_visit_time)
                            
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
                        Browser    = 'Edge'
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

    Write-Verbose "Edge scan complete. Found $($findings.Count) AI-related entries."
    return $findings
}
