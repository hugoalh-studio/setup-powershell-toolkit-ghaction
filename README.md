# Setup PowerShell Toolkit (GitHub Action)

![License](https://img.shields.io/static/v1?label=License&message=MIT&style=flat-square "License")
[![GitHub Repository](https://img.shields.io/badge/Repository-181717?logo=github&logoColor=ffffff&style=flat-square "GitHub Repository")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction)
[![GitHub Stars](https://img.shields.io/github/stars/hugoalh-studio/setup-powershell-toolkit-ghaction?label=Stars&logo=github&logoColor=ffffff&style=flat-square "GitHub Stars")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/stargazers)
[![GitHub Contributors](https://img.shields.io/github/contributors/hugoalh-studio/setup-powershell-toolkit-ghaction?label=Contributors&logo=github&logoColor=ffffff&style=flat-square "GitHub Contributors")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/graphs/contributors)
[![GitHub Issues](https://img.shields.io/github/issues-raw/hugoalh-studio/setup-powershell-toolkit-ghaction?label=Issues&logo=github&logoColor=ffffff&style=flat-square "GitHub Issues")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr-raw/hugoalh-studio/setup-powershell-toolkit-ghaction?label=Pull%20Requests&logo=github&logoColor=ffffff&style=flat-square "GitHub Pull Requests")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/pulls)
[![GitHub Discussions](https://img.shields.io/github/discussions/hugoalh-studio/setup-powershell-toolkit-ghaction?label=Discussions&logo=github&logoColor=ffffff&style=flat-square "GitHub Discussions")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/discussions)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/hugoalh-studio/setup-powershell-toolkit-ghaction?label=Grade&logo=codefactor&logoColor=ffffff&style=flat-square "CodeFactor Grade")](https://www.codefactor.io/repository/github/hugoalh-studio/setup-powershell-toolkit-ghaction)

| **Releases** | **Latest** (![GitHub Latest Release Date](https://img.shields.io/github/release-date/hugoalh-studio/setup-powershell-toolkit-ghaction?label=&style=flat-square "GitHub Latest Release Date")) | **Pre** (![GitHub Latest Pre-Release Date](https://img.shields.io/github/release-date-pre/hugoalh-studio/setup-powershell-toolkit-ghaction?label=&style=flat-square "GitHub Latest Pre-Release Date")) |
|:-:|:-:|:-:|
| [![GitHub](https://img.shields.io/badge/GitHub-181717?logo=github&logoColor=ffffff&style=flat-square "GitHub")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/releases) ![GitHub Total Downloads](https://img.shields.io/github/downloads/hugoalh-studio/setup-powershell-toolkit-ghaction/total?label=&style=flat-square "GitHub Total Downloads") | ![GitHub Latest Release Version](https://img.shields.io/github/release/hugoalh-studio/setup-powershell-toolkit-ghaction?sort=semver&label=&style=flat-square "GitHub Latest Release Version") | ![GitHub Latest Pre-Release Version](https://img.shields.io/github/release/hugoalh-studio/setup-powershell-toolkit-ghaction?include_prereleases&sort=semver&label=&style=flat-square "GitHub Latest Pre-Release Version") |

## 📝 Description

A GitHub Action to setup PowerShell Gallery, PowerShellGet, and PowerShell module `hugoalh.GitHubActionsToolkit` ([GitHub](https://github.com/hugoalh-studio/ghactions-toolkit-powershell))([PowerShell Gallery](https://www.powershellgallery.com/packages/hugoalh.GitHubActionsToolkit)).

## 📚 Documentation

> **⚠ Important:** This documentation is v1.2.0 based; To view other version's documentation, please visit the [versions list](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/tags) and select the correct version.

### Getting Started

- GitHub Actions Runner >= v2.303.0
  - PowerShell >= v7.2.0

```yml
jobs:
  job_id:
    runs-on: "________" # Any
    steps:
      - uses: "hugoalh-studio/setup-powershell-toolkit-ghaction@<Version>"
```

### 📥 Input

#### `toolkit_setup`

**\[Optional\]** `<Boolean = True>` Whether to setup PowerShell module `hugoalh.GitHubActionsToolkit`. When this input is `False`, will ignore inputs:

- [`toolkit_version`](#toolkit_version)
- [`toolkit_allowprerelease`](#toolkit_allowprerelease)

#### `toolkit_version`

**\[Optional\]** `<SemVer = "1.4.1">` PowerShell module `hugoalh.GitHubActionsToolkit` target version; Default value will always change to the latest stable version.

| **Versions** | **`toolkit_version` Default Value** |
|:-:|:-:|
| v1.2.1 | `"1.4.1"` |
| v1.2.0 | `"1.4.0"` |
| v1.1.0 | `"1.3.2"` |
| v1.0.1 | `"1.2.3"` |
| v1.0.0 | `"1.2.1"` |

#### `toolkit_allowprerelease`

**\[Optional\]** `<Boolean = False>` Whether to allow PowerShell module `hugoalh.GitHubActionsToolkit` target pre release version.

### 📤 Output

*N/A*

### Example

```yml
jobs:
  job_id:
    name: "Hello World"
    runs-on: "ubuntu-latest"
    steps:
      - uses: "hugoalh-studio/setup-powershell-toolkit-ghaction@v1.2.1"
      - run: |
          Import-Module -Name 'hugoalh.GitHubActionsToolkit' -Scope 'Local'
          Write-GitHubActionsNotice -Message 'Hello, world!'
        shell: "pwsh"
```

### Guide

#### GitHub Actions

- [Enabling debug logging](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
