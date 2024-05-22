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
>   EOL("End Of Life")
>   Unstable --> Pre --> Release
>   subgraph Supported
>     Release -- Major = 0 --> Maintenance
>     Release -- Major > 0 --> LTS --> Maintenance
>   end
>   Maintenance --> EOL
> ```

| **Versions** | **Release Date** | **Long Term Support Date** | **End Of Life Date** |
|:-:|:-:|:-:|:-:|
| v2.X.X | 2024-01-17 | 2024-02-01 | *Unknown* |
| v1.X.X | *N/A* | 2023-09-01 | 2024-05-01 |

> **ℹ️ Note**
>
> - The date format is according to the specification ISO 8601.
> - Values in italic format are subject to change.
> - Versions which not in the list are also end of life.

## Report Vulnerabilities

You can report security vulnerabilities by [create security vulnerability report](https://github.com/hugoalh/hugoalh/blob/main/universal-guide/contributing.md#create-a-security-vulnerability-report).
