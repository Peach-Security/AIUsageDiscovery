# PeachSecurity.AIUsageDiscovery

**Discover Shadow AI usage on Windows/macOS endpoints in minutes.**

`PeachSecurity.AIUsageDiscovery` is a lightweight PowerShell module that identifies AI usage (ChatGPT, Gemini, Claude, Perplexity, Copilot, etc.) across Chrome, Edge, and Firefox.  
Developed for MSPs who need fast AI exposure assessments and QBR-ready reports.

Runs fully locally — no data leaves the device.

---

## ✨ Features

- 🔍 Scan **Chrome**, **Edge**, **Firefox**, and **Safari** (macOS) for AI usage
- 🧠 Detect Shadow AI (ChatGPT, Gemini, Claude, Perplexity, Copilot, etc.)
- 🏷 Categorize detected tools (Generative AI, Code AI, Image AI, Business AI, etc.)
- 👥 Scan **all users** on the system with `-AllUsers` (requires elevation)
- 📊 Export **JSON**, **CSV**, and **Markdown** reports
- 🔒 Privacy-first: everything stays on the device
- 🧩 Perfect pre-sales tool for MSP AI governance offerings

---

## 🚀 Installation

### Install from PowerShell Gallery (when published)

```powershell
Install-Module -Name PeachSecurity.AIUsageDiscovery
```

### Or run from source

```powershell
git clone https://github.com/Peach-Security/AIUsageDiscovery
Import-Module "$PWD/src/PeachSecurity.AIUsageDiscovery.psd1" -Force
```

---

## 📖 Usage

Run a full scan

```powershell
Get-AIUsageDiscovery
```

Export a QBR-ready report

```powershell
Get-AIUsageDiscovery \
  -AllBrowsers \
  -ExportJson \
  -ExportCsv \
  -ExportMarkdown \
  -OutputPath "C:\\Reports\\AI"
```

---

## 🧠 Supported Browsers
- Google Chrome
- Microsoft Edge
- Mozilla Firefox
- Safari (macOS only - requires Full Disk Access permission)

More can be added based on MSP feedback.

---

## 🔐 Privacy
- All processing happens locally
- No telemetry
- No external communication
- Code is fully open for MSP audit

---

## 🛠 Commands

### Get-AIUsageDiscovery

Main scanning command with full output and export options.

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `-AllBrowsers` | Scan all supported browsers (default) |
| `-Chrome` | Scan only Chrome |
| `-Edge` | Scan only Edge |
| `-Firefox` | Scan only Firefox |
| `-Safari` | Scan only Safari (macOS only) |
| `-AllUsers` | Scan all users on the system (requires elevation) |
| `-DaysBack <int>` | Days of history to scan (default: 90) |
| `-ExportJson` | Export results to JSON |
| `-ExportCsv` | Export results to CSV |
| `-ExportMarkdown` | Export results to Markdown |
| `-OutputPath <path>` | Output directory for exports |
| `-PassThru` | Return raw results object for pipeline |
| `-Verbose` | Show detailed progress |

**Examples:**

```powershell
# Basic scan (current user, all browsers)
Get-AIUsageDiscovery

# Scan specific browsers
Get-AIUsageDiscovery -Chrome -Edge -DaysBack 30

# Scan all users (requires admin/sudo)
Get-AIUsageDiscovery -AllUsers

# Export reports
Get-AIUsageDiscovery -ExportJson -ExportCsv -ExportMarkdown -OutputPath "./Reports"
```

### Get-AIUsageSummary

Quick summary output with optional detailed breakdown.

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `-ScanResults` | Scan results from pipeline (optional) |
| `-DaysBack <int>` | Days of history to scan (default: 30) |
| `-Detailed` | Show detailed breakdown by tool and category |

**Examples:**

```powershell
# Quick summary
Get-AIUsageSummary

# Detailed summary
Get-AIUsageSummary -Detailed -DaysBack 7

# Pipeline from full scan
Get-AIUsageDiscovery -PassThru | Get-AIUsageSummary -Detailed
```

---

## 🧪 Testing

```powershell
Invoke-Pester -Path .\tests
```

---

## 🗺 Roadmap
- v1.1: Improved heuristics
- v1.2: Optional clipboard analysis
- v1.3: Configurable AI tool list
- v1.4: Browser profile selection

---

## ❤️ Part of Peach Security’s Free Tools Friday

This module is part of Free Tools Friday, a weekly release series for MSPs.

👉 Full catalog: https://github.com/Peach-Security/free-tools-friday
👉 Learn more: https://peachsecurity.io
👉 Join the waitlist: https://peachsecurity.io/waitlist

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
