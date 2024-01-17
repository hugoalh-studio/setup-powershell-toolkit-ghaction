#Requires -PSEdition Core -Version 7.2
$Script:ErrorActionPreference = 'Stop'
[Boolean]$IsDebugMode = $Env:RUNNER_DEBUG -ieq '1'
[RegEx]$RegExSemVerModifier = '^(?:[<>]=?|=|\^|~) *'
Function Resolve-TargetVersion {
	[CmdletBinding()]
	[OutputType([SemVer])]
	Param (
		[Parameter(Mandatory = $True, Position = 0)][AllowEmptyString()][String]$VersionModifier,
		[Parameter(Mandatory = $True, Position = 1)][SemVer]$VersionNumber,
		[Switch]$AllowPrerelease
	)
	[SemVer[]]$VersionsAvailable = Find-Module -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -Repository 'PSGallery' -AllowPrerelease:($AllowPrerelease.IsPresent) -Verbose:$IsDebugMode |
		ForEach-Object -Process { [SemVer]::Parse($_.Version) } |
		Sort-Object -Descending
	[String]$VersionsAvailableStringify = $VersionsAvailable |
		ForEach-Object -Process { $_.ToString() } |
		Join-String -Separator ', '
	Write-Host -Object "::debug::Versions Available [$($VersionsAvailable.Count)]: $VersionsAvailableStringify"
	$VersionResolve = $VersionsAvailable |
		Where-Object -FilterScript {
			[SemVer]$VersionAvailable = $_ # This reassign is necessary, as $_ in Switch is value of the switch!
			Switch ($VersionModifier) {
				'<' {
					$VersionAvailable -ilt $VersionNumber |
						Write-Output
					Break
				}
				'<=' {
					$VersionAvailable -ile $VersionNumber |
						Write-Output
					Break
				}
				'>=' {
					$VersionAvailable -ige $VersionNumber |
						Write-Output
					Break
				}
				'>' {
					$VersionAvailable -igt $VersionNumber |
						Write-Output
					Break
				}
				'^' {
					$VersionAvailable -ige $VersionNumber -and $VersionAvailable -ilt [SemVer]::Parse("$($VersionNumber.Major + 1).0.0") |
						Write-Output
					Break
				}
				'~' {
					$VersionAvailable -ige $VersionNumber -and $VersionAvailable -ilt [SemVer]::Parse("$($VersionNumber.Major).$($VersionNumber.Minor + 1).0") |
						Write-Output
					Break
				}
				Default {
					$VersionAvailable -ieq $VersionNumber |
						Write-Output
					Break
				}
			}
		} |
		Sort-Object -Descending |
		Select-Object -First 1
	If ($Null -ieq $VersionResolve) {
		throw "No available versions that fulfill the target version ``$($VersionModifier)$($VersionNumber.ToString())``! Only these versions are available: $VersionsAvailableStringify"
	}
	Write-Output -InputObject $VersionResolve
}
[Boolean]$InputAllowPreRelease = [Boolean]::Parse($Env:INPUT_ALLOWPRERELEASE)
[Boolean]$InputForce = [Boolean]::Parse($Env:INPUT_FORCE)
[Boolean]$InputKeepSetting = [Boolean]::Parse($Env:INPUT_KEEPSETTING)
[String]$InputScope = $Env:INPUT_SCOPE
[String]$InputVersionRaw = $Env:INPUT_VERSION
[Boolean]$InputUninstall = $InputVersionRaw -iin @('-', 'False', 'None', 'Uninstall')
[Boolean]$InputVersionLatest = $InputVersionRaw -iin @('*', 'Latest')
If (!$InputVersionLatest -and !$InputUninstall) {
	Try {
		[String]$InputVersionModifier = ($InputVersionRaw -imatch $RegExSemVerModifier) ? $Matches[0].Trim() : ''
		[SemVer]$InputVersionNumber = [SemVer]::Parse((($InputVersionRaw -imatch $RegExSemVerModifier) ? $InputVersionRaw -ireplace "^$([RegEx]::Escape($Matches[0]))", '' : $InputVersionRaw))
	}
	Catch {
		Write-Host -Object "::error::``$InputVersionRaw`` is not a valid version!"
		Exit 1
	}
}
$PSPackageProviderPowerShellGetMeta = Get-PackageProvider -Name 'PowerShellGet'
If (!($PSPackageProviderPowerShellGetMeta.Version -ge [Microsoft.PackageManagement.Internal.Utility.Versions.FourPartVersion]::Parse('2.2.5') -and $PSPackageProviderPowerShellGetMeta.Version -lt [Microsoft.PackageManagement.Internal.Utility.Versions.FourPartVersion]::Parse('3.0.0'))) {
	Write-Host -Object "::error::PowerShell package provider ``PowerShellGet`` is not compatible! Expect ``^2.2.5.0``; Current ``$($PSPackageProviderPowerShellGetMeta.Version.ToString())``."
	Exit 1
}
$PSRepositoryPSGalleryMeta = Get-PSRepository -Name 'PSGallery'
If ($Null -eq $PSRepositoryPSGalleryMeta) {
	Write-Host -Object '::error::PowerShell repository `PSGallery` is missing!'
	Exit 1
}
If ($PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
	Write-Host -Object 'Tweak PowerShell repository configuration.'
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' -Verbose:$IsDebugMode
}
Try {
	$ToolkitInstalledPrevious = Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease -ErrorAction 'SilentlyContinue'
	If ($InputUninstall) {
		$ToolkitInstalledPrevious |
			ForEach-Object -Process {
				Uninstall-Module -Name 'hugoalh.GitHubActionsToolkit' -RequiredVersion $_.Version -AllowPrerelease -Confirm:$False -Verbose:$IsDebugMode
			}
	}
	Else {
		[SemVer]$VersionResolve = Resolve-TargetVersion -VersionModifier ($InputVersionLatest ? '>=' : $InputVersionModifier) -VersionNumber ($InputVersionLatest ? [SemVer]::Parse('2.1.0') : $InputVersionNumber) -AllowPrerelease:$InputAllowPreRelease
		$ToolkitInstalledPrevious |
			Where-Object -FilterScript { $InputForce -or [SemVer]::Parse($_.Version) -ine $VersionResolve } |
			ForEach-Object -Process {
				Uninstall-Module -Name 'hugoalh.GitHubActionsToolkit' -RequiredVersion $_.Version -AllowPrerelease -Confirm:$False -Verbose:$IsDebugMode
			}
		If (
			$InputForce -or
			(
				$ToolkitInstalledPrevious |
					Where-Object -FilterScript { [SemVer]::Parse($_.Version) -ieq $VersionResolve } |
					Measure-Object
			).Count -eq 0
		) {
			Install-Module -Name 'hugoalh.GitHubActionsToolkit' -Repository 'PSGallery' -RequiredVersion $VersionResolve -Scope $InputScope -AllowPrerelease:$InputAllowPreRelease -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
		}
	}
}
Catch {
	Write-Host -Object "::error::$($_ -ireplace '\r?\n', ' ')"
	Exit 1
}
$ToolkitInstalledCurrent = Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease -ErrorAction ($InputUninstall ? 'Continue' : 'Stop')
$ToolkitInstalledCurrent |
	Format-List -Property @('Version', 'PublishedDate', 'InstalledDate', 'UpdatedDate', 'Dependencies', 'RepositorySourceLocation', 'Repository', 'PackageManagementProvider', 'InstalledLocation')
If ($Null -ne $ToolkitInstalledCurrent) {
	Add-Content -LiteralPath $Env:GITHUB_OUTPUT -Value @(
		"path=$($ToolkitInstalledCurrent.InstalledLocation)",
		"version=$($ToolkitInstalledCurrent.Version.ToString())"
	) -Confirm:$False -Encoding 'UTF8NoBOM'
}
If (!$InputKeepSetting) {
	If ($PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
		Write-Host -Object 'Restore PowerShell repository configuration.'
		Set-PSRepository -Name 'PSGallery' -InstallationPolicy $PSRepositoryPSGalleryMeta.InstallationPolicy -Verbose:$IsDebugMode
	}
}
