# Security Policy

## Supported Versions

> ```mermaid
> ---
> title: Versions Status Flow
> ---
> flowchart LR
>   Unstable("Unstable")
>   Pre("Pre Release")
>   Release("Release")
>   LTS("Long Term Support")
>   Maintenance("Maintenance")
>   EOL("End Of Life / Not Supported")
>   Unstable --> Pre
>   Pre --> Release
>   subgraph Support
>     Release -- Major = 0 --> Maintenance
>     Release -- Major > 0 --> LTS
>     LTS --> Maintenance
>   end
>   Maintenance --> EOL
> ```

| **Versions** | **Release Date** | **Long Term Support Date** | **End Of Life Date / Not Supported Date** |
|:-:|:-:|:-:|:-:|
| v2.X.X | 2024-01-17 | 2024-02-01 | *Unknown* |
| v1.X.X | *N/A* | 2023-09-01 | 2024-05-01 |

> **ℹ️ Note**
>
> - The date format is according to ISO 8601 standard.
> - Values in italic format are subject to change.
> - Versions which not in the list are also end of life.

## Report A Vulnerability

You can report a security vulnerability by [create a security vulnerability report](https://github.com/hugoalh/hugoalh/blob/main/universal-guide/contributing.md#create-a-security-vulnerability-report).
