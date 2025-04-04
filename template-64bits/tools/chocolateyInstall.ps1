# chocolateyInstall.ps1 universel pour différents types d'installateurs

$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

# Déterminer automatiquement le nom du fichier d'installation basé sur le nom du package
$installerExt = '[[InstallerType]]' # 'exe' ou 'msi'
$fileLocation = Join-Path $toolsDir "[[PackageNameLower]]-x64.$installerExt"

# Détection automatique de type d'installeur si le fichier spécifié n'existe pas
if (!(Test-Path $fileLocation)) {
    $possibleExts = @('exe', 'msi', 'msixbundle', 'msp')
    $found = $false
    
    foreach ($ext in $possibleExts) {
        $testPath = Join-Path $toolsDir "[[PackageNameLower]]-x64.$ext"
        if (Test-Path $testPath) {
            $fileLocation = $testPath
            $installerExt = $ext
            $found = $true
            Write-Host "Installer trouvé: $fileLocation"
            break
        }
    }
    
    if (!$found) {
        throw @"
Le fichier d'installation n'a pas été trouvé.

INSTRUCTIONS:
1. Téléchargez l'installateur 64-bit pour [[PackageName]]
2. Renommez-le en "[[PackageNameLower]]-x64.exe" (ou .msi, .msixbundle)
3. Placez-le dans le dossier 'tools' du package
4. Relancez la création du package
"@
    }
}

# Détermination des arguments silencieux en fonction du type de fichier et du nom du package
$silentArgs = switch -Regex ($installerExt) {
    'msi' { '/qn /norestart'; Break }
    'exe' {
        # Détection intelligente du type d'installateur
        $fileInfo = (Get-Item $fileLocation).VersionInfo
        $fileDesc = $fileInfo.FileDescription
        $companyName = $fileInfo.CompanyName
        $productName = $fileInfo.ProductName
        $originalFilename = $fileInfo.OriginalFilename
        
        Write-Host "Détection du type d'installateur..."
        Write-Host "Description: $fileDesc"
        Write-Host "Compagnie: $companyName"
        Write-Host "Produit: $productName"
        Write-Host "Fichier original: $originalFilename"
        
        # Essayer de détecter le type d'installateur
        if ($fileDesc -match "Inno Setup" -or $productName -match "Inno Setup") {
            Write-Host "Détecté comme un installateur Inno Setup"
            '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
        }
        elseif ($fileDesc -match "NSIS" -or $productName -match "NSIS" -or $fileDesc -match "Nullsoft") {
            Write-Host "Détecté comme un installateur NSIS"
            '/S'
        }
        elseif ($fileDesc -match "InstallShield" -or $productName -match "InstallShield") {
            Write-Host "Détecté comme un installateur InstallShield"
            '/s /v"/qn /norestart"'
        }
        elseif ($originalFilename -match "dotnet" -or $productName -match "\.NET" -or $productName -match "Microsoft") {
            Write-Host "Détecté comme un installateur Microsoft .NET"
            '/install /quiet /norestart'
        }
        elseif ($productName -match "Java" -or $companyName -match "Oracle") {
            Write-Host "Détecté comme un installateur Java"
            '/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0'
        }
        else {
            Write-Host "Type d'installateur non reconnu, utilisation des arguments par défaut"
            '/quiet /norestart'
        }
        Break
    }
    'msixbundle|appx' { '/quiet'; Break }
    'msp' { '/qn /norestart'; Break }
    default { '[[SilentArgs]]'; Break }
}

Write-Host "Arguments silencieux utilisés: $silentArgs"

# Calculer automatiquement le checksum pour la vérification
$checksum = Get-FileHash -Path $fileLocation -Algorithm SHA256 | Select-Object -ExpandProperty Hash
Write-Host "Checksum du fichier: $checksum"

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $toolsDir
    fileType       = $installerExt
    file64         = $fileLocation
    silentArgs     = $silentArgs
    validExitCodes = @(0, 3010, 1641)  # 3010/1641 = redémarrage requis
    checksum64     = $checksum
    checksumType64 = 'sha256'
}

# Installation avec gestion des erreurs
try {
    Write-Host "Installation du package avec les paramètres suivants:"
    Write-Host "Type de fichier: $($packageArgs.fileType)"
    Write-Host "Fichier: $($packageArgs.file64)"
    Write-Host "Arguments: $($packageArgs.silentArgs)"
    
    if ($packageArgs.fileType -eq "exe") {
        Install-ChocolateyInstallPackage @packageArgs
    }
    elseif ($packageArgs.fileType -eq "msi") {
        Install-ChocolateyInstallPackage @packageArgs
    }
    elseif ($packageArgs.fileType -match "msixbundle|appx") {
        # Pour les packages MSIX/AppX
        Add-AppxPackage -Path $fileLocation
    }
    else {
        Install-ChocolateyInstallPackage @packageArgs
    }
    
    # Tester si l'installation a ajouté des commandes au PATH
    if ($env:ChocolateyPackageName -match "dotnet|java|node|python") {
        Write-Host "Actualisation des variables d'environnement..."
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # Test spécifique pour certains packages
        switch -Regex ($env:ChocolateyPackageName) {
            "dotnet" {
                Write-Host "Test d'installation .NET..."
                try { Invoke-Expression "dotnet --list-runtimes" } catch { Write-Warning "Impossible d'exécuter la commande dotnet. Un redémarrage peut être nécessaire." }
                break
            }
            "java" {
                Write-Host "Test d'installation Java..."
                try { Invoke-Expression "java -version" } catch { Write-Warning "Impossible d'exécuter la commande java. Un redémarrage peut être nécessaire." }
                break
            }
            "node" {
                Write-Host "Test d'installation Node.js..."
                try { Invoke-Expression "node --version" } catch { Write-Warning "Impossible d'exécuter la commande node. Un redémarrage peut être nécessaire." }
                break
            }
            "python" {
                Write-Host "Test d'installation Python..."
                try { Invoke-Expression "python --version" } catch { Write-Warning "Impossible d'exécuter la commande python. Un redémarrage peut être nécessaire." }
                break
            }
        }
    }
    
    Write-Host "Installation terminée avec succès."
    if ($packageArgs.validExitCodes -contains 3010) {
        Write-Warning "Un redémarrage peut être nécessaire pour terminer l'installation."
    }
} 
catch {
    Write-Error "Erreur lors de l'installation: $_"
    throw
}

# Supprimer l'installateur après l'installation pour économiser de l'espace
# Décommentez si nécessaire:
# Remove-Item $fileLocation -Force -ErrorAction SilentlyContinue