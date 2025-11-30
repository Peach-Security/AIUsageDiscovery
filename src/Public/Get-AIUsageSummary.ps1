# Get-AIUsageSummary.ps1 - Summary view of AI usage findings

function Get-AIUsageSummary {
    <#
    .SYNOPSIS
    Provide a brief summary of AI usage findings.

    .DESCRIPTION
    Generates a quick summary of AI usage from browser history. Can run a quick scan
    or accept pipeline input from Get-AIUsageDiscovery.

    .PARAMETER ScanResults
    Optional scan results from Get-AIUsageDiscovery -PassThru. If not provided,
    runs a quick scan of all browsers.

    .PARAMETER DaysBack
    Number of days of history to scan if running a new scan. Default is 30.

    .PARAMETER Detailed
    Show detailed breakdown by tool and category.

    .EXAMPLE
    Get-AIUsageSummary
    Quick summary of AI usage from all browsers (last 30 days).

    .EXAMPLE
    Get-AIUsageSummary -DaysBack 7 -Detailed
    Detailed summary of the last 7 days.

    .EXAMPLE
    Get-AIUsageDiscovery -AllBrowsers -PassThru | Get-AIUsageSummary -Detailed
    Pipe results from a full scan for detailed summary.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [hashtable] $ScanResults,

        [ValidateRange(1, 3650)]
        [int] $DaysBack = 30,

        [switch] $Detailed
    )

    process {
        # Run a scan if no results provided
        if (-not $ScanResults) {
            Write-Verbose "No scan results provided, running quick scan..."
            $ScanResults = Invoke-AIUsageScan -Browsers @('Chrome', 'Edge', 'Firefox', 'Safari') -DaysBack $DaysBack
        }

        # Build summary object
        $summary = [PSCustomObject]@{
            Machine         = $ScanResults.Machine
            ScanTime        = $ScanResults.ScanTime
            DaysScanned     = if ($ScanResults.DaysBack) { $ScanResults.DaysBack } else { $DaysBack }
            TotalFindings   = $ScanResults.Summary.TotalFindings
            UniqueTools     = $ScanResults.Summary.UniqueTools
            BrowsersScanned = $ScanResults.Summary.BrowsersScanned
        }

        if ($Detailed) {
            # Add detailed breakdown
            $toolCounts = @{}
            $browserCounts = @{}
            $timelineCounts = @{}

            foreach ($browser in $ScanResults.Browsers.Keys) {
                $browserCounts[$browser] = $ScanResults.Browsers[$browser].Count
                
                foreach ($finding in $ScanResults.Browsers[$browser]) {
                    if (-not $toolCounts.ContainsKey($finding.Tool)) {
                        $toolCounts[$finding.Tool] = @{
                            Count    = 0
                            Category = $finding.Category
                        }
                    }
                    $toolCounts[$finding.Tool].Count++

                    # Group by time period for timeline
                    if ($finding.Timestamp) {
                        # Use week start date as key for grouping
                        $weekStart = $finding.Timestamp.Date.AddDays(-[int]$finding.Timestamp.DayOfWeek)
                        $weekKey = $weekStart.ToString('yyyy-MM-dd')
                        if (-not $timelineCounts.ContainsKey($weekKey)) {
                            $timelineCounts[$weekKey] = @{
                                Date  = $weekStart
                                Count = 0
                            }
                        }
                        $timelineCounts[$weekKey].Count++
                    }
                }
            }

            # Output detailed view with branding
            Write-Host ""
            Write-Host "    ____                 __       _____                      _ __       " -ForegroundColor DarkYellow
            Write-Host "   / __ \___  ____ _____/ /_     / ___/___  _______  _______(_) /___  __" -ForegroundColor DarkYellow
            Write-Host "  / /_/ / _ \/ __ `` / __/ __ \    \__ \/ _ \/ ___/ / / / ___/ / __/ / / /" -ForegroundColor Yellow
            Write-Host " / ____/  __/ /_/ / /_/ / / /   ___/ /  __/ /__/ /_/ / /  / / /_/ /_/ / " -ForegroundColor Yellow
            Write-Host "/_/    \___/\__,_/\__/_/ /_/   /____/\___/\___/\__,_/_/  /_/\__/\__, /  " -ForegroundColor DarkYellow
            Write-Host "                                                              /____/   " -ForegroundColor DarkYellow
            Write-Host ""
            Write-Host "  ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
            Write-Host "  ║" -ForegroundColor DarkGray -NoNewline
            Write-Host "            FREE TOOLS FRIDAY" -ForegroundColor Magenta -NoNewline
            Write-Host " - AI Usage Summary               ║" -ForegroundColor DarkGray
            Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "    Machine:        " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($summary.Machine)" -ForegroundColor White
            Write-Host "    Scan Time:      " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($summary.ScanTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
            Write-Host "    Period:         " -ForegroundColor DarkGray -NoNewline
            Write-Host "Last $($summary.DaysScanned) days" -ForegroundColor White
            Write-Host ""
            Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
            Write-Host "  │  FINDINGS OVERVIEW                                              │" -ForegroundColor Yellow
            Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
            Write-Host "    Total Visits:   " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($summary.TotalFindings)" -ForegroundColor $(if ($summary.TotalFindings -gt 0) { 'Yellow' } else { 'Green' })
            Write-Host "    Unique Tools:   " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($summary.UniqueTools)" -ForegroundColor White
            Write-Host ""

            if ($browserCounts.Count -gt 0) {
                Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
                Write-Host "  │  BY BROWSER                                                     │" -ForegroundColor Cyan
                Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
                foreach ($browser in $browserCounts.Keys | Sort-Object) {
                    $count = $browserCounts[$browser]
                    $bar = '█' * [Math]::Min($count, 30)
                    $barColor = if ($count -gt 0) { 'Yellow' } else { 'DarkGray' }
                    Write-Host "    $($browser.PadRight(10)) " -ForegroundColor White -NoNewline
                    Write-Host "$($count.ToString().PadLeft(5))  " -ForegroundColor Cyan -NoNewline
                    Write-Host "$bar" -ForegroundColor $barColor
                }
                Write-Host ""
            }

            if ($toolCounts.Count -gt 0) {
                Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Magenta
                Write-Host "  │  BY TOOL                                                        │" -ForegroundColor Magenta
                Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Magenta
                $sortedTools = $toolCounts.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending

                foreach ($entry in $sortedTools) {
                    $toolName = $entry.Key
                    $count = $entry.Value.Count
                    $category = $entry.Value.Category
                    Write-Host "    $($toolName.PadRight(20)) " -ForegroundColor White -NoNewline
                    Write-Host "$($count.ToString().PadLeft(5))  " -ForegroundColor Cyan -NoNewline
                    Write-Host "[$category]" -ForegroundColor DarkGray
                }
                Write-Host ""
            }

            if ($ScanResults.Summary.CategoryBreakdown.Count -gt 0) {
                Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
                Write-Host "  │  BY CATEGORY                                                    │" -ForegroundColor Green
                Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
                foreach ($category in $ScanResults.Summary.CategoryBreakdown.Keys | Sort-Object) {
                    $count = $ScanResults.Summary.CategoryBreakdown[$category]
                    $bar = '█' * [Math]::Min([Math]::Ceiling($count / 2), 20)
                    Write-Host "    $($category.PadRight(16)) " -ForegroundColor White -NoNewline
                    Write-Host "$($count.ToString().PadLeft(5))  " -ForegroundColor Cyan -NoNewline
                    Write-Host "$bar" -ForegroundColor Green
                }
                Write-Host ""
            }

            # Timeline chart - usage over time
            if ($timelineCounts.Count -gt 0) {
                Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Blue
                Write-Host "  │  USAGE OVER TIME (by week)                                      │" -ForegroundColor Blue
                Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Blue
                
                # Sort by date and get max for scaling
                $sortedTimeline = $timelineCounts.GetEnumerator() | Sort-Object { $_.Value.Date }
                $maxCount = ($sortedTimeline | ForEach-Object { $_.Value.Count } | Measure-Object -Maximum).Maximum
                if ($maxCount -eq 0) { $maxCount = 1 }
                
                # Calculate bar scale (max 40 chars wide)
                $maxBarWidth = 40
                
                foreach ($entry in $sortedTimeline) {
                    $weekDate = $entry.Value.Date
                    $count = $entry.Value.Count
                    $barWidth = [Math]::Max(1, [Math]::Ceiling(($count / $maxCount) * $maxBarWidth))
                    $bar = '█' * $barWidth
                    
                    # Format date as "MMM dd"
                    $dateLabel = $weekDate.ToString('MMM dd')
                    
                    Write-Host "    $($dateLabel.PadRight(8)) " -ForegroundColor DarkGray -NoNewline
                    Write-Host "$($count.ToString().PadLeft(4)) " -ForegroundColor Cyan -NoNewline
                    Write-Host "$bar" -ForegroundColor Blue
                }
                Write-Host ""
            }

            Write-Host "  ─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
            Write-Host "    github.com/Peach-Security" -ForegroundColor DarkCyan
            Write-Host ""
        }
        else {
            # Simple summary output
            return $summary
        }
    }
}
