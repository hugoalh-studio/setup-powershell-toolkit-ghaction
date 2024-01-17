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
			Switch ($VersionModifier) {
				'<' {
					$_ -ilt $VersionNumber |
						Write-Output
					Break
				}
				'<=' {
					$_ -ile $VersionNumber |
						Write-Output
					Break
				}
				'>=' {
					$_ -ige $VersionNumber |
						Write-Output
					Break
				}
				'>' {
					$_ -igt $VersionNumber |
						Write-Output
					Break
				}
				'^' {
					$_ -ige $VersionNumber -and $_ -ilt [SemVer]::Parse("$($VersionNumber.Major + 1).0.0") |
						Write-Output
					Break
				}
				'~' {
					$_ -ige $VersionNumber -and $_ -ilt [SemVer]::Parse("$($VersionNumber.Major).$($VersionNumber.Minor + 1).0") |
						Write-Output
					Break
				}
				Default {
					$_ -ieq $VersionNumber |
						Write-Output
					Break
				}
			}
		} |
		Sort-Object -Descending |
		Select-Object -First 1
	If ($Null -ieq $VersionResolve) {
		Write-Host -Object "::error::No available versions that fulfill the target version ``$($VersionModifier)$($VersionNumber.ToString())``! Only these versions are available: $VersionsAvailableStringify"
		Exit 1
	}
	Write-Output -InputObject $VersionResolve
}
Write-Host -Object 'Initialize.'
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
Write-Host -Object 'Check PowerShell repository.'
$PSRepositoryPSGalleryMeta = Get-PSRepository -Name 'PSGallery'
If ((
	$PSRepositoryPSGalleryMeta |
		Measure-Object
).Count -ne 1) {
	Write-Host -Object '::error::PowerShell repository does not meet the requirement!'
	Exit 1
}
If ($PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
	Write-Host -Object 'Tweak PowerShell repository configuration.'
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' -Verbose:$IsDebugMode
}
Write-Host -Object 'Check PowerShell package provider.'
$PSPackageProviderPowerShellGetMeta = Get-PackageProvider -Name 'PowerShellGet'
If (
	(
		$PSPackageProviderPowerShellGetMeta |
			Measure-Object
	).Count -ne 1 -or
	!([SemVer]::Parse($PSPackageProviderPowerShellGetMeta.Version) -ge [SemVer]::Parse('2.2.5') -and [SemVer]::Parse($PSPackageProviderPowerShellGetMeta.Version) -lt [SemVer]::Parse('3.0.0'))
) {
	Write-Host -Object '::error::PowerShell package provider does not meet the requirement!'
	Exit 1
}
Write-Host -Object 'Setup PowerShell module `hugoalh.GitHubActionsToolkit`.'
Try {
	If ($InputUninstall) {
		Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease |
			ForEach-Object -Process {
				Uninstall-Module -Name 'hugoalh.GitHubActionsToolkit' -RequiredVersion $_.Version -AllowPrerelease -Confirm:$False -Verbose:$IsDebugMode
			}
	}
	Else {
		[SemVer]$VersionResolve = Resolve-TargetVersion -VersionModifier ($InputVersionLatest ? '>=' : $InputVersionModifier) -VersionNumber ($InputVersionLatest ? [SemVer]::Parse('2.1.0') : $InputVersionNumber) -AllowPrerelease:$InputAllowPreRelease
		[SemVer[]]$VersionsInstalled = Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease |
			ForEach-Object -Process { [SemVer]::Parse($_.Version) }
		$VersionsInstalled |
			Where-Object -FilterScript { $InputForce -or $_ -ine $VersionResolve } |
			ForEach-Object -Process {
				Uninstall-Module -Name 'hugoalh.GitHubActionsToolkit' -RequiredVersion $_ -AllowPrerelease -Confirm:$False -Verbose:$IsDebugMode
			}
		If (
			$InputForce -or
			(
				$VersionsInstalled |
					Where-Object -FilterScript { $_ -ieq $VersionResolve } |
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
Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease -ErrorAction ($InputUninstall ? 'Continue' : 'Stop') |
	Format-List -Property @('Version', 'PublishedDate', 'InstalledDate', 'UpdatedDate', 'Dependencies', 'RepositorySourceLocation', 'Repository', 'PackageManagementProvider', 'InstalledLocation') |
	Write-Host
If (!$InputKeepSetting) {
	If ($PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
		Write-Host -Object 'Restore PowerShell repository configuration.'
		Set-PSRepository -Name 'PSGallery' -InstallationPolicy $PSRepositoryPSGalleryMeta.InstallationPolicy -Verbose:$IsDebugMode
	}
}
