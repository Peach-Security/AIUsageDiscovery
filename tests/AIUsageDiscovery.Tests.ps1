# AIUsageDiscovery.Tests.ps1 - Pester tests for AI Usage Discovery module

BeforeAll {
    # Import the module
    Import-Module "$PSScriptRoot/../src/PeachSecurity.AIUsageDiscovery.psd1" -Force
}

Describe 'Module Loading' {
    It 'should load the module without errors' {
        { Get-Module -Name PeachSecurity.AIUsageDiscovery } | Should -Not -Throw
    }

    It 'should export Get-AIUsageDiscovery function' {
        Get-Command -Name Get-AIUsageDiscovery -Module PeachSecurity.AIUsageDiscovery | Should -Not -BeNullOrEmpty
    }

    It 'should export Get-AIUsageSummary function' {
        Get-Command -Name Get-AIUsageSummary -Module PeachSecurity.AIUsageDiscovery | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AIToolPatterns' {
    BeforeAll {
        # Access private function via module scope
        $patterns = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-AIToolPatterns }
    }

    It 'should return an array of patterns' {
        $patterns | Should -BeOfType [System.Collections.Hashtable]
        $patterns.Count | Should -BeGreaterThan 0
    }

    It 'should include ChatGPT pattern' {
        $chatgpt = $patterns | Where-Object { $_.Name -eq 'ChatGPT' }
        $chatgpt | Should -Not -BeNullOrEmpty
        $chatgpt.Category | Should -Be 'Generative AI'
    }

    It 'should include Claude pattern' {
        $claude = $patterns | Where-Object { $_.Name -eq 'Claude' }
        $claude | Should -Not -BeNullOrEmpty
        $claude.Category | Should -Be 'Generative AI'
    }

    It 'should include patterns for multiple categories' {
        $categories = $patterns | Select-Object -ExpandProperty Category -Unique
        $categories | Should -Contain 'Generative AI'
        $categories | Should -Contain 'Code AI'
        $categories | Should -Contain 'Image AI'
    }

    It 'should have valid regex patterns' {
        foreach ($pattern in $patterns) {
            { [regex]::new($pattern.Pattern) } | Should -Not -Throw
        }
    }
}

Describe 'Pattern Matching' {
    BeforeAll {
        $patterns = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-AIToolPatterns }
    }

    It 'should match ChatGPT URLs' {
        $chatgpt = ($patterns | Where-Object { $_.Name -eq 'ChatGPT' }).Pattern
        'https://chat.openai.com/c/abc123' | Should -Match $chatgpt
        'https://chatgpt.com/' | Should -Match $chatgpt
    }

    It 'should match Claude URLs' {
        $claude = ($patterns | Where-Object { $_.Name -eq 'Claude' }).Pattern
        'https://claude.ai/chat/abc123' | Should -Match $claude
    }

    It 'should match GitHub Copilot URLs' {
        $copilot = ($patterns | Where-Object { $_.Name -eq 'GitHub Copilot' }).Pattern
        'https://github.com/features/copilot' | Should -Match $copilot
    }

    It 'should match Midjourney URLs' {
        $midjourney = ($patterns | Where-Object { $_.Name -eq 'Midjourney' }).Pattern
        'https://www.midjourney.com/app/' | Should -Match $midjourney
    }

    It 'should not match unrelated URLs' {
        $chatgpt = ($patterns | Where-Object { $_.Name -eq 'ChatGPT' }).Pattern
        'https://www.google.com/' | Should -Not -Match $chatgpt
        'https://github.com/' | Should -Not -Match $chatgpt
    }
}

Describe 'Get-BrowserProfilePaths' {
    It 'should return array for Chrome' {
        $paths = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Chrome' }
        # Paths can be empty if browser not installed, but should be an array
        $paths | Should -Not -Be $null -Because "Function should return empty array, not null"
    }

    It 'should return array for Edge' {
        $paths = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Edge' }
        # Edge may not be installed, function should return empty array not throw
        { & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Edge' } } | Should -Not -Throw
    }

    It 'should return array for Firefox' {
        $paths = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Firefox' }
        # Firefox may not be installed, function should return empty array not throw
        { & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Firefox' } } | Should -Not -Throw
    }

    It 'should return array for Safari on macOS' {
        # Safari is only supported on macOS, but function should not throw
        { & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Safari' } } | Should -Not -Throw
    }

    It 'should accept AllUsers parameter' {
        # Should not throw, even if not elevated
        { & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Chrome' -AllUsers } } | Should -Not -Throw
    }

    It 'should include Username in profile paths' {
        $paths = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-BrowserProfilePaths -Browser 'Chrome' }
        if ($paths.Count -gt 0) {
            $paths[0].Username | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Convert-ChromiumTimestamp' {
    It 'should convert Chromium timestamp to DateTime' {
        # Known timestamp: 13349245200000000 = 2024-01-01 00:00:00 UTC (approximately)
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { Convert-ChromiumTimestamp -Timestamp 13349245200000000 }
        $result | Should -BeOfType [DateTime]
        $result.Year | Should -Be 2024
    }

    It 'should handle zero timestamp' {
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { Convert-ChromiumTimestamp -Timestamp 0 }
        $result | Should -BeOfType [DateTime]
        $result.Year | Should -Be 1601
    }
}

Describe 'Convert-FirefoxTimestamp' {
    It 'should convert Firefox timestamp to DateTime' {
        # Unix timestamp in microseconds: 1704067200000000 = 2024-01-01 00:00:00 UTC
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { Convert-FirefoxTimestamp -Timestamp 1704067200000000 }
        $result | Should -BeOfType [DateTime]
        $result.Year | Should -Be 2024
    }

    It 'should handle zero timestamp' {
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { Convert-FirefoxTimestamp -Timestamp 0 }
        $result | Should -BeOfType [DateTime]
        $result.Year | Should -Be 1970
    }
}

Describe 'Convert-ToReportFormat' {
    It 'should generate valid JSON output' {
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { 
            $mockData = @{
                Machine  = 'TEST-PC'
                ScanTime = Get-Date '2024-01-15 10:30:00'
                Browsers = @{
                    'Chrome' = @(
                        [PSCustomObject]@{
                            Browser    = 'Chrome'
                            Username   = 'testuser'
                            Profile    = 'Default'
                            Tool       = 'ChatGPT'
                            Category   = 'Generative AI'
                            Url        = 'https://chat.openai.com/'
                            Title      = 'ChatGPT'
                            VisitCount = 5
                            Timestamp  = Get-Date '2024-01-14 09:00:00'
                        }
                    )
                }
            }
            Convert-ToReportFormat -ScanResults $mockData -Format 'JSON' 
        }
        $result.Content | Should -Not -BeNullOrEmpty
        { $result.Content | ConvertFrom-Json } | Should -Not -Throw
        $result.Content | Should -Match 'testuser'
    }

    It 'should generate valid CSV output' {
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { 
            $mockData = @{
                Machine  = 'TEST-PC'
                ScanTime = Get-Date '2024-01-15 10:30:00'
                Browsers = @{
                    'Chrome' = @(
                        [PSCustomObject]@{
                            Browser    = 'Chrome'
                            Username   = 'testuser'
                            Profile    = 'Default'
                            Tool       = 'ChatGPT'
                            Category   = 'Generative AI'
                            Url        = 'https://chat.openai.com/'
                            Title      = 'ChatGPT'
                            VisitCount = 5
                            Timestamp  = Get-Date '2024-01-14 09:00:00'
                        }
                    )
                }
            }
            Convert-ToReportFormat -ScanResults $mockData -Format 'CSV' 
        }
        $result.Content | Should -Not -BeNullOrEmpty
        $result.Content | Should -Match 'ChatGPT'
        $result.Content | Should -Match 'testuser'
    }

    It 'should generate valid Markdown output' {
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { 
            $mockData = @{
                Machine  = 'TEST-PC'
                ScanTime = Get-Date '2024-01-15 10:30:00'
                Browsers = @{
                    'Chrome' = @(
                        [PSCustomObject]@{
                            Browser    = 'Chrome'
                            Username   = 'testuser'
                            Profile    = 'Default'
                            Tool       = 'ChatGPT'
                            Category   = 'Generative AI'
                            Url        = 'https://chat.openai.com/'
                            Title      = 'ChatGPT'
                            VisitCount = 5
                            Timestamp  = Get-Date '2024-01-14 09:00:00'
                        }
                    )
                }
            }
            Convert-ToReportFormat -ScanResults $mockData -Format 'Markdown' 
        }
        $result.Content | Should -Not -BeNullOrEmpty
        $result.Content | Should -Match '# AI Usage Discovery Report'
        $result.Content | Should -Match 'ChatGPT'
        $result.Content | Should -Match 'testuser'
    }
}

Describe 'Test-IsElevated' {
    It 'should return a boolean' {
        $result = & (Get-Module PeachSecurity.AIUsageDiscovery) { Test-IsElevated }
        $result | Should -BeOfType [bool]
    }
}

Describe 'Get-AllUserPaths' {
    It 'should return an array of user paths' {
        $paths = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-AllUserPaths }
        # Should find at least the current user or be empty if no access
        $paths | Should -Not -Be $null
    }

    It 'should include Username in each path entry' {
        $paths = & (Get-Module PeachSecurity.AIUsageDiscovery) { Get-AllUserPaths }
        if ($paths.Count -gt 0) {
            $paths[0].Username | Should -Not -BeNullOrEmpty
            $paths[0].HomePath | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Invoke-AIUsageScan' {
    It 'should return valid results structure' {
        $results = & (Get-Module PeachSecurity.AIUsageDiscovery) { 
            Invoke-AIUsageScan -Browsers @('Chrome') -DaysBack 1 
        }
        
        $results | Should -Not -BeNullOrEmpty
        $results.Machine | Should -Not -BeNullOrEmpty
        $results.ScanTime | Should -BeOfType [DateTime]
        $results.Browsers | Should -Not -BeNullOrEmpty
        $results.Summary | Should -Not -BeNullOrEmpty
    }

    It 'should scan multiple browsers' {
        $results = & (Get-Module PeachSecurity.AIUsageDiscovery) { 
            Invoke-AIUsageScan -Browsers @('Chrome', 'Edge') -DaysBack 1 
        }
        
        $results.Browsers.Keys | Should -Contain 'Chrome'
        $results.Browsers.Keys | Should -Contain 'Edge'
    }
}

Describe 'Get-AIUsageDiscovery Parameters' {
    It 'should accept AllBrowsers switch' {
        $cmd = Get-Command -Name Get-AIUsageDiscovery
        $cmd.Parameters.Keys | Should -Contain 'AllBrowsers'
    }

    It 'should accept individual browser switches' {
        $cmd = Get-Command -Name Get-AIUsageDiscovery
        $cmd.Parameters.Keys | Should -Contain 'Chrome'
        $cmd.Parameters.Keys | Should -Contain 'Edge'
        $cmd.Parameters.Keys | Should -Contain 'Firefox'
    }

    It 'should accept export format switches' {
        $cmd = Get-Command -Name Get-AIUsageDiscovery
        $cmd.Parameters.Keys | Should -Contain 'ExportJson'
        $cmd.Parameters.Keys | Should -Contain 'ExportCsv'
        $cmd.Parameters.Keys | Should -Contain 'ExportMarkdown'
    }

    It 'should accept DaysBack parameter with validation' {
        $cmd = Get-Command -Name Get-AIUsageDiscovery
        $cmd.Parameters.Keys | Should -Contain 'DaysBack'
        $param = $cmd.Parameters['DaysBack']
        $param.ParameterType | Should -Be ([int])
    }

    It 'should accept OutputPath parameter' {
        $cmd = Get-Command -Name Get-AIUsageDiscovery
        $cmd.Parameters.Keys | Should -Contain 'OutputPath'
    }

    It 'should accept PassThru switch' {
        $cmd = Get-Command -Name Get-AIUsageDiscovery
        $cmd.Parameters.Keys | Should -Contain 'PassThru'
    }

    It 'should accept AllUsers switch' {
        $cmd = Get-Command -Name Get-AIUsageDiscovery
        $cmd.Parameters.Keys | Should -Contain 'AllUsers'
    }
}

Describe 'Get-AIUsageSummary Parameters' {
    It 'should accept pipeline input' {
        $cmd = Get-Command -Name Get-AIUsageSummary
        $cmd.Parameters['ScanResults'].Attributes | 
            Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
            Select-Object -ExpandProperty ValueFromPipeline | 
            Should -Be $true
    }

    It 'should accept Detailed switch' {
        $cmd = Get-Command -Name Get-AIUsageSummary
        $cmd.Parameters.Keys | Should -Contain 'Detailed'
    }

    It 'should accept DaysBack parameter' {
        $cmd = Get-Command -Name Get-AIUsageSummary
        $cmd.Parameters.Keys | Should -Contain 'DaysBack'
    }
}

AfterAll {
    Remove-Module PeachSecurity.AIUsageDiscovery -Force -ErrorAction SilentlyContinue
}
