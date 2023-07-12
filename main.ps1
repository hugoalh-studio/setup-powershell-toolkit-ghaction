#Requires -PSEdition Core -Version 7.2
$Script:ErrorActionPreference = 'Stop'
Write-Host -Object 'Initialize.'
[Boolean]$IsDebugMode = $Env:RUNNER_DEBUG -ieq '1' -or $Env:RUNNER_DEBUG -ieq 'True'
[RegEx]$SemVerRangeRegEx = '^(?:<|<=|=|>=|>|\^|~) *'
<#
[SemVer]$PowerShellGetVersionMaximum = [SemVer]::Parse('2.99999999.99999999')
[SemVer]$PowerShellGetVersionMinimum = [SemVer]::Parse('2.2.5')
#>
Function Install-ModuleTargetVersion {
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $True, Position = 0)][Alias('ModuleName')][String]$Name,
		[Parameter(Mandatory = $True, Position = 1)][AllowEmptyString()][Alias('ModuleVersionModifier')][String]$VersionModifier,
		[Parameter(Mandatory = $True, Position = 2)][Alias('ModuleVersionNumber')][SemVer]$VersionNumber,
		[Switch]$AllowPrerelease
	)
	[SemVer]$VersionTarget = Find-Module -Name $Name -AllVersions -AllowPrerelease:($AllowPrerelease.IsPresent) -Verbose:$IsDebugMode |
		Select-Object -ExpandProperty 'Version' |
		ForEach-Object -Process { [SemVer]::Parse($_) } |
		Where-Object -FilterScript {
			If ($VersionModifier -ieq '<') {
				$_ -ilt $VersionNumber |
					Write-Output
			}
			ElseIf ($VersionModifier -ieq '<=') {
				$_ -ile $VersionNumber |
					Write-Output
			}
			ElseIf ($VersionModifier -ieq '>') {
				$_ -igt $VersionNumber |
					Write-Output
			}
			ElseIf ($VersionModifier -ieq '>=') {
				$_ -ige $VersionNumber |
					Write-Output
			}
			ElseIf ($VersionModifier -ieq '^') {
				$_ -ige $VersionNumber -and $_ -ilt [SemVer]::Parse("$($VersionNumber.Major + 1).0.0") |
					Write-Output
			}
			ElseIf ($VersionModifier -ieq '~') {
				$_ -ige $VersionNumber -and $_ -ilt [SemVer]::Parse("$($VersionNumber.Major).$($VersionNumber.Minor + 1).0") |
					Write-Output
			}
			Else {
				$VersionNumber -ieq $_ |
					Write-Output
			}
		} |
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
Write-Host -Object 'Import input.'
Try {
	[Boolean]$InputPowerShellGetSetup = [Boolean]::Parse($Env:INPUT_POWERSHELLGET_SETUP)
}
Catch {
	Write-Host -Object '::error::Input `powershellget_setup` must be type of boolean!'
	Exit 1
}
Try {
	[String]$InputPowerShellGetVersionRaw = $Env:INPUT_POWERSHELLGET_VERSION
	[Boolean]$InputPowerShellGetVersionLatest = $InputPowerShellGetVersionRaw -ieq 'Latest'
	If (!$InputPowerShellGetVersionLatest) {
		[String]$InputPowerShellGetVersionModifier = ($InputPowerShellGetVersionRaw -imatch $SemVerRangeRegEx) ? $Matches[0].Trim() : ''
		[SemVer]$InputPowerShellGetVersionNumber = [SemVer]::Parse((($InputPowerShellGetVersionRaw -imatch $SemVerRangeRegEx) ? $InputPowerShellGetVersionRaw -ireplace "^$([RegEx]::Escape($Matches[0]))", '' : $InputPowerShellGetVersionRaw))
	}
}
Catch {
	Write-Host -Object '::error::Input `powershellget_version` must be `"Latest"` or type of SemVer!'
	Exit 1
}
Try {
	[Boolean]$InputToolkitSetup = [Boolean]::Parse($Env:INPUT_TOOLKIT_SETUP)
}
Catch {
	Write-Host -Object '::error::Input `toolkit_setup` must be type of boolean!'
	Exit 1
}
Try {
	[String]$InputToolkitVersionRaw = $Env:INPUT_TOOLKIT_VERSION
	[Boolean]$InputToolkitVersionLatest = $InputToolkitVersionRaw -ieq 'Latest'
	If (!$InputToolkitVersionLatest) {
		[String]$InputToolkitVersionModifier = ($InputToolkitVersionRaw -imatch $SemVerRangeRegEx) ? $Matches[0].Trim() : ''
		[SemVer]$InputToolkitVersionNumber = [SemVer]::Parse((($InputToolkitVersionRaw -imatch $SemVerRangeRegEx) ? $InputToolkitVersionRaw -ireplace "^$([RegEx]::Escape($Matches[0]))", '' : $InputToolkitVersionRaw))
	}
}
Catch {
	Write-Host -Object '::error::Input `toolkit_version` must be `"Latest"` or type of SemVer!'
	Exit 1
}
Try {
	[Boolean]$InputToolkitAllowPreRelease = [Boolean]::Parse($Env:INPUT_TOOLKIT_ALLOWPRERELEASE)
}
Catch {
	Write-Host -Object '::error::Input `toolkit_allowprerelease` must be type of boolean!'
	Exit 1
}
Write-Host -Object 'Setup PowerShell Gallery.'
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
<#
Write-Host -Object 'Setup PowerShellGet.'
Try {
	$PSModulePowerShellGetMeta = (
		Get-Module -Name 'PowerShellGet' -ListAvailable -ErrorAction 'SilentlyContinue' |
			Where-Object -FilterScript { $_.Path -imatch '[\\/]powershell[\\/]\d+[\\/]modules[\\/]powershellget[\\/]' } |
			Sort-Object -Property 'Version' |
			Select-Object -Last 1
	) ?? (Get-PackageProvider -Name 'PowerShellGet' -ErrorAction 'SilentlyContinue') ?? (Get-InstalledModule -Name 'PowerShellGet' -ErrorAction 'SilentlyContinue')
	If (
		$Null -ieq $PSModulePowerShellGetMeta -or
		$PSModulePowerShellGetMeta.Version -ilt $PowerShellGetVersionMinimum
	) {
		Throw
	}
}
Catch {
	Install-Module -Name 'PowerShellGet' -MinimumVersion $PowerShellGetVersionMinimum -MaximumVersion $PowerShellGetVersionMaximum -Scope 'AllUsers' -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
}
#>
If ($InputPowerShellGetSetup) {
	Write-Host -Object 'Setup PowerShellGet.'
	If ($InputPowerShellGetVersionLatest) {
		Install-Module -Name 'PowerShellGet' -Scope 'AllUsers' -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
	}
	Else {
		Install-ModuleTargetVersion -Name 'PowerShellGet' -VersionModifier $InputPowerShellGetVersionModifier -VersionNumber $InputPowerShellGetVersionNumber
	}
	Get-InstalledModule -Name 'PowerShellGet' -AllVersions |
		Format-List |
		Out-String -Width 120 |
		Write-Host
}
If ($InputToolkitSetup) {
	Write-Host -Object 'Setup PowerShell module `hugoalh.GitHubActionsToolkit`.'
	If ($InputToolkitVersionLatest) {
		Install-Module -Name 'hugoalh.GitHubActionsToolkit' -Scope 'AllUsers' -AllowPrerelease:$InputToolkitAllowPreRelease -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
	}
	Else {
		<#
		Try {
			$PSModuleToolkitMeta = Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit'
			If ($PSModuleToolkitMeta.Version -ine $InputToolkitVersion) {
				Throw
			}
		}
		Catch {
			Install-Module -Name 'hugoalh.GitHubActionsToolkit' -RequiredVersion $InputToolkitVersion -Scope 'AllUsers' -AllowPrerelease:$InputToolkitAllowPreRelease -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
		}
		#>
		Install-ModuleTargetVersion -Name 'hugoalh.GitHubActionsToolkit' -VersionModifier $InputToolkitVersionModifier -VersionNumber $InputToolkitVersionNumber -AllowPrerelease:$InputToolkitAllowPreRelease
	}
	Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease |
		Format-List |
		Out-String -Width 120 |
		Write-Host
}
