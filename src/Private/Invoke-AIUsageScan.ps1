# Invoke-AIUsageScan.ps1 - Orchestrator for AI usage scanning

function Invoke-AIUsageScan {
    <#
    .SYNOPSIS
    Orchestrate AI usage scanning across selected browsers.

    .DESCRIPTION
    Coordinates browser history parsing across Chrome, Edge, Firefox, and Safari.
    Aggregates results and handles errors gracefully for each browser.

    .PARAMETER Browsers
    Array of browsers to scan. Valid values: Chrome, Edge, Firefox, Safari.

    .PARAMETER DaysBack
    Number of days of history to scan. Default is 90.

    .PARAMETER AllUsers
    Scan all users on the system instead of just the current user.
    Requires elevated/admin permissions.

    .EXAMPLE
    Invoke-AIUsageScan -Browsers @('Chrome', 'Safari') -DaysBack 30

    .EXAMPLE
    Invoke-AIUsageScan -Browsers @('Chrome') -AllUsers
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Chrome', 'Edge', 'Firefox', 'Safari')]
        [string[]] $Browsers,

        [int] $DaysBack = 90,

        [switch] $AllUsers
    )

    Write-Verbose "Starting AI usage scan for browsers: $($Browsers -join ', ')"
    Write-Verbose "Scanning last $DaysBack days of history"
    
    if ($AllUsers) {
        Write-Verbose "AllUsers mode enabled - scanning all users on system"
        if (-not (Test-IsElevated)) {
            Write-Warning "AllUsers mode requires elevated/admin permissions. Some user directories may not be accessible."
        }
    }

    # Initialize results structure
    $results = @{
        Machine   = [System.Environment]::MachineName
        ScanTime  = Get-Date
        DaysBack  = $DaysBack
        Browsers  = @{}
        Errors    = @()
    }

    foreach ($browser in $Browsers) {
        Write-Verbose "Processing browser: $browser"
        
        try {
            $findings = switch ($browser) {
                'Chrome' {
                    Get-ChromeHistory -DaysBack $DaysBack -AllUsers:$AllUsers
                }
                'Edge' {
                    Get-EdgeHistory -DaysBack $DaysBack -AllUsers:$AllUsers
                }
                'Firefox' {
                    Get-FirefoxHistory -DaysBack $DaysBack -AllUsers:$AllUsers
                }
                'Safari' {
                    Get-SafariHistory -DaysBack $DaysBack -AllUsers:$AllUsers
                }
            }

            $results.Browsers[$browser] = @($findings)
            Write-Verbose "$browser scan complete: $($findings.Count) findings"
        }
        catch {
            $errorMsg = "Failed to scan $browser`: $_"
            Write-Warning $errorMsg
            $results.Errors += $errorMsg
            $results.Browsers[$browser] = @()
        }
    }

    # Calculate summary statistics
    $totalFindings = 0
    $uniqueTools = @{}
    $categoryBreakdown = @{}

    foreach ($browser in $results.Browsers.Keys) {
        foreach ($finding in $results.Browsers[$browser]) {
            $totalFindings++
            $uniqueTools[$finding.Tool] = $true
            
            if (-not $categoryBreakdown.ContainsKey($finding.Category)) {
                $categoryBreakdown[$finding.Category] = 0
            }
            $categoryBreakdown[$finding.Category]++
        }
    }

    $results.Summary = @{
        TotalFindings     = $totalFindings
        UniqueTools       = $uniqueTools.Keys.Count
        ToolsList         = @($uniqueTools.Keys | Sort-Object)
        CategoryBreakdown = $categoryBreakdown
        BrowsersScanned   = $Browsers.Count
    }

    Write-Verbose "Scan complete. Total findings: $totalFindings across $($uniqueTools.Keys.Count) unique AI tools"

    return $results
}
