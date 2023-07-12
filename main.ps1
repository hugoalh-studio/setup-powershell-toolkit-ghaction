#Requires -PSEdition Core -Version 7.2
$Script:ErrorActionPreference = 'Stop'
Write-Host -Object 'Initialize.'
[Boolean]$IsDebugMode = $Env:RUNNER_DEBUG -ieq '1' -or $Env:RUNNER_DEBUG -ieq 'True'
[SemVer]$PowerShellGetVersionMaximum = [SemVer]::Parse('2.99999999.99999999')
[SemVer]$PowerShellGetVersionMinimum = [SemVer]::Parse('2.2.5')
Write-Host -Object 'Import input.'
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
	[SemVer]$InputToolkitVersion = $InputToolkitVersionLatest ? [SemVer]::Parse('1.0.0-fake') : [SemVer]::Parse($InputToolkitVersionRaw)
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
If ($InputToolkitSetup) {
	Write-Host -Object 'Setup PowerShell module `hugoalh.GitHubActionsToolkit`.'
	If ($InputToolkitVersionLatest) {
		Install-Module -Name 'hugoalh.GitHubActionsToolkit' -Scope 'AllUsers' -AllowPrerelease:$InputToolkitAllowPreRelease -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
		Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit' -AllVersions -AllowPrerelease |
			Format-List |
			Out-String -Width 120 |
			Write-Host
	}
	Else {
		Try {
			$PSModuleToolkitMeta = Get-InstalledModule -Name 'hugoalh.GitHubActionsToolkit'
			If ($PSModuleToolkitMeta.Version -ine $InputToolkitVersion) {
				Throw
			}
		}
		Catch {
			Install-Module -Name 'hugoalh.GitHubActionsToolkit' -RequiredVersion $InputToolkitVersion -Scope 'AllUsers' -AllowPrerelease:$InputToolkitAllowPreRelease -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
		}
	}
}
