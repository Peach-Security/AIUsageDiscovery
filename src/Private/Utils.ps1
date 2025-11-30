# Utils.ps1 - Utility functions for AI Usage Discovery

function Test-IsElevated {
    <#
    .SYNOPSIS
    Check if the current session has elevated/admin permissions.

    .DESCRIPTION
    Returns $true if running as Administrator (Windows) or root (macOS/Linux).
    #>
    [CmdletBinding()]
    param()

    $isWindows = $PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows -or $PSVersionTable.PSVersion.Major -lt 6
    
    if ($isWindows) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else {
        # macOS/Linux: check if running as root
        return (id -u) -eq 0
    }
}

function Get-AllUserPaths {
    <#
    .SYNOPSIS
    Get home directory paths for all users on the system.

    .DESCRIPTION
    Returns an array of user home directories for Windows, macOS, or Linux.
    Requires elevated permissions to access other users' directories.
    #>
    [CmdletBinding()]
    param()

    $isWindows = $PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows -or $PSVersionTable.PSVersion.Major -lt 6
    $isMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
    $isLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux

    $userPaths = @()

    if ($isWindows) {
        $usersRoot = "$env:SystemDrive\Users"
        $excludedDirs = @('Public', 'Default', 'Default User', 'All Users')
        
        Get-ChildItem -Path $usersRoot -Directory -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -notin $excludedDirs -and -not $_.Name.EndsWith('.') } |
            ForEach-Object {
                $userPaths += @{
                    Username = $_.Name
                    HomePath = $_.FullName
                    LocalAppData = Join-Path $_.FullName 'AppData\Local'
                    RoamingAppData = Join-Path $_.FullName 'AppData\Roaming'
                }
            }
    }
    elseif ($isMacOS) {
        $usersRoot = '/Users'
        $excludedDirs = @('Shared', 'Guest')
        
        Get-ChildItem -Path $usersRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notin $excludedDirs -and -not $_.Name.StartsWith('.') } |
            ForEach-Object {
                $userPaths += @{
                    Username = $_.Name
                    HomePath = $_.FullName
                }
            }
    }
    elseif ($isLinux) {
        $usersRoot = '/home'
        
        Get-ChildItem -Path $usersRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { -not $_.Name.StartsWith('.') } |
            ForEach-Object {
                $userPaths += @{
                    Username = $_.Name
                    HomePath = $_.FullName
                }
            }
        
        # Also check /root for root user
        if (Test-Path '/root') {
            $userPaths += @{
                Username = 'root'
                HomePath = '/root'
            }
        }
    }

    return $userPaths
}

function Get-AIToolPatterns {
    <#
    .SYNOPSIS
    Returns a comprehensive hashtable of AI tool URL patterns organized by category.

    .DESCRIPTION
    Provides URL pattern matching rules for detecting AI tool usage in browser history.
    Each pattern includes the tool name, category, and URL regex pattern.
    #>
    [CmdletBinding()]
    param()

    return @(
        # Generative AI - Chat & Text
        @{ Name = 'ChatGPT'; Category = 'Generative AI'; Pattern = 'chat\.openai\.com|chatgpt\.com' }
        @{ Name = 'Claude'; Category = 'Generative AI'; Pattern = 'claude\.ai' }
        @{ Name = 'Google Gemini'; Category = 'Generative AI'; Pattern = 'gemini\.google\.com|bard\.google\.com' }
        @{ Name = 'Microsoft Copilot'; Category = 'Generative AI'; Pattern = 'copilot\.microsoft\.com|bing\.com/chat' }
        @{ Name = 'Perplexity'; Category = 'Generative AI'; Pattern = 'perplexity\.ai' }
        @{ Name = 'Poe'; Category = 'Generative AI'; Pattern = 'poe\.com' }
        @{ Name = 'Character.AI'; Category = 'Generative AI'; Pattern = 'character\.ai|beta\.character\.ai' }
        @{ Name = 'Pi.ai'; Category = 'Generative AI'; Pattern = 'pi\.ai' }
        @{ Name = 'You.com'; Category = 'Generative AI'; Pattern = 'you\.com' }
        @{ Name = 'Inflection AI'; Category = 'Generative AI'; Pattern = 'inflection\.ai' }
        @{ Name = 'Anthropic Console'; Category = 'Generative AI'; Pattern = 'console\.anthropic\.com' }
        @{ Name = 'OpenAI Platform'; Category = 'Generative AI'; Pattern = 'platform\.openai\.com' }
        @{ Name = 'Mistral AI'; Category = 'Generative AI'; Pattern = 'chat\.mistral\.ai|mistral\.ai' }
        @{ Name = 'Cohere'; Category = 'Generative AI'; Pattern = 'coral\.cohere\.com|cohere\.com' }
        @{ Name = 'AI21 Labs'; Category = 'Generative AI'; Pattern = 'ai21\.com|studio\.ai21\.com' }
        @{ Name = 'DeepSeek'; Category = 'Generative AI'; Pattern = 'chat\.deepseek\.com|deepseek\.com' }
        @{ Name = 'Grok'; Category = 'Generative AI'; Pattern = 'grok\.x\.ai|x\.com/i/grok' }
        @{ Name = 'Meta AI'; Category = 'Generative AI'; Pattern = 'meta\.ai' }

        # Code AI - Development Tools
        @{ Name = 'GitHub Copilot'; Category = 'Code AI'; Pattern = 'github\.com/features/copilot|copilot\.github\.com' }
        @{ Name = 'Cursor'; Category = 'Code AI'; Pattern = 'cursor\.sh|cursor\.com' }
        # Note: Replit removed - it's a general coding platform, AI features can't be distinguished by URL
        @{ Name = 'Codeium'; Category = 'Code AI'; Pattern = 'codeium\.com' }
        @{ Name = 'Tabnine'; Category = 'Code AI'; Pattern = 'tabnine\.com' }
        @{ Name = 'Amazon CodeWhisperer'; Category = 'Code AI'; Pattern = 'aws\.amazon\.com/codewhisperer|codewhisperer\.aws' }
        @{ Name = 'Sourcegraph Cody'; Category = 'Code AI'; Pattern = 'sourcegraph\.com/cody|about\.sourcegraph\.com' }
        @{ Name = 'Phind'; Category = 'Code AI'; Pattern = 'phind\.com' }
        @{ Name = 'BlackBox AI'; Category = 'Code AI'; Pattern = 'blackbox\.ai' }
        @{ Name = 'AskCodi'; Category = 'Code AI'; Pattern = 'askcodi\.com' }
        @{ Name = 'Pieces'; Category = 'Code AI'; Pattern = 'pieces\.app' }

        # Image AI - Image Generation
        @{ Name = 'DALL-E'; Category = 'Image AI'; Pattern = 'labs\.openai\.com|openai\.com/dall-e' }
        @{ Name = 'Midjourney'; Category = 'Image AI'; Pattern = 'midjourney\.com' }
        @{ Name = 'Stable Diffusion'; Category = 'Image AI'; Pattern = 'stability\.ai|dreamstudio\.ai|stablediffusionweb\.com' }
        @{ Name = 'Leonardo.AI'; Category = 'Image AI'; Pattern = 'leonardo\.ai|app\.leonardo\.ai' }
        @{ Name = 'Adobe Firefly'; Category = 'Image AI'; Pattern = 'firefly\.adobe\.com|adobe\.com/products/firefly' }
        @{ Name = 'Ideogram'; Category = 'Image AI'; Pattern = 'ideogram\.ai' }
        @{ Name = 'Playground AI'; Category = 'Image AI'; Pattern = 'playground\.ai|playgroundai\.com' }
        @{ Name = 'NightCafe'; Category = 'Image AI'; Pattern = 'nightcafe\.studio' }
        @{ Name = 'Canva AI'; Category = 'Image AI'; Pattern = 'canva\.com/ai' }
        @{ Name = 'Microsoft Designer'; Category = 'Image AI'; Pattern = 'designer\.microsoft\.com' }
        @{ Name = 'Bing Image Creator'; Category = 'Image AI'; Pattern = 'bing\.com/images/create|bing\.com/create' }
        @{ Name = 'Craiyon'; Category = 'Image AI'; Pattern = 'craiyon\.com' }
        @{ Name = 'Lexica'; Category = 'Image AI'; Pattern = 'lexica\.art' }
        @{ Name = 'Flux AI'; Category = 'Image AI'; Pattern = 'flux\.ai|fal\.ai/models/flux' }

        # Audio/Video AI - Media Generation
        @{ Name = 'ElevenLabs'; Category = 'Audio/Video AI'; Pattern = 'elevenlabs\.io|beta\.elevenlabs\.io' }
        @{ Name = 'Runway'; Category = 'Audio/Video AI'; Pattern = 'runwayml\.com|app\.runwayml\.com' }
        @{ Name = 'Synthesia'; Category = 'Audio/Video AI'; Pattern = 'synthesia\.io' }
        @{ Name = 'Descript'; Category = 'Audio/Video AI'; Pattern = 'descript\.com' }
        @{ Name = 'HeyGen'; Category = 'Audio/Video AI'; Pattern = 'heygen\.com' }
        @{ Name = 'Murf AI'; Category = 'Audio/Video AI'; Pattern = 'murf\.ai' }
        @{ Name = 'Lumen5'; Category = 'Audio/Video AI'; Pattern = 'lumen5\.com' }
        @{ Name = 'Pictory'; Category = 'Audio/Video AI'; Pattern = 'pictory\.ai' }
        @{ Name = 'Opus Clip'; Category = 'Audio/Video AI'; Pattern = 'opus\.pro' }
        @{ Name = 'Suno AI'; Category = 'Audio/Video AI'; Pattern = 'suno\.ai|app\.suno\.ai' }
        @{ Name = 'Udio'; Category = 'Audio/Video AI'; Pattern = 'udio\.com' }
        @{ Name = 'Pika Labs'; Category = 'Audio/Video AI'; Pattern = 'pika\.art' }
        @{ Name = 'Sora'; Category = 'Audio/Video AI'; Pattern = 'openai\.com/sora' }

        # Business AI - Productivity & Writing
        # Note: Notion AI removed - it's integrated into notion.so and can't be distinguished from regular Notion usage
        @{ Name = 'Jasper'; Category = 'Business AI'; Pattern = 'jasper\.ai' }
        @{ Name = 'Copy.ai'; Category = 'Business AI'; Pattern = 'copy\.ai' }
        @{ Name = 'Otter.ai'; Category = 'Business AI'; Pattern = 'otter\.ai' }
        @{ Name = 'Grammarly'; Category = 'Business AI'; Pattern = 'grammarly\.com|app\.grammarly\.com' }
        @{ Name = 'Writesonic'; Category = 'Business AI'; Pattern = 'writesonic\.com' }
        @{ Name = 'Rytr'; Category = 'Business AI'; Pattern = 'rytr\.me' }
        @{ Name = 'Wordtune'; Category = 'Business AI'; Pattern = 'wordtune\.com' }
        @{ Name = 'QuillBot'; Category = 'Business AI'; Pattern = 'quillbot\.com' }
        @{ Name = 'Tome'; Category = 'Business AI'; Pattern = 'tome\.app' }
        @{ Name = 'Beautiful.ai'; Category = 'Business AI'; Pattern = 'beautiful\.ai' }
        @{ Name = 'Gamma'; Category = 'Business AI'; Pattern = 'gamma\.app' }
        @{ Name = 'Mem.ai'; Category = 'Business AI'; Pattern = 'mem\.ai' }
        @{ Name = 'Fireflies.ai'; Category = 'Business AI'; Pattern = 'fireflies\.ai' }
        @{ Name = 'Krisp'; Category = 'Business AI'; Pattern = 'krisp\.ai' }
        @{ Name = 'Fathom'; Category = 'Business AI'; Pattern = 'fathom\.video' }
        @{ Name = 'tl;dv'; Category = 'Business AI'; Pattern = 'tldv\.io' }

        # Research & Data AI
        @{ Name = 'HuggingFace'; Category = 'Research AI'; Pattern = 'huggingface\.co' }
        @{ Name = 'Weights & Biases'; Category = 'Research AI'; Pattern = 'wandb\.ai' }
        @{ Name = 'Kaggle'; Category = 'Research AI'; Pattern = 'kaggle\.com' }
        @{ Name = 'Papers with Code'; Category = 'Research AI'; Pattern = 'paperswithcode\.com' }
        @{ Name = 'Semantic Scholar'; Category = 'Research AI'; Pattern = 'semanticscholar\.org' }
        @{ Name = 'Elicit'; Category = 'Research AI'; Pattern = 'elicit\.org|elicit\.com' }
        @{ Name = 'Consensus'; Category = 'Research AI'; Pattern = 'consensus\.app' }
        @{ Name = 'Scite.ai'; Category = 'Research AI'; Pattern = 'scite\.ai' }
        @{ Name = 'Connected Papers'; Category = 'Research AI'; Pattern = 'connectedpapers\.com' }
        @{ Name = 'ChatPDF'; Category = 'Research AI'; Pattern = 'chatpdf\.com' }
        @{ Name = 'SciSpace'; Category = 'Research AI'; Pattern = 'scispace\.com|typeset\.io' }
    )
}

function Get-BrowserProfilePaths {
    <#
    .SYNOPSIS
    Returns browser profile paths based on the current operating system.

    .DESCRIPTION
    Detects the current OS and returns appropriate paths for Chrome, Edge, Firefox,
    and Safari browser history database locations.

    .PARAMETER Browser
    The browser to get paths for: Chrome, Edge, Firefox, or Safari.

    .PARAMETER AllUsers
    Scan all users on the system instead of just the current user.
    Requires elevated/admin permissions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Chrome', 'Edge', 'Firefox', 'Safari')]
        [string] $Browser,

        [switch] $AllUsers
    )

    $paths = @()
    $isWindows = $PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows -or $PSVersionTable.PSVersion.Major -lt 6
    $isMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
    $isLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux

    # Determine which users to scan
    if ($AllUsers) {
        $userContexts = Get-AllUserPaths
        Write-Verbose "AllUsers mode: Found $($userContexts.Count) user(s) to scan"
    }
    else {
        # Current user only
        $currentUsername = if ($isWindows) { $env:USERNAME } else { $env:USER }
        $userContexts = @(
            @{
                Username = $currentUsername
                HomePath = if ($isWindows) { "$env:USERPROFILE" } else { $HOME }
                LocalAppData = if ($isWindows) { $env:LOCALAPPDATA } else { $null }
                RoamingAppData = if ($isWindows) { $env:APPDATA } else { $null }
            }
        )
    }

    foreach ($userCtx in $userContexts) {
        $username = $userCtx.Username
        $homePath = $userCtx.HomePath

        switch ($Browser) {
            'Chrome' {
                if ($isWindows) {
                    $basePath = Join-Path $userCtx.LocalAppData 'Google\Chrome\User Data'
                }
                elseif ($isMacOS) {
                    $basePath = Join-Path $homePath 'Library/Application Support/Google/Chrome'
                }
                elseif ($isLinux) {
                    $basePath = Join-Path $homePath '.config/google-chrome'
                }
                else {
                    Write-Warning "Unsupported OS for Chrome detection"
                    continue
                }

                # Use try/catch to handle access denied errors silently
                try {
                    if (Test-Path $basePath -ErrorAction Stop) {
                        # Get Default and all Profile directories
                        $profiles = @('Default') + @(Get-ChildItem -Path $basePath -Directory -Filter 'Profile *' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
                        foreach ($profile in $profiles) {
                            $historyPath = Join-Path $basePath "$profile/History"
                            if (Test-Path $historyPath -ErrorAction SilentlyContinue) {
                                $paths += @{
                                    Username    = $username
                                    ProfileName = $profile
                                    HistoryPath = $historyPath
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Cannot access Chrome data for user: $username (Access denied)"
                }
            }

            'Edge' {
                if ($isWindows) {
                    $basePath = Join-Path $userCtx.LocalAppData 'Microsoft\Edge\User Data'
                }
                elseif ($isMacOS) {
                    $basePath = Join-Path $homePath 'Library/Application Support/Microsoft Edge'
                }
                elseif ($isLinux) {
                    $basePath = Join-Path $homePath '.config/microsoft-edge'
                }
                else {
                    Write-Warning "Unsupported OS for Edge detection"
                    continue
                }

                try {
                    if (Test-Path $basePath -ErrorAction Stop) {
                        $profiles = @('Default') + @(Get-ChildItem -Path $basePath -Directory -Filter 'Profile *' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
                        foreach ($profile in $profiles) {
                            $historyPath = Join-Path $basePath "$profile/History"
                            if (Test-Path $historyPath -ErrorAction SilentlyContinue) {
                                $paths += @{
                                    Username    = $username
                                    ProfileName = $profile
                                    HistoryPath = $historyPath
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Cannot access Edge data for user: $username (Access denied)"
                }
            }

            'Firefox' {
                if ($isWindows) {
                    $basePath = Join-Path $userCtx.RoamingAppData 'Mozilla\Firefox\Profiles'
                }
                elseif ($isMacOS) {
                    $basePath = Join-Path $homePath 'Library/Application Support/Firefox/Profiles'
                }
                elseif ($isLinux) {
                    $basePath = Join-Path $homePath '.mozilla/firefox'
                }
                else {
                    Write-Warning "Unsupported OS for Firefox detection"
                    continue
                }

                try {
                    if (Test-Path $basePath -ErrorAction Stop) {
                        # Firefox profiles have random prefixes like "abc123.default-release"
                        $profileDirs = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue
                        foreach ($profileDir in $profileDirs) {
                            $placesPath = Join-Path $profileDir.FullName 'places.sqlite'
                            if (Test-Path $placesPath -ErrorAction SilentlyContinue) {
                                $paths += @{
                                    Username    = $username
                                    ProfileName = $profileDir.Name
                                    HistoryPath = $placesPath
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Cannot access Firefox data for user: $username (Access denied)"
                }
            }

            'Safari' {
                # Safari is only available on macOS
                if (-not $isMacOS) {
                    Write-Verbose "Safari is only available on macOS"
                    continue
                }

                $historyPath = Join-Path $homePath 'Library/Safari/History.db'
                
                # Check if Safari folder is accessible (requires Full Disk Access)
                $safariFolder = Join-Path $homePath 'Library/Safari'
                try {
                    $null = Get-ChildItem -Path $safariFolder -ErrorAction Stop
                }
                catch {
                    Write-Warning "Safari requires Full Disk Access permission for user: $username"
                    Write-Warning "Grant access in: System Settings > Privacy & Security > Full Disk Access"
                    continue
                }

                if (Test-Path $historyPath) {
                    $paths += @{
                        Username    = $username
                        ProfileName = 'Default'
                        HistoryPath = $historyPath
                    }
                }
            }
        }
    }

    return $paths
}

function Invoke-SQLiteQuery {
    <#
    .SYNOPSIS
    Executes a SQLite query against a database file.

    .DESCRIPTION
    Copies the database to a temp location (to handle locked files) and executes the query.
    Uses System.Data.SQLite if available, otherwise falls back to sqlite3 CLI.

    .PARAMETER DatabasePath
    Path to the SQLite database file.

    .PARAMETER Query
    SQL query to execute.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $DatabasePath,

        [Parameter(Mandatory)]
        [string] $Query
    )

    if (-not (Test-Path $DatabasePath)) {
        Write-Warning "Database not found: $DatabasePath"
        return @()
    }

    # Copy to temp to avoid lock issues
    $tempDb = Join-Path ([System.IO.Path]::GetTempPath()) "aiusage_$(Get-Random).db"
    
    try {
        # Use shell copy on macOS/Linux to handle locked files better
        $isUnix = $PSVersionTable.PSVersion.Major -ge 6 -and ($IsMacOS -or $IsLinux)
        
        if ($isUnix) {
            # Use cp command which can copy locked files on Unix systems
            $copyResult = & cp "$DatabasePath" "$tempDb" 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to copy database: $copyResult"
            }
        }
        else {
            Copy-Item -Path $DatabasePath -Destination $tempDb -Force -ErrorAction Stop
        }
        Write-Verbose "Copied database to temp: $tempDb"

        # Try using sqlite3 CLI (commonly available)
        $sqlite3Path = $null
        
        # Check common locations
        $possiblePaths = @(
            'sqlite3'  # In PATH
            '/usr/bin/sqlite3'  # Linux/macOS
            '/opt/homebrew/bin/sqlite3'  # macOS Homebrew ARM
            '/usr/local/bin/sqlite3'  # macOS Homebrew Intel
            "$env:ProgramFiles\SQLite\sqlite3.exe"  # Windows
            "$env:LOCALAPPDATA\Programs\sqlite3\sqlite3.exe"  # Windows user install
        )

        foreach ($path in $possiblePaths) {
            if (Get-Command $path -ErrorAction SilentlyContinue) {
                $sqlite3Path = $path
                break
            }
        }

        if ($sqlite3Path) {
            Write-Verbose "Using sqlite3 CLI at: $sqlite3Path"
            $result = & $sqlite3Path -separator '|' -header $tempDb $Query 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "SQLite query failed: $result"
                return @()
            }

            # Parse the output into objects
            $lines = $result -split "`n" | Where-Object { $_ -match '\S' }
            if ($lines.Count -lt 2) {
                return @()
            }

            $headers = $lines[0] -split '\|'
            $objects = @()

            for ($i = 1; $i -lt $lines.Count; $i++) {
                $values = $lines[$i] -split '\|'
                $obj = @{}
                for ($j = 0; $j -lt $headers.Count; $j++) {
                    $obj[$headers[$j].Trim()] = if ($j -lt $values.Count) { $values[$j].Trim() } else { '' }
                }
                $objects += [PSCustomObject]$obj
            }

            return $objects
        }
        else {
            Write-Warning "sqlite3 not found. Please install SQLite CLI tools."
            Write-Warning "  macOS: brew install sqlite"
            Write-Warning "  Linux: sudo apt install sqlite3"
            Write-Warning "  Windows: Download from https://sqlite.org/download.html"
            return @()
        }
    }
    catch {
        Write-Warning "Failed to query database: $_"
        return @()
    }
    finally {
        # Cleanup temp file
        if (Test-Path $tempDb) {
            Remove-Item -Path $tempDb -Force -ErrorAction SilentlyContinue
        }
    }
}

function Convert-ChromiumTimestamp {
    <#
    .SYNOPSIS
    Converts Chromium/WebKit timestamp to DateTime.

    .DESCRIPTION
    Chromium uses microseconds since 1601-01-01 (Windows FILETIME epoch).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [long] $Timestamp
    )

    try {
        # Chromium timestamp is microseconds since 1601-01-01
        $epoch = [DateTime]::new(1601, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
        return $epoch.AddTicks($Timestamp * 10)
    }
    catch {
        return $null
    }
}

function Convert-FirefoxTimestamp {
    <#
    .SYNOPSIS
    Converts Firefox timestamp to DateTime.

    .DESCRIPTION
    Firefox uses microseconds since Unix epoch (1970-01-01).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [long] $Timestamp
    )

    try {
        $epoch = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
        return $epoch.AddTicks($Timestamp * 10)
    }
    catch {
        return $null
    }
}

function Convert-SafariTimestamp {
    <#
    .SYNOPSIS
    Converts Safari timestamp to DateTime.

    .DESCRIPTION
    Safari uses seconds since Mac absolute time epoch (2001-01-01).
    This is also known as Cocoa/Core Data timestamp.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [double] $Timestamp
    )

    try {
        # Mac absolute time epoch is 2001-01-01
        $epoch = [DateTime]::new(2001, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
        return $epoch.AddSeconds($Timestamp)
    }
    catch {
        return $null
    }
}

function Convert-ToReportFormat {
    <#
    .SYNOPSIS
    Convert AI usage findings into the desired report formats.

    .DESCRIPTION
    Formats scan results into JSON, CSV, or Markdown format.

    .PARAMETER ScanResults
    The scan results object from Invoke-AIUsageScan.

    .PARAMETER Format
    Output format: JSON, CSV, or Markdown.

    .PARAMETER OutputPath
    Optional path to save the report file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $ScanResults,

        [Parameter(Mandatory)]
        [ValidateSet('JSON', 'CSV', 'Markdown')]
        [string] $Format,

        [string] $OutputPath
    )

    $output = $null
    $extension = switch ($Format) {
        'JSON' { '.json' }
        'CSV' { '.csv' }
        'Markdown' { '.md' }
    }

    switch ($Format) {
        'JSON' {
            $jsonObject = @{
                machine    = $ScanResults.Machine
                scanTime   = $ScanResults.ScanTime.ToString('o')
                browsers   = @()
            }

            foreach ($browser in $ScanResults.Browsers.Keys) {
                $browserData = @{
                    name     = $browser
                    findings = @()
                }

                foreach ($finding in $ScanResults.Browsers[$browser]) {
                    $browserData.findings += @{
                        url       = $finding.Url
                        title     = $finding.Title
                        tool      = $finding.Tool
                        category  = $finding.Category
                        timestamp = if ($finding.Timestamp) { $finding.Timestamp.ToString('o') } else { $null }
                        username  = $finding.Username
                        profile   = $finding.Profile
                    }
                }

                $jsonObject.browsers += $browserData
            }

            $output = $jsonObject | ConvertTo-Json -Depth 10
        }

        'CSV' {
            $csvData = @()
            foreach ($browser in $ScanResults.Browsers.Keys) {
                foreach ($finding in $ScanResults.Browsers[$browser]) {
                    $csvData += [PSCustomObject]@{
                        Machine   = $ScanResults.Machine
                        ScanTime  = $ScanResults.ScanTime.ToString('o')
                        Username  = $finding.Username
                        Browser   = $browser
                        Profile   = $finding.Profile
                        Tool      = $finding.Tool
                        Category  = $finding.Category
                        Url       = $finding.Url
                        Title     = $finding.Title
                        Timestamp = if ($finding.Timestamp) { $finding.Timestamp.ToString('o') } else { '' }
                    }
                }
            }

            if ($csvData.Count -eq 0) {
                $output = "Machine,ScanTime,Username,Browser,Profile,Tool,Category,Url,Title,Timestamp"
            }
            else {
                $output = $csvData | ConvertTo-Csv -NoTypeInformation | Out-String
            }
        }

        'Markdown' {
            $sb = [System.Text.StringBuilder]::new()
            [void]$sb.AppendLine("# AI Usage Discovery Report")
            [void]$sb.AppendLine()
            [void]$sb.AppendLine("- **Machine**: $($ScanResults.Machine)")
            [void]$sb.AppendLine("- **Scan Time**: $($ScanResults.ScanTime.ToString('yyyy-MM-dd HH:mm:ss'))")
            [void]$sb.AppendLine()

            $totalFindings = 0
            foreach ($browser in $ScanResults.Browsers.Keys) {
                $totalFindings += $ScanResults.Browsers[$browser].Count
            }
            [void]$sb.AppendLine("- **Total Findings**: $totalFindings")
            [void]$sb.AppendLine()

            foreach ($browser in $ScanResults.Browsers.Keys | Sort-Object) {
                $findings = $ScanResults.Browsers[$browser]
                [void]$sb.AppendLine("## $browser ($($findings.Count) findings)")
                [void]$sb.AppendLine()

                if ($findings.Count -eq 0) {
                    [void]$sb.AppendLine("No AI tool usage detected.")
                    [void]$sb.AppendLine()
                    continue
                }

                # Group by category
                $byCategory = $findings | Group-Object -Property Category

                foreach ($categoryGroup in $byCategory | Sort-Object Name) {
                    [void]$sb.AppendLine("### $($categoryGroup.Name)")
                    [void]$sb.AppendLine()
                    [void]$sb.AppendLine("| User | Tool | URL | Timestamp |")
                    [void]$sb.AppendLine("|------|------|-----|-----------|")

                    foreach ($finding in $categoryGroup.Group | Sort-Object Username, Tool, Timestamp) {
                        $ts = if ($finding.Timestamp) { $finding.Timestamp.ToString('yyyy-MM-dd HH:mm') } else { 'N/A' }
                        $shortUrl = if ($finding.Url.Length -gt 50) { $finding.Url.Substring(0, 47) + '...' } else { $finding.Url }
                        [void]$sb.AppendLine("| $($finding.Username) | $($finding.Tool) | $shortUrl | $ts |")
                    }

                    [void]$sb.AppendLine()
                }
            }

            $output = $sb.ToString()
        }
    }

    # Save to file if OutputPath specified
    if ($OutputPath) {
        $fileName = "AIUsageReport_$($ScanResults.Machine)_$($ScanResults.ScanTime.ToString('yyyyMMdd_HHmmss'))$extension"
        $fullPath = Join-Path $OutputPath $fileName

        # Ensure directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }

        $output | Out-File -FilePath $fullPath -Encoding UTF8 -Force
        Write-Verbose "Report saved to: $fullPath"
        
        return @{
            Content  = $output
            FilePath = $fullPath
        }
    }

    return @{
        Content  = $output
        FilePath = $null
    }
}
