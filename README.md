<p align="center">
  <img src="images/peach-logo.png" alt="Peach Security" width="100"/>
</p>

<h1 align="center">PeachSecurity.AIUsageDiscovery</h1>

<p align="center">
  <strong>A lightweight PowerShell tool for MSPs to discover employee AI usage across ChatGPT, Claude, Gemini, Perplexity, and other AI apps.</strong>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/PeachSecurity.AIUsageDiscovery"><img src="https://img.shields.io/powershellgallery/v/PeachSecurity.AIUsageDiscovery?style=flat-square&label=PSGallery&color=blue" alt="PowerShell Gallery Version"></a>
  <a href="https://www.powershellgallery.com/packages/PeachSecurity.AIUsageDiscovery"><img src="https://img.shields.io/powershellgallery/dt/PeachSecurity.AIUsageDiscovery?style=flat-square&label=Downloads&color=green" alt="Downloads"></a>
  <a href="https://github.com/Peach-Security/AIUsageDiscovery/stargazers"><img src="https://img.shields.io/github/stars/Peach-Security/AIUsageDiscovery?style=flat-square&color=yellow" alt="GitHub Stars"></a>
  <a href="https://github.com/Peach-Security/AIUsageDiscovery/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Peach-Security/AIUsageDiscovery?style=flat-square" alt="License"></a>
</p>

---

## 🎯 At a Glance

- 🔎 **Detects AI usage** across Chrome, Edge, Firefox, and Safari
- 👥 **Scans all users** on Windows/macOS with `-AllUsers` flag
- 🛡️ **Zero data leaves the machine** — 100% local processing
- ⚡ **Fast MSP onboarding** — run one command, get instant visibility
- 📦 **Flexible output** — JSON, CSV, Markdown, or PowerShell objects
- 📊 **Timeline charts** — visualize AI usage trends over time

---

## 🚀 Quick Start

### Install from PowerShell Gallery

```powershell
Install-Module -Name PeachSecurity.AIUsageDiscovery -Scope CurrentUser
```

### Run a scan

```powershell
Get-AIUsageDiscovery
```

### Export reports for QBR

```powershell
Get-AIUsageDiscovery -ExportJson -ExportCsv -ExportMarkdown -OutputPath "./Reports"
```

---

## 📋 Sample Output

```
    ____                 __       _____                      _ __       
   / __ \___  ____ _____/ /_     / ___/___  _______  _______(_) /___  __
  / /_/ / _ \/ __ `/ __/ __ \    \__ \/ _ \/ ___/ / / / ___/ / __/ / / /
 / ____/  __/ /_/ / /_/ / / /   ___/ /  __/ /__/ /_/ / /  / / /_/ /_/ / 
/_/    \___/\__,_/\__/_/ /_/   /____/\___/\___/\__,_/_/  /_/\__/\__, /  
                                                              /____/   

  ╔═══════════════════════════════════════════════════════════════════╗
  ║            FREE TOOLS FRIDAY - AI Usage Discovery                 ║
  ╚═══════════════════════════════════════════════════════════════════╝

    Machine:        CLIENT-PC
    Scan Time:      2025-01-15 10:30:00
    Period:         Last 90 days
    Scope:          Current User

    Total Findings: 127
    Unique Tools:   8

  ┌─────────────────────────────────────────────────────────────────┐
  │  DETECTED AI TOOLS                                              │
  └─────────────────────────────────────────────────────────────────┘
    ► ChatGPT
    ► Claude
    ► Microsoft Copilot
    ► Google Gemini
    ► Perplexity
    ► Cursor
    ► Midjourney
    ► GitHub Copilot
```

### JSON Export Sample

```json
[
  {
    "Browser": "Chrome",
    "Username": "jsmith",
    "Tool": "ChatGPT",
    "Category": "Generative AI",
    "Url": "https://chat.openai.com/",
    "Timestamp": "2025-01-14T09:15:00Z"
  },
  {
    "Browser": "Edge",
    "Username": "jsmith",
    "Tool": "Claude",
    "Category": "Generative AI",
    "Url": "https://claude.ai/chat",
    "Timestamp": "2025-01-14T11:30:00Z"
  }
]
```

---

## 🔧 How It Works

```
┌──────────────────┐     ┌─────────────────────┐     ┌──────────────────┐
│  Browser History │ ──► │  AIUsageDiscovery   │ ──► │   Local Report   │
│  Chrome / Edge   │     │  Pattern Matching   │     │  JSON/CSV/MD     │
│  Firefox/Safari  │     │  70+ AI Tools       │     │  (stays local)   │
└──────────────────┘     └─────────────────────┘     └──────────────────┘
```

The script scans browser history databases locally and matches URLs against 70+ known AI tool patterns including:

| Category | Tools Detected |
|----------|----------------|
| **Generative AI** | ChatGPT, Claude, Gemini, Copilot, Perplexity, Grok, DeepSeek |
| **Code AI** | GitHub Copilot, Cursor, Codeium, Tabnine, Amazon CodeWhisperer |
| **Image AI** | DALL-E, Midjourney, Stable Diffusion, Adobe Firefly, Leonardo |
| **Audio/Video AI** | ElevenLabs, Runway, Synthesia, Suno, HeyGen |
| **Business AI** | Jasper, Copy.ai, Grammarly, Otter.ai, Tome |
| **Research AI** | Hugging Face, Kaggle, Elicit, Consensus, ChatPDF |

---

## 🛠 Commands

### Get-AIUsageDiscovery

Main scanning command with full output and export options.

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

### Get-AIUsageSummary

Quick summary with timeline visualization.

| Parameter | Description |
|-----------|-------------|
| `-Detailed` | Show detailed breakdown with usage timeline chart |
| `-DaysBack <int>` | Days of history to scan (default: 30) |

---

## 🔒 Security & Privacy

<table>
<tr>
<td>✅</td>
<td><strong>100% Local Processing</strong> — All scanning happens on the endpoint. Nothing is uploaded.</td>
</tr>
<tr>
<td>✅</td>
<td><strong>No Telemetry</strong> — Zero data is transmitted to Peach Security or any third party.</td>
</tr>
<tr>
<td>✅</td>
<td><strong>Open Source</strong> — Full source code available for security audit.</td>
</tr>
<tr>
<td>✅</td>
<td><strong>MIT Licensed</strong> — Use freely in your MSP practice.</td>
</tr>
</table>

> **This script reads browser history locally and outputs a report locally. No network calls are made. No data leaves the machine.**

---

## 💼 MSP Use Cases

### Pre-Sales Discovery
Run a quick scan during prospect meetings to demonstrate AI exposure:
```powershell
Get-AIUsageSummary -Detailed
```

### QBR Reporting
Generate professional reports showing AI tool adoption trends:
```powershell
Get-AIUsageDiscovery -AllUsers -ExportMarkdown -OutputPath "C:\QBR\ClientName"
```

### Compliance Assessment
Document Shadow AI usage for security assessments:
```powershell
Get-AIUsageDiscovery -AllUsers -ExportJson -ExportCsv -DaysBack 180
```

### Multi-Tenant Scanning
Deploy via RMM to scan all endpoints across client environments.

---

## 🧪 Testing

```powershell
Invoke-Pester -Path .\tests
```

---

## 🗺 Roadmap

- [x] Multi-user scanning (`-AllUsers`)
- [x] Timeline usage charts
- [x] Safari support (macOS)
- [ ] Configurable AI tool patterns
- [ ] Browser profile selection
- [ ] RMM deployment scripts
- [ ] Clipboard/file analysis (opt-in)

---

## 🔍 Keywords

This tool helps MSPs with **shadow AI detection**, **employee AI usage discovery**, and **AI security assessments**. It provides **browser AI activity scanning** for compliance and governance. Perfect for MSPs needing **AI DLP visibility**, **AI compliance tools**, and **automated AI usage insights** across client environments. Supports **ChatGPT detection**, **Claude monitoring**, **Copilot discovery**, and 70+ other AI applications.

---

## ❤️ Part of Free Tools Friday

This module is part of **Free Tools Friday**, a weekly release series for MSPs by Peach Security.

<p align="center">
  <a href="https://github.com/Peach-Security/free-tools-friday">📦 Full Tool Catalog</a> •
  <a href="https://peachsecurity.io">🍑 Learn More</a> •
  <a href="https://www.peachsecurity.io/#waitlist">📋 Join the Waitlist</a>
</p>

---

## 🚀 Want More?

**Need real-time AI monitoring, AI DLP, tenant-wide reporting, and automated insights?**

<p align="center">
  <a href="https://peachsecurity.io/free-tools-friday">
    <img src="https://img.shields.io/badge/Try%20Peach%20Security-MSP%20AI%20Platform-ff6b6b?style=for-the-badge" alt="Try Peach Security">
  </a>
</p>

Peach Security provides enterprise-grade AI visibility and control for MSPs:
- 🔴 Real-time AI usage alerts
- 📊 Tenant-wide dashboards
- 🛡️ AI DLP policy enforcement
- 📈 Automated compliance reports

👉 **[peachsecurity.io/free-tools-friday](https://peachsecurity.io/free-tools-friday)**

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

<p align="center">
  <sub>Built with ❤️ by <a href="https://peachsecurity.io">Peach Security</a> for the MSP community</sub>
</p>
