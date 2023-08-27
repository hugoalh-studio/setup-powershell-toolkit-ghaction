#Requires -PSEdition Core -Version 7.2
$Script:ErrorActionPreference = 'Stop'
Write-Host -Object 'Initialize.'
[Boolean]$IsDebugMode = $Env:RUNNER_DEBUG -iin @('1', 'True')
[RegEx]$SemVerModifierRegEx = '^(?:[<>]=?|=|\^|~) *'
Function Install-ModuleTargetVersion {
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $True, Position = 0)][String]$Name,
		[Parameter(Mandatory = $True, Position = 1)][AllowEmptyString()][String]$VersionModifier,
		[Parameter(Mandatory = $True, Position = 2)][SemVer]$VersionNumber,
		[Switch]$AllowPrerelease,
		[String]$Scope,
		[Switch]$Force
	)
	[SemVer[]]$VersionsAvailable = Find-Module -Name $Name -AllVersions -Repository 'PSGallery' -AllowPrerelease:($AllowPrerelease.IsPresent) -Verbose:$IsDebugMode |
		Select-Object -ExpandProperty 'Version' |
		ForEach-Object -Process { [SemVer]::Parse($_) } |
		Sort-Object
	[SemVer]$VersionTarget = $VersionsAvailable |
		Where-Object -FilterScript { Test-SemVerModifier -Original $_ -TargetModifier $VersionModifier -TargetNumber $VersionNumber } |
		Sort-Object |
		Select-Object -Last 1
	If ($Null -ieq $VersionTarget) {
		Throw "No available versions that meet requested version ``$($VersionModifier)$($VersionNumber.ToString())``! Only these versions are available: $(
			$VersionsAvailable |
				ForEach-Object -Process { $_.ToString() } |
				Join-String -Separator ', '
		)"
	}
	Try {
		[SemVer[]]$VersionInstalled = Get-InstalledModule -Name $Name -AllVersions -AllowPrerelease |
			Select-Object -ExpandProperty 'Version' |
			ForEach-Object -Process { [SemVer]::Parse($_) }
		$VersionInstalled |
			Where-Object -FilterScript { $Force.IsPresent -or $_ -ine $VersionTarget } |
			ForEach-Object -Process {
				Uninstall-Module -Name $Name -RequiredVersion $_ -AllowPrerelease -Confirm:$False -Verbose:$IsDebugMode -ErrorAction 'Continue'
			}
		If (
			$Force.IsPresent -or
			(
				$VersionInstalled |
					Where-Object -FilterScript { $_ -ieq $VersionTarget } |
					Measure-Object |
					Select-Object -ExpandProperty 'Count'
			) -eq 0
		) {
			Throw
		}
	}
	Catch {
		Install-Module -Name $Name -RequiredVersion $VersionTarget -Repository 'PSGallery' -Scope $Scope -AllowPrerelease:($AllowPrerelease.IsPresent) -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
	}
}
Function Test-SemVerModifier {
	[CmdletBinding()]
	[OutputType([Boolean])]
	Param (
		[Parameter(Mandatory = $True, Position = 0)][SemVer]$Original,
		[Parameter(Mandatory = $True, Position = 1)][AllowEmptyString()][String]$TargetModifier,
		[Parameter(Mandatory = $True, Position = 2)][SemVer]$TargetNumber
	)
	Switch ($TargetModifier) {
		'<' {
			$Original -ilt $TargetNumber |
				Write-Output
			Break
		}
		'<=' {
			$Original -ile $TargetNumber |
				Write-Output
			Break
		}
		'>=' {
			$Original -ige $TargetNumber |
				Write-Output
			Break
		}
		'>' {
			$Original -igt $TargetNumber |
				Write-Output
			Break
		}
		'^' {
			$Original -ige $TargetNumber -and $Original -ilt [SemVer]::Parse("$($TargetNumber.Major + 1).0.0") |
				Write-Output
			Break
		}
		'~' {
			$Original -ige $TargetNumber -and $Original -ilt [SemVer]::Parse("$($TargetNumber.Major).$($TargetNumber.Minor + 1).0") |
				Write-Output
			Break
		}
		Default {
			$Original -ieq $TargetNumber |
				Write-Output
			Break
		}
	}
}
Write-Host -Object 'Import input.'
Try {
	[String]$InputVersionRaw = $Env:INPUT_VERSION
	[Boolean]$InputVersionLatest = $InputVersionRaw -ieq 'Latest'
	[Boolean]$InputUninstall = $InputVersionRaw -iin @('False', 'None', 'Uninstall')
	If (!$InputVersionLatest -and !$InputUninstall) {
		[String]$InputVersionModifier = ($InputVersionRaw -imatch $SemVerModifierRegEx) ? $Matches[0].Trim() : ''
		[SemVer]$InputVersionNumber = [SemVer]::Parse((($InputVersionRaw -imatch $SemVerModifierRegEx) ? $InputVersionRaw -ireplace "^$([RegEx]::Escape($Matches[0]))", '' : $InputVersionRaw))
	}
}
Catch {
	Write-Host -Object '::error::Input `version` must be `"Latest"` or a SemVer!'
	Exit 1
}
Try {
	[Boolean]$InputAllowPreRelease = [Boolean]::Parse($Env:INPUT_ALLOWPRERELEASE)
}
Catch {
	Write-Host -Object '::error::Input `allowprerelease` must be a boolean!'
	Exit 1
}
Try {
	[Boolean]$InputForce = [Boolean]::Parse($Env:INPUT_FORCE)
}
Catch {
	Write-Host -Object '::error::Input `force` must be a boolean!'
	Exit 1
}
[String]$InputScope = $Env:INPUT_SCOPE
Try {
	[Boolean]$InputKeepSetting = [Boolean]::Parse($Env:INPUT_KEEPSETTING)
}
Catch {
	Write-Host -Object '::error::Input `keepsetting` must be a boolean!'
	Exit 1
}
$PSRepositoryPSGalleryMeta = Get-PSRepository -Name 'PSGallery'
If ($PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
	Write-Host -Object 'Tweak PowerShell repository configuration.'
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' -Verbose:$IsDebugMode
}
Write-Host -Object 'Check PowerShellGet.'
Try {
	$PSModulePowerShellGetMeta = ((
		Get-Module -Name 'PowerShellGet' -ListAvailable -ErrorAction 'SilentlyContinue' |
			Where-Object -FilterScript { $_.Path -imatch '[\\/]powershell[\\/]\d+[\\/]modules[\\/]powershellget[\\/]' }
	) ?? (Get-PackageProvider -Name 'PowerShellGet' -ErrorAction 'SilentlyContinue') ?? (Get-InstalledModule -Name 'PowerShellGet')) |
		Sort-Object -Property 'Version' |
		Select-Object -Last 1
}
Catch {
	Write-Host -Object '::error::PowerShell module `PowerShellGet` does not exist!'
	Exit 1
}
If (!(Test-SemVerModifier -Original $PSModulePowerShellGetMeta.Version -TargetModifier '^' -TargetNumber ([SemVer]::Parse('2.2.5')))) {
	Write-Host -Object '::error::PowerShell module `PowerShellGet` does not meet requirement!'
	Exit 1
}
Write-Host -Object 'Setup PowerShell module `hugoalh.GitHubActionsToolkit`.'
Try {
	If ($InputUninstall) {
		Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease |
			Select-Object -ExpandProperty 'Version' |
			ForEach-Object -Process { [SemVer]::Parse($_) } |
			ForEach-Object -Process {
				Uninstall-Module -Name 'hugoalh.GitHubActionsToolkit' -RequiredVersion $_ -AllowPrerelease -Confirm:$False -Verbose:$IsDebugMode -ErrorAction 'Continue'
			}
	}
	Else {
		Install-ModuleTargetVersion -Name 'hugoalh.GitHubActionsToolkit' -VersionModifier ($InputVersionLatest ? '>=' : $InputVersionModifier) -VersionNumber ($InputVersionLatest ? [SemVer]::Parse('0') : $InputVersionNumber) -AllowPrerelease:$InputAllowPreRelease -Scope $InputScope -Force:$InputForce
	}
}
Catch {
	Write-Host -Object "::error::$($_ -ireplace '\r?\n', ' ')"
	Exit 1
}
Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease -ErrorAction ($InputUninstall ? 'Continue' : 'Stop') |
	Format-List |
	Out-String -Width 120 |
	Write-Host
If (!$InputKeepSetting -and $PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
	Write-Host -Object 'Restore PowerShell repository configuration.'
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy $PSRepositoryPSGalleryMeta.InstallationPolicy -Verbose:$IsDebugMode
}
