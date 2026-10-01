# PowerShell Computer Setup

This repository contains two elevated PowerShell scripts: `choco.ps1` installs a configured set of Chocolatey applications, and `admin-tools.ps1` installs selected Windows administration capabilities. Both scripts log their progress, skip items that are already installed, verify new installations, and return a non-zero exit code when an installation fails.

## Requirements

- Run the scripts in an elevated PowerShell session. Both use `#Requires -RunAsAdministrator` and also check administrator privileges.
- `choco.ps1` supports Windows 10, Windows 11, Windows Server 2019, and Windows Server 2022. Internet access is needed to install Chocolatey and download packages.
- `admin-tools.ps1` requires a Windows version and edition that provides the listed Windows capabilities. Windows may need access to Windows Update or a configured Features on Demand source to download capability payloads.
- The current PowerShell process must allow the commands and execution policy required by the scripts.

## Chocolatey Setup

Run `choco.ps1` from an elevated PowerShell prompt:

```powershell
.\choco.ps1
```

From another directory, invoke it by its full path:

```powershell
& "C:\path\to\powershell-choco-computer-setup\choco.ps1"
```

### What It Does

1. Creates `C:\Temp` if it does not exist and checks administrator privileges.
2. Checks whether `choco.exe` is available. If Chocolatey is missing, it temporarily sets the process execution policy to `Bypass`, enables TLS 1.2, downloads and runs Chocolatey's install script, refreshes the current process PATH, and verifies that Chocolatey is available.
3. Checks the configured application list. Packages detected by `choco list` are logged as already installed and are not reinstalled.
4. On a computer name matching the configured VDI pattern, skips applications listed in `$SkipApplications`.
5. Installs remaining packages with `choco install -y --no-progress`, checks Chocolatey's exit code, and verifies each package after installation.
6. Logs per-package failures, reports a summary, and exits with code `1` if any package installation or verification fails.

### Default Applications

The `$Applications` list in `choco.ps1` contains:

- `keepass`
- `omnissa-horizon-client`
- `powershell-core`
- `python314`
- `git`
- `vscode`
- `vscode-powershell`
- `vscode-python`
- `vscode-ansible`
- `vscode-kubernetes-tools`
- `vscode-terraform`

`omnissa-horizon-client` is in `$SkipApplications` and is skipped when the computer name matches the VDI pattern checked by the script. Edit `$Applications` to change the packages to install, and `$SkipApplications` to change the VDI exclusions.

### Chocolatey Log and Exit Codes

Logs are written to `C:\Temp\ChocoInstall.log` and to the console. Entries include timestamps, severity levels, and installation status.

- `0`: all configured packages were already installed, were installed and verified, or were intentionally skipped.
- `1`: one or more package installations or verifications failed, or the script could not validate administrator privileges.

## Windows Admin Tools

Run `admin-tools.ps1` from an elevated PowerShell prompt:

```powershell
.\admin-tools.ps1
```

The script checks each capability with `Get-WindowsCapability`. It skips capabilities already in the `Installed` state, installs the others with `Add-WindowsCapability`, then checks that each installation succeeded. Failures are recorded while the script continues through the list.

### Capabilities

The `$WindowsComponents` list in `admin-tools.ps1` includes:

- Failover Cluster Management Tools
- Active Directory Domain Services and Lightweight Directory Services Tools
- DNS Server Tools
- Group Policy Management Tools
- Remote Access Management Tools
- Server Manager Tools
- Shielded VM Tools
- Storage Migration Service Management Tools
- Volume Activation Tools

Edit `$WindowsComponents` in `admin-tools.ps1` to change the capabilities managed by the script. Capability availability can vary by Windows version and edition.

### Admin Tools Log and Exit Codes

Logs are written to `C:\Temp\AdminToolsInstall.log` and to the console. Entries include timestamps, severity levels, and the status of each capability.

- `0`: all listed capabilities are installed or were already installed.
- `1`: one or more capabilities failed to install or verify, or the script could not validate administrator privileges.
