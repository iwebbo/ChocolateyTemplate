# Enterprise Chocolatey Template for 64-bit Applications

This template is designed to create Chocolatey packages for enterprise environments, supporting a wide range of 64-bit applications from a local installer file, with intelligent detection of installer types.

## Key Features

- **Automatic installer type detection** for various applications (dotnet, Java, browsers, etc.)
- **Smart silent arguments configuration** based on installer type
- **Automatic checksum calculation** for file integrity verification
- **Post-installation testing** for runtime environments
- **Support for multiple installer formats** (.exe, .msi, .msixbundle, .msp)
- **Detailed logging** for troubleshooting

## Usage

1. Create a new package based on this template:
   ```
   Copy template-64bits in C:\ProgramData\chocolatey\templates
   choco new mypackage -t=template-64bit
   ```

2. Download the 64-bit installer for your application and rename it:
   - Name format: `[packagename]-x64.[extension]`
   - Example: `firefox-x64.exe` for a Firefox package
   - Place this file in the `tools` folder of your package

3. Edit the generated files with information specific to your package:
   - `mypackage.nuspec`: General package information
   - Other settings will be automatically detected

4. Build the package:
   ```
   choco pack mypackage.nuspec
   ```

5. Test the package locally:
   ```
   choco install mypackage -s="." -f --debug --verbose
   ```

## Supported Installer Types

The template automatically detects and configures appropriate silent installation arguments for:

| Installer Type | Detection Method | Silent Arguments |
|----------------|------------------|------------------|
| Inno Setup | File metadata | `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-` |
| NSIS | File metadata | `/S` |
| InstallShield | File metadata | `/s /v"/qn /norestart"` |
| Microsoft (.NET) | Product name | `/install /quiet /norestart` |
| Java | Company/product info | `/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0` |
| MSI | File extension | `/qn /norestart` |
| MSIX/AppX | File extension | Uses Add-AppxPackage cmdlet |
| Other types | Default | `/quiet /norestart` |

## Examples for Common Applications

### Microsoft .NET Runtime
```
choco new dotnet-runtime -t=enterprise-64bit
# Download dotnet-runtime-8.0.x-win-x64.exe to tools/dotnet-runtime-x64.exe
# Package will automatically use correct silent arguments: /install /quiet /norestart
```

### Firefox
```
choco new firefox -t=enterprise-64bit
# Download Firefox installer to tools/firefox-x64.exe
# Package will automatically detect NSIS installer and use /S silent argument
```

### Java Runtime
```
choco new jre -t=enterprise-64bit
# Download Java installer to tools/jre-x64.exe
# Package will automatically detect Java installer and use appropriate arguments
```

## Testing Your Package

1. Build the package:
   ```
   choco pack mypackage.nuspec
   ```

2. Install the package locally:
   ```
   choco install mypackage -s="." -f
   ```

3. For debugging installation issues:
   ```
   choco install mypackage -s="." -f --debug --verbose
   ```

4. Check installation logs:
   ```
   Get-Content "C:\ProgramData\chocolatey\logs\chocolatey.log" -Tail 50
   ```

5. Uninstall to test removal:
   ```
   choco uninstall mypackage -f
   ```

## Customizing the Template

If you need to customize the template for specific application types:

1. Edit the switch statement in chocolateyInstall.ps1 to add detection for your specific application.
2. Add appropriate silent arguments for your installer type.
3. Extend the post-installation tests if needed.

## Troubleshooting

- **Installation fails**: Check the Chocolatey logs at `C:\ProgramData\chocolatey\logs\chocolatey.log`
- **Application doesn't work after install**: Some applications require a system restart
- **Lock file errors**: Delete any Chocolatey lock files in `C:\ProgramData\chocolatey\lib\`
- **Path issues**: Try refreshing environment variables or restarting your command prompt