# Setup PowerShell Toolkit (GitHub Action)

[⚖️ MIT](./LICENSE.md)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/hugoalh-studio/setup-powershell-toolkit-ghaction?label=Grade&logo=codefactor&logoColor=ffffff&style=flat-square "CodeFactor Grade")](https://www.codefactor.io/repository/github/hugoalh-studio/setup-powershell-toolkit-ghaction)

|  | **Heat** | **Release - Latest** | **Release - Pre** |
|:-:|:-:|:-:|:-:|
| [![GitHub](https://img.shields.io/badge/GitHub-181717?logo=github&logoColor=ffffff&style=flat-square "GitHub")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction) | [![GitHub Stars](https://img.shields.io/github/stars/hugoalh-studio/setup-powershell-toolkit-ghaction?label=&logoColor=ffffff&style=flat-square "GitHub Stars")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/stargazers) \| ![GitHub Total Downloads](https://img.shields.io/github/downloads/hugoalh-studio/setup-powershell-toolkit-ghaction/total?label=&style=flat-square "GitHub Total Downloads") | ![GitHub Latest Release Version](https://img.shields.io/github/release/hugoalh-studio/setup-powershell-toolkit-ghaction?sort=semver&label=&style=flat-square "GitHub Latest Release Version") (![GitHub Latest Release Date](https://img.shields.io/github/release-date/hugoalh-studio/setup-powershell-toolkit-ghaction?label=&style=flat-square "GitHub Latest Release Date")) | ![GitHub Latest Pre-Release Version](https://img.shields.io/github/release/hugoalh-studio/setup-powershell-toolkit-ghaction?include_prereleases&sort=semver&label=&style=flat-square "GitHub Latest Pre-Release Version") (![GitHub Latest Pre-Release Date](https://img.shields.io/github/release-date-pre/hugoalh-studio/setup-powershell-toolkit-ghaction?label=&style=flat-square "GitHub Latest Pre-Release Date")) |

A GitHub Action to setup PowerShell module `hugoalh.GitHubActionsToolkit` ([GitHub](https://github.com/hugoalh-studio/ghactions-toolkit-powershell))([PowerShell Gallery](https://www.powershellgallery.com/packages/hugoalh.GitHubActionsToolkit)).

## 📓 Documentation

> **⚠️ Important:** This documentation is v1.4.0 based; To view other version's documentation, please visit the [versions list](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/tags) and select the correct version.

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

#### `sudo`

**(>= v1.5.0) \[Optional\]** `<Boolean = False>` Whether to execute this action in sudo mode on non-Windows environment. This must set to `True` in order to able install for all users on non-Windows environment (i.e.: when input [`scope`](#scope) is `"AllUsers"`).

#### `version`

**\[Optional\]** `<String = "Latest">` Target version, by Semantic Versioning (SemVer) 2.0.0 with optional modifier; Default to the latest version.

- **`Latest`:** Latest version
- **`<Ma.Mi.Pa-PR+Bu`:** Less than version `Ma.Mi.Pa-PR+Bu`
- **`<=Ma.Mi.Pa-PR+Bu`:** Less than or equal version `Ma.Mi.Pa-PR+Bu`
- **`Ma.Mi.Pa-PR+Bu` / `=Ma.Mi.Pa-PR+Bu`:** Equal version `Ma.Mi.Pa-PR+Bu`
- **`>=Ma.Mi.Pa-PR+Bu`:** Greater than or equal version `Ma.Mi.Pa-PR+Bu`
- **`>Ma.Mi.Pa-PR+Bu`:** Greater than version `Ma.Mi.Pa-PR+Bu`
- **`^Ma.Mi.Pa-PR+Bu`:** Between version `Ma.Mi.Pa-PR+Bu` and major equitant latest version
- **`~Ma.Mi.Pa-PR+Bu`:** Between version `Ma.Mi.Pa-PR+Bu` and minor equitant latest version

#### `allowprerelease`

**\[Optional\]** `<Boolean = False>` Whether to allow target pre release version.

#### `scope`

**(>= v1.5.0) \[Optional\]** `<String = "CurrentUser">` Installation scope.

- **`"AllUsers"`:** For all users. Also need to set input [`sudo`](#sudo) to `True`.
- **`"CurrentUser"`:** For current user.

#### `force`

**(>= v1.5.0) \[Optional\]** `<Boolean = False>` Whether to force install or reinstall target (pre release) version.

#### `keepsetting`

**\[Optional\]** `<Boolean = True>` Whether to keep the setting that modified by this action.

### 📤 Output

*N/A*

### Example

```yml
jobs:
  job_id:
    name: "Hello World"
    runs-on: "ubuntu-latest"
    steps:
      - name: "Setup PowerShell Toolkit"
        uses: "hugoalh-studio/setup-powershell-toolkit-ghaction@v1.5.0"
      - run: |
          Import-Module -Name 'hugoalh.GitHubActionsToolkit' -Scope 'Local'
          Write-GitHubActionsNotice -Message 'Hello, world!'
        shell: "pwsh"
```

### Guide

#### GitHub Actions

- [Enabling debug logging](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
