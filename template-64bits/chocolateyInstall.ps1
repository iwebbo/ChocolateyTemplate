# Modification du chocolateyInstall.ps1 pour utiliser automatiquement le nom du package

<#
.SYNOPSIS
    Installation script for 64-bit [[PackageName]] package using a local installer.
.DESCRIPTION
    This script is designed to install [[PackageName]] for x64 architecture
    from a local installer file included in the package.
#>

$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

# Déterminer automatiquement le nom du fichier d'installation basé sur le nom du package
# Le format sera packagename-x64.exe ou packagename-x64.msi
$installerExt = '[[InstallerType]]' # 'exe' ou 'msi'
$fileLocation = Join-Path $toolsDir "[[PackageNameLower]]-x64.$installerExt"

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  fileType       = '[[InstallerType]]'
  file64         = $fileLocation
  silentArgs     = '[[SilentArgs]]'
  validExitCodes = @(0)
}

# Vérifier que le fichier d'installation existe
if (!(Test-Path $fileLocation)) {
  # Message d'erreur explicite avec des instructions
  throw @"
Le fichier d'installation '$fileLocation' est introuvable.
  
INSTRUCTIONS:
1. Téléchargez le fichier d'installation de [[PackageName]] (version 64-bit)
2. Renommez-le en "[[PackageNameLower]]-x64.$installerExt"
3. Placez-le dans le dossier 'tools' du package
4. Relancez la création du package
"@
}

# Installation à partir du fichier local
Install-ChocolateyInstallPackage @packageArgs

# Supprimer l'installateur après l'installation pour économiser de l'espace
# Décommentez la ligne suivante si vous souhaitez supprimer l'installateur après l'installation
# Remove-Item $fileLocation -Force -ErrorAction SilentlyContinue