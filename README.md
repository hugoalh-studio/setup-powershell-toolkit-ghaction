# Setup PowerShell Toolkit (GitHub Action)

[**⚖️** MIT](./LICENSE.md)

**🗂️**
[![GitHub: hugoalh-studio/setup-powershell-toolkit-ghaction](https://img.shields.io/badge/hugoalh--studio/setup--powershell--toolkit--ghaction-181717?logo=github&logoColor=ffffff&style=flat "GitHub: hugoalh-studio/setup-powershell-toolkit-ghaction")](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction)

**🆙** ![Latest Release Version](https://img.shields.io/github/release/hugoalh-studio/setup-powershell-toolkit-ghaction?sort=semver&color=2187C0&label=&style=flat "Latest Release Version") (![Latest Release Date](https://img.shields.io/github/release-date/hugoalh-studio/setup-powershell-toolkit-ghaction?color=2187C0&label=&style=flat "Latest Release Date"))

A GitHub Action to setup PowerShell module `hugoalh.GitHubActionsToolkit` ([GitHub](https://github.com/hugoalh-studio/ghactions-toolkit-powershell))([PowerShell Gallery](https://www.powershellgallery.com/packages/hugoalh.GitHubActionsToolkit)).

> [!IMPORTANT]
> This documentation is v2.0.0 based; To view other version's documentation, please visit the [versions list](https://github.com/hugoalh-studio/setup-powershell-toolkit-ghaction/tags) and select the correct version.

## 🎯 Target

- GitHub Actions Runner
  > **🛡️ Require Permission**
  >
  > *N/A*

  > **💽 Require Software**
  >
  > - PowerShell >= v7.2.0

## 🔰 Usage

### Composite Action

1. Import at the metadata (`action.yml`):
    ```yml
    runs:
      using: "composite"
      steps:
        - uses: "hugoalh-studio/setup-powershell-toolkit-ghaction@<Tag>"
    ```

### Workflow

1. Import at the workflow (`.github/workflows/<WorkflowName>.yml`):
    ```yml
    jobs:
      job_id:
        runs-on: "________" # Any
        steps:
          - uses: "hugoalh-studio/setup-powershell-toolkit-ghaction@<Tag>"
    ```

## 🧩 Input

> [!NOTE]
> All of the inputs are optional; Use this action without any input will default to install major equitant latest version of `2.1.0` for current user, and keep the setting that modified.

### `sudo`

`<Boolean = False>` Whether to execute in sudo mode on non-Windows environment. This must set to `True` in order to able install for all users on non-Windows environment (i.e.: when [input `scope`](#scope) is `"AllUsers"`).

### `version`

`<String = "^2.1.0">` Target version, by [Semantic Versioning (SemVer) 2.0.0](https://semver.org/spec/v2.0.0.html) with optional modifier; Default to major equitant latest version of `2.1.0`.

- **`"Latest"`:** Latest version
- **`"<1.2.3"`:** Less than this version
- **`"<=1.2.3"`:** Less than or equal to this version
- **`"1.2.3"` / `"=1.2.3"`:** Equal to this version
- **`">=1.2.3"`:** Greater than or equal to this version
- **`">1.2.3"`:** Greater than this version
- **`"^1.2.3"`:** Between this version and major equitant latest version
- **`"~1.2.3"`:** Between this version and minor equitant latest version

### `allowprerelease`

`<Boolean = False>` Whether to allow target pre release version.

### `scope`

`<String = "CurrentUser">` Installation scope.

- **`"AllUsers"`:** For all users. Also need to set [input `sudo`](#sudo) to `True` on non-Windows environment.
- **`"CurrentUser"`:** For current user.

### `force`

`<Boolean = False>` Whether to force install or reinstall target (pre release) version.

### `keepsetting`

`<Boolean = False>` Whether to keep the setting that modified.

## 🧩 Output

### `path`

`<String>` Path of the installation.

### `version`

`<SemVer>` Version of the installation.

## ✍️ Example

- ```yml
  jobs:
    job_id:
      name: "Hello World"
      runs-on: "ubuntu-latest"
      steps:
        - name: "Setup PowerShell Toolkit"
          uses: "hugoalh-studio/setup-powershell-toolkit-ghaction@v2.0.0"
        - run: |
            Import-Module -Name 'hugoalh.GitHubActionsToolkit' -Scope 'Local'
            Write-GitHubActionsNotice -Message 'Hello, world!'
          shell: "pwsh"
  ```

## 📚 Guide

- GitHub Actions
  - [Enabling debug logging](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
