@{
    RootModule        = 'PeachSecurity.AIUsageDiscovery.psm1'
    ModuleVersion     = '1.1.1'
    GUID              = '00000000-0000-0000-0000-000000000000' # placeholder, I'll replace with a real GUID
    Author            = 'Peach Security'
    CompanyName       = 'Peach Security'
    Description       = 'Discover AI usage and Shadow AI across Chrome, Edge, and Firefox using PowerShell.'
    FunctionsToExport = @(
        'Get-AIUsageDiscovery',
        'Get-AIUsageSummary'
    )
    CmdletsToExport   = @()
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags         = @('AI', 'MSP', 'Security', 'Discovery', 'Browser', 'ShadowAI', 'PeachSecurity')
            ProjectUri   = 'https://github.com/Peach-Security/AIUsageDiscovery'
            LicenseUri   = 'https://github.com/Peach-Security/AIUsageDiscovery/blob/main/LICENSE'
            IconUri      = ''
            ReleaseNotes = 'v1.1.1: Performance improvements and PowerShell 6+ compatibility fix.'
        }
    }
}
