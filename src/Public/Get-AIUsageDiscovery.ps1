# Get-AIUsageDiscovery.ps1 - Main public function for AI usage discovery

function Get-AIUsageDiscovery {
    <#
    .SYNOPSIS
    Run AI usage discovery across supported browsers.

    .DESCRIPTION
    Scans browser history databases (Chrome, Edge, Firefox, Safari) for URLs matching known AI tools.
    Supports cross-platform operation (Windows, macOS, Linux) and multiple export formats.

    .PARAMETER AllBrowsers
    Scan all supported browsers (Chrome, Edge, Firefox, Safari on macOS).

    .PARAMETER Chrome
    Scan only Google Chrome.

    .PARAMETER Edge
    Scan only Microsoft Edge.

    .PARAMETER Firefox
    Scan only Mozilla Firefox.

    .PARAMETER Safari
    Scan only Safari (macOS only).

    .PARAMETER AllUsers
    Scan all users on the system instead of just the current user.
    Requires elevated/admin permissions (Run as Administrator on Windows, sudo on macOS/Linux).

    .PARAMETER DaysBack
    Number of days of history to scan. Default is 90.

    .PARAMETER ExportJson
    Export findings to JSON format.

    .PARAMETER ExportCsv
    Export findings to CSV format.

    .PARAMETER ExportMarkdown
    Export findings to Markdown format.

    .PARAMETER OutputPath
    Output directory for exported reports. Defaults to current directory.

    .PARAMETER PassThru
    Return the raw scan results object in addition to any exports.

    .EXAMPLE
    Get-AIUsageDiscovery
    Scan all browsers (default behavior) and display results.

    .EXAMPLE
    Get-AIUsageDiscovery -Chrome -Edge -DaysBack 30
    Scan only Chrome and Edge for the last 30 days.

    .EXAMPLE
    Get-AIUsageDiscovery -ExportJson -ExportMarkdown -OutputPath "C:\Reports\AI"
    Scan all browsers and export to JSON and Markdown files.

    .EXAMPLE
    $results = Get-AIUsageDiscovery -PassThru
    Scan all browsers and capture the raw results object.

    .EXAMPLE
    Get-AIUsageDiscovery -AllUsers
    Scan all users on the system (requires admin/elevated permissions).
    #>
    [CmdletBinding()]
    param(
        [switch] $AllBrowsers,
        [switch] $Chrome,
        [switch] $Edge,
        [switch] $Firefox,
        [switch] $Safari,
        
        [switch] $AllUsers,
        
        [ValidateRange(1, 3650)]
        [int] $DaysBack = 90,
        
        [switch] $ExportJson,
        [switch] $ExportCsv,
        [switch] $ExportMarkdown,
        
        [string] $OutputPath = (Get-Location).Path,
        
        [switch] $PassThru
    )

    # Determine which browsers to scan (default: all browsers)
    $browsersToScan = @()

    if ($Chrome) { $browsersToScan += 'Chrome' }
    if ($Edge) { $browsersToScan += 'Edge' }
    if ($Firefox) { $browsersToScan += 'Firefox' }
    if ($Safari) { $browsersToScan += 'Safari' }

    # If no specific browser selected (or -AllBrowsers), scan all
    if ($browsersToScan.Count -eq 0 -or $AllBrowsers) {
        $browsersToScan = @('Chrome', 'Edge', 'Firefox', 'Safari')
    }

    Write-Verbose "AI Usage Discovery starting..."
    Write-Verbose "Browsers to scan: $($browsersToScan -join ', ')"
    Write-Verbose "Days back: $DaysBack"
    Write-Verbose "All users mode: $AllUsers"

    # Run the scan
    $scanResults = Invoke-AIUsageScan -Browsers $browsersToScan -DaysBack $DaysBack -AllUsers:$AllUsers

    # Display ASCII art header
    Write-Host ""
    Write-Host "    ____                 __       _____                      _ __       " -ForegroundColor DarkYellow
    Write-Host "   / __ \___  ____ _____/ /_     / ___/___  _______  _______(_) /___  __" -ForegroundColor DarkYellow
    Write-Host "  / /_/ / _ \/ __ \`/ __/ __ \    \__ \/ _ \/ ___/ / / / ___/ / __/ / / /" -ForegroundColor Yellow
    Write-Host " / ____/  __/ /_/ / /_/ / / /   ___/ /  __/ /__/ /_/ / /  / / /_/ /_/ / " -ForegroundColor Yellow
    Write-Host "/_/    \___/\__,_/\__/_/ /_/   /____/\___/\___/\__,_/_/  /_/\__/\__, /  " -ForegroundColor DarkYellow
    Write-Host "                                                              /____/   " -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "  ║" -ForegroundColor DarkGray -NoNewline
    Write-Host "            FREE TOOLS FRIDAY" -ForegroundColor Magenta -NoNewline
    Write-Host " - AI Usage Discovery             ║" -ForegroundColor DarkGray
    Write-Host "  ║" -ForegroundColor DarkGray -NoNewline
    Write-Host "                  github.com/Peach-Security                    " -ForegroundColor DarkCyan -NoNewline
    Write-Host "║" -ForegroundColor DarkGray
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""

    # Display summary to console
    Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │                      SCAN RESULTS                               │" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Machine:        " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($scanResults.Machine)" -ForegroundColor White
    Write-Host "    Scan Time:      " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($scanResults.ScanTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host "    Period:         " -ForegroundColor DarkGray -NoNewline
    Write-Host "Last $DaysBack days" -ForegroundColor White
    Write-Host "    Scope:          " -ForegroundColor DarkGray -NoNewline
    Write-Host $(if ($AllUsers) { "All Users" } else { "Current User" }) -ForegroundColor White
    Write-Host ""
    Write-Host "    Total Findings: " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($scanResults.Summary.TotalFindings)" -ForegroundColor $(if ($scanResults.Summary.TotalFindings -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "    Unique Tools:   " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($scanResults.Summary.UniqueTools)" -ForegroundColor White
    Write-Host ""

    if ($scanResults.Summary.TotalFindings -gt 0) {
        Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
        Write-Host "  │  DETECTED AI TOOLS                                              │" -ForegroundColor Yellow
        Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
        foreach ($tool in $scanResults.Summary.ToolsList) {
            Write-Host "    ► " -ForegroundColor Yellow -NoNewline
            Write-Host "$tool" -ForegroundColor White
        }
        Write-Host ""

        Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Magenta
        Write-Host "  │  BY CATEGORY                                                    │" -ForegroundColor Magenta
        Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Magenta
        foreach ($category in $scanResults.Summary.CategoryBreakdown.Keys | Sort-Object) {
            $count = $scanResults.Summary.CategoryBreakdown[$category]
            Write-Host "    ► " -ForegroundColor Magenta -NoNewline
            Write-Host "$category`: " -ForegroundColor White -NoNewline
            Write-Host "$count" -ForegroundColor Cyan
        }
        Write-Host ""

        Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
        Write-Host "  │  BY BROWSER                                                     │" -ForegroundColor Cyan
        Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
        foreach ($browser in $scanResults.Browsers.Keys | Sort-Object) {
            $count = $scanResults.Browsers[$browser].Count
            Write-Host "    ► " -ForegroundColor Cyan -NoNewline
            Write-Host "$browser`: " -ForegroundColor White -NoNewline
            Write-Host "$count findings" -ForegroundColor $(if ($count -gt 0) { 'Yellow' } else { 'DarkGray' })
        }
    }
    else {
        Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
        Write-Host "  │  ✓ No AI tool usage detected in browser history                │" -ForegroundColor Green
        Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    # Handle exports
    $exportedFiles = @()

    if ($ExportJson) {
        Write-Verbose "Exporting to JSON..."
        $result = Convert-ToReportFormat -ScanResults $scanResults -Format 'JSON' -OutputPath $OutputPath
        if ($result.FilePath) {
            $exportedFiles += $result.FilePath
            Write-Host "  Exported: $($result.FilePath)" -ForegroundColor Green
        }
    }

    if ($ExportCsv) {
        Write-Verbose "Exporting to CSV..."
        $result = Convert-ToReportFormat -ScanResults $scanResults -Format 'CSV' -OutputPath $OutputPath
        if ($result.FilePath) {
            $exportedFiles += $result.FilePath
            Write-Host "  Exported: $($result.FilePath)" -ForegroundColor Green
        }
    }

    if ($ExportMarkdown) {
        Write-Verbose "Exporting to Markdown..."
        $result = Convert-ToReportFormat -ScanResults $scanResults -Format 'Markdown' -OutputPath $OutputPath
        if ($result.FilePath) {
            $exportedFiles += $result.FilePath
            Write-Host "  Exported: $($result.FilePath)" -ForegroundColor Green
        }
    }

    if ($exportedFiles.Count -gt 0) {
        Write-Host ""
    }

    # Report any errors
    if ($scanResults.Errors.Count -gt 0) {
        Write-Host "  Warnings:" -ForegroundColor Yellow
        foreach ($error in $scanResults.Errors) {
            Write-Host "    • $error" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    # Return results if PassThru specified
    if ($PassThru) {
        return $scanResults
    }
}
