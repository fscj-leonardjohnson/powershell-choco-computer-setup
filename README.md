# PowerShell Chocolatey Computer Setup

This script installs Chocolatey if it is not already installed, then installs a predefined set of applications using Chocolatey. It also logs installation activity to `C:\Temp\ChocoInstall.log` and exits with a non-zero status if any package installation fails.

## Features

- Verifies the script is running as Administrator
- Installs Chocolatey automatically when needed
- Installs a configured list of applications
- Skips selected packages when running on a VDI machine
- Writes detailed logs to both the console and `C:\Temp\ChocoInstall.log`
- Validates package installation before continuing
- Returns an error code if any app fails to install

## Requirements

- Windows 10, Windows 11, Windows Server 2019, or Windows Server 2022
- PowerShell with Administrator privileges
- Internet access to download Chocolatey and package installers
- Execution policy permission for the current PowerShell session

## Script Behavior

The script performs the following steps:

1. Creates the log directory if it does not exist
2. Checks that the current user is an Administrator
3. Detects whether Chocolatey is installed
4. Installs Chocolatey if it is missing
5. Reads the list of applications from the configuration section
6. Installs each package using `choco install`
7. Verifies each product was installed successfully
8. Logs any failures and exits with status code `1` if needed

## Default Applications

The script installs these packages by default:

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

The following package is skipped on VDI machines:

- `omnissa-horizon-client`

## How to Run

Open PowerShell as Administrator and run:

```powershell
.\choco.ps1
```

If you are running from another directory, use:

```powershell
& "C:\path\to\powershell-choco-computer-setup\choco.ps1"
```

## Logging

The script writes logs to:

```text
C:\Temp\ChocoInstall.log
```

This log includes timestamps, log levels, and installation status for each action.

## Notes

- The script uses the `#Requires -RunAsAdministrator` directive, so it will not run without elevated privileges.
- Package names can be modified in the `$Applications` array at the top of the script.
- Additional packages can be added or removed by editing that list.
- The VDI skip list is controlled by `$SkipApplications`.

## Exit Codes

- `0` = all applications installed successfully
- `1` = one or more package installations failed
