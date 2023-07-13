#Requires -PSEdition Core -Version 7.2
$Script:ErrorActionPreference = 'Stop'
Write-Host -Object 'Initialize.'
[Boolean]$IsDebugMode = $Env:RUNNER_DEBUG -iin @('1', 'True')
[RegEx]$SemVerModifierRegEx = '^(?:<|<=|=|>=|>|\^|~) *'
Function Install-ModuleTargetVersion {
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $True, Position = 0)][String]$Name,
		[Parameter(Mandatory = $True, Position = 1)][AllowEmptyString()][String]$VersionModifier,
		[Parameter(Mandatory = $True, Position = 2)][SemVer]$VersionNumber,
		[Switch]$AllowPrerelease
	)
	[SemVer]$VersionTarget = Find-Module -Name $Name -AllVersions -AllowPrerelease:($AllowPrerelease.IsPresent) -Verbose:$IsDebugMode |
		Select-Object -ExpandProperty 'Version' |
		ForEach-Object -Process { [SemVer]::Parse($_) } |
		Where-Object -FilterScript { Test-SemVerModifier -Original $_ -TargetModifier $VersionModifier -TargetNumber $VersionNumber } |
		Sort-Object |
		Select-Object -Last 1
	Try {
		$ModuleMeta = Get-InstalledModule -Name $Name
		If ($ModuleMeta.Version -ine $VersionTarget) {
			Throw
		}
	}
	Catch {
		Install-Module -Name $Name -RequiredVersion $VersionTarget -Scope 'AllUsers' -AllowPrerelease:($AllowPrerelease.IsPresent) -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
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
	If (!$InputVersionLatest) {
		[String]$InputVersionModifier = ($InputVersionRaw -imatch $SemVerModifierRegEx) ? $Matches[0].Trim() : ''
		[SemVer]$InputVersionNumber = [SemVer]::Parse((($InputVersionRaw -imatch $SemVerModifierRegEx) ? $InputVersionRaw -ireplace "^$([RegEx]::Escape($Matches[0]))", '' : $InputVersionRaw))
	}
}
Catch {
	Write-Host -Object '::error::Input `version` must be `"Latest"` or type of SemVer!'
	Exit 1
}
Try {
	[Boolean]$InputAllowPreRelease = [Boolean]::Parse($Env:INPUT_ALLOWPRERELEASE)
}
Catch {
	Write-Host -Object '::error::Input `allowprerelease` must be type of boolean!'
	Exit 1
}
Write-Host -Object 'Tweak PowerShell repository configuration.'
Try {
	$PSRepositoryPSGalleryMeta = Get-PSRepository -Name 'PSGallery'
}
Catch {
	Write-Host -Object '::error::PowerShell repository `PSGallery` does not exist!'
	Exit 1
}
If ($PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
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
If ($InputVersionLatest) {
	Install-Module -Name 'hugoalh.GitHubActionsToolkit' -Scope 'AllUsers' -AllowPrerelease:$InputAllowPreRelease -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
}
Else {
	Install-ModuleTargetVersion -Name 'hugoalh.GitHubActionsToolkit' -VersionModifier $InputVersionModifier -VersionNumber $InputVersionNumber -AllowPrerelease:$InputAllowPreRelease
}
Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease |
	Format-List |
	Out-String -Width 120 |
	Write-Host
If ($PSRepositoryPSGalleryMeta.InstallationPolicy -ine 'Trusted') {
	Write-Host -Object 'Restore PowerShell repository configuration.'
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy $PSRepositoryPSGalleryMeta.InstallationPolicy -Verbose:$IsDebugMode
}
