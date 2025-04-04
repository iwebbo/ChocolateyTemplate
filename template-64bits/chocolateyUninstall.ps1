<#
.SYNOPSIS
    Uninstallation script for [[PackageName]] package.
.DESCRIPTION
    This script removes [[PackageName]].
#>

$ErrorActionPreference = 'Stop'

$packageName = $env:ChocolateyPackageName

$uninstallRegistry = Get-UninstallRegistryKey -SoftwareName "[[PackageName]]*"

if ($uninstallRegistry.Count -eq 1) {
  $uninstallRegistry | ForEach-Object {
    $uninstallArgs = @{
      packageName    = $packageName
      fileType       = '[[InstallerType]]' # 'exe' or 'msi'
      silentArgs     = '[[UninstallArgs]]' # For MSI: "$($_.PSChildName) /qn /norestart"
      validExitCodes = @(0)
      file           = "$($_.UninstallString)" # Use if UninstallString contains the path directly
    }
    
    # Handle MSI uninstallation differently if needed
    if ($uninstallArgs.fileType -eq 'msi') {
      $uninstallArgs.silentArgs = "$($_.PSChildName) /qn /norestart"
      $uninstallArgs.file = ''
    }

    Uninstall-ChocolateyPackage @uninstallArgs
  }
} elseif ($uninstallRegistry.Count -eq 0) {
  Write-Warning "[[PackageName]] not found in Programs and Features. It may have been uninstalled manually."
} else {
  Write-Warning "Multiple instances of [[PackageName]] found in Programs and Features. Manual intervention required."
}
