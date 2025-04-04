# Chocolatey Template for 64-bit Applications with Local Installer

This template is designed to create Chocolatey packages specifically configured for 64-bit applications using a local installer file.

## Usage

1. Create a new package based on this template:
   ```
   choco new mypackage -t=64bit-local
   ```

2. Download the 64-bit installer for your application and rename it:
   - The file should be named `[packagename]-x64.exe` or `[packagename]-x64.msi`
   - For example, if your package is named "mypackage", the installer should be named `mypackage-x64.exe`
   - Place this file in the `tools` folder of your package

3. Edit the generated files with information specific to your package:
   - `mypackage.nuspec`: General package information
   - `tools/chocolateyInstall.ps1`: Installation script (adjust silent installation arguments)
   - `tools/chocolateyUninstall.ps1`: Uninstallation script

4. Build the package:
   ```
   choco pack mypackage.nuspec
   ```

## Template Variables

- `[[PackageName]]`: Package name
- `[[PackageNameLower]]`: Package name in lowercase
- `[[PackageVersion]]`: Package version
- `[[MaintainerName]]`: Maintainer's name
- `[[InstallerType]]`: Installer type ('exe' or 'msi')
- `[[SilentArgs]]`: Arguments for silent installation
- `[[UninstallArgs]]`: Arguments for silent uninstallation
- `[[LicenseType]]`: License type (e.g., MIT, Apache-2.0)
- `[[ProjectUrl]]`: Project URL
- `[[IconUrl]]`: Icon URL
- `[[PackageSourceUrl]]`: Package source code URL
- `[[DocsUrl]]`: Documentation URL
- `[[BugTrackerUrl]]`: Bug tracker URL
- `[[PackageSummary]]`: Package summary
- `[[PackageDescription]]`: Detailed package description
- `[[AdditionalNotes]]`: Additional notes
- `[[ReleaseNotes]]`: Release notes

## Practical Example: DBeaver

1. Create the package:
   ```powershell
   choco new dbeaver-ce -t=64bit-local
   ```

2. Download and rename the DBeaver Community Edition 64-bit installer:
   ```powershell
   # Download the file
   Invoke-WebRequest -Uri "https://dbeaver.io/files/dbeaver-ce-latest-x86_64-setup.exe" -OutFile "dbeaver-ce-x64.exe"
   
   # Move to the tools folder
   Move-Item "dbeaver-ce-x64.exe" "dbeaver-ce\tools\"
   ```

3. Edit `chocolateyInstall.ps1` to set the correct silent installation arguments:
   ```powershell
   $packageArgs = @{
     # ... other parameters already present ...
     silentArgs     = '/S /ALLUSERS'
   }
   ```

4. Build the package:
   ```powershell
   choco pack dbeaver-ce\dbeaver-ce.nuspec
   ```

## Common Silent Installation Arguments

### EXE Installers
```powershell
# For InnoSetup installers
silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'

# For NSIS installers
silentArgs     = '/S'

# For InstallShield installers
silentArgs     = '/s /v"/qn /norestart"'
```

### MSI Installers
```powershell
# Standard MSI arguments
silentArgs     = '/qn /norestart'

# With additional properties
silentArgs     = '/qn /norestart ALLUSERS=1 REBOOT=ReallySuppress'
```

## Advanced Tips

- **Automatic checksum calculation**: You can add this code to your installation script to automatically calculate the checksum:
  ```powershell
  # Calculate checksum automatically
  $actualChecksum = Get-FileHash -Path $fileLocation -Algorithm SHA256 | Select-Object -ExpandProperty Hash
  Write-Host "File checksum: $actualChecksum"
  
  $packageArgs.Add("checksum64", $actualChecksum)
  $packageArgs.Add("checksumType64", 'sha256')
  ```

- **Multiple format support**: If your application can have different installation formats, you can adapt the code:
  ```powershell
  # Look for installer in multiple possible formats
  $possibleExtensions = @('exe', 'msi', 'zip')
  $fileLocation = $null
  
  foreach ($ext in $possibleExtensions) {
      $possibleFile = Join-Path $toolsDir "[[PackageNameLower]]-x64.$ext"
      if (Test-Path $possibleFile) {
          $fileLocation = $possibleFile
          $packageArgs.fileType = $ext
          break
      }
  }
  ```

Note: Chocolatey packages containing large installers are generally not accepted in the public Chocolatey.org repository, but they are perfect for private/enterprise repositories.