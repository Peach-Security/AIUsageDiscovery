# BrowserHistory.Safari.ps1 - Safari browser history scanning (macOS only)

function Get-SafariHistory {
    <#
    .SYNOPSIS
    Parse Safari browser history for AI usage indicators.

    .DESCRIPTION
    Scans Safari browser history SQLite database for URLs matching known AI tools.
    Safari is only available on macOS, so this function only works on macOS.

    .PARAMETER DaysBack
    Number of days of history to scan. Default is 90.

    .PARAMETER AllUsers
    Scan all users on the system instead of just the current user.
    Requires elevated/admin permissions.

    .EXAMPLE
    Get-SafariHistory -DaysBack 30

    .EXAMPLE
    Get-SafariHistory -AllUsers
    #>
    [CmdletBinding()]
    param(
        [int] $DaysBack = 90,

        [switch] $AllUsers
    )

    Write-Verbose "Starting Safari history scan..."
    $findings = @()

    # Safari is only available on macOS
    $isMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
    if (-not $isMacOS) {
        Write-Verbose "Safari is only available on macOS. Skipping."
        return $findings
    }

    # Get AI tool patterns
    $aiPatterns = Get-AIToolPatterns

    # Get Safari profile paths
    $profiles = Get-BrowserProfilePaths -Browser 'Safari' -AllUsers:$AllUsers

    if ($profiles.Count -eq 0) {
        Write-Verbose "No Safari history found."
        return $findings
    }

    Write-Verbose "Found $($profiles.Count) Safari profile(s)"

    foreach ($profile in $profiles) {
        Write-Verbose "Scanning Safari profile: $($profile.ProfileName)"

        # Query the history database
        # Safari uses history_items for URLs and history_visits for timestamps
        # visit_time is seconds since 2001-01-01 (Mac absolute time / Cocoa epoch)
        $query = @"
SELECT 
    hi.url,
    hi.domain_expansion as title,
    hi.visit_count,
    hv.visit_time
FROM history_items hi
LEFT JOIN history_visits hv ON hi.id = hv.history_item
WHERE hv.visit_time IS NOT NULL
ORDER BY hv.visit_time DESC
"@

        $historyEntries = Invoke-SQLiteQuery -DatabasePath $profile.HistoryPath -Query $query

        if ($historyEntries.Count -eq 0) {
            Write-Verbose "No history entries found in Safari"
            continue
        }

        Write-Verbose "Found $($historyEntries.Count) history entries in Safari"

        foreach ($entry in $historyEntries) {
            $url = $entry.url
            if (-not $url) { continue }

            # Check against each AI pattern
            foreach ($pattern in $aiPatterns) {
                if ($url -match $pattern.Pattern) {
                    # Convert timestamp (Safari uses Mac absolute time - seconds since 2001-01-01)
                    $timestamp = $null
                    if ($entry.visit_time) {
                        try {
                            $timestamp = Convert-SafariTimestamp -Timestamp ([double]$entry.visit_time)
                            
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
                        Browser    = 'Safari'
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

    Write-Verbose "Safari scan complete. Found $($findings.Count) AI-related entries."
    return $findings
}

