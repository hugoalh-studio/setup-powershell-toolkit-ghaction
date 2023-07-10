#Requires -PSEdition Core -Version 7.2
$Script:ErrorActionPreference = 'Stop'
[Boolean]$IsDebugMode = $Env:RUNNER_DEBUG -ieq '1' -or $Env:RUNNER_DEBUG -ieq 'True'
Try {
	[Boolean]$InputToolkitSetup = [Boolean]::Parse($Env:INPUT_TOOLKIT_SETUP)
}
Catch {
	Write-Host -Object '::error::Input `toolkit_setup` must be type of boolean!'
	Exit 1
}
Try {
	[SemVer]$InputToolkitVersion = [SemVer]::Parse($Env:INPUT_TOOLKIT_VERSION)
}
Catch {
	Write-Host -Object '::error::Input `toolkit_version` must be type of SemVer!'
	Exit 1
}
Try {
	[Boolean]$InputToolkitAllowPreRelease = [Boolean]::Parse($Env:INPUT_TOOLKIT_ALLOWPRERELEASE)
}
Catch {
	Write-Host -Object '::error::Input `toolkit_allowprerelease` must be type of boolean!'
	Exit 1
}
Try {
	$PSRepositoryPSGallery = Get-PSRepository -Name 'PSGallery'
}
Catch {
	Write-Host -Object '::error::PowerShell repository `PSGallery` does not exist!'
	Exit 1
}
If ($PSRepositoryPSGallery.InstallationPolicy -ine 'Trusted') {
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' -Verbose:$IsDebugMode
}
[SemVer]$PowerShellGetMinimumVersion = [SemVer]::Parse('2.2.5')
Try {
	$PSModulePowerShellGetMeta = (
		Get-Module -Name 'PowerShellGet' -ListAvailable -ErrorAction 'SilentlyContinue' |
			Where-Object -FilterScript { $_.Path -imatch '[\\/]powershell[\\/]\d+[\\/]modules[\\/]powershellget[\\/]' } |
			Sort-Object -Property 'Version' |
			Select-Object -Last 1
	) ?? (Get-PackageProvider -Name 'PowerShellGet' -ErrorAction 'SilentlyContinue') ?? (Get-InstalledModule -Name 'PowerShellGet' -ErrorAction 'SilentlyContinue')
	If (
		$Null -ieq $PSModulePowerShellGetMeta -or
		$PSModulePowerShellGetMeta.Version -ilt $PowerShellGetMinimumVersion
	) {
		Throw
	}
}
Catch {
	Install-Module -Name 'PowerShellGet' -MinimumVersion $PowerShellGetMinimumVersion -Scope 'AllUsers' -AcceptLicense -Confirm:$False -Verbose:$IsDebugMode
}
If ($InputToolkitSetup) {
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
