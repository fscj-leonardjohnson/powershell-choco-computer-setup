<#
.SYNOPSIS
    Installs Windows administration tools if they are not already installed.

.DESCRIPTION
    This script:
    - Verifies it is running with Administrator privileges
    - Installs Windows capabilities if necessary
    - Logs all actions to C:\Temp\AdminToolsInstall.log
    - Verifies installations
    - Returns a non-zero exit code if any installation fails
#>

#Requires -RunAsAdministrator

#region Configuration

$LogDirectory = "C:\Temp"
$LogFile = Join-Path $LogDirectory "AdminToolsInstall.log"

$WindowsComponents = @(
	"Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0"
	"Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
	"Rsat.Dns.Tools~~~~0.0.1.0"
	"Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
	"Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0"
	"Rsat.ServerManager.Tools~~~~0.0.1.0"
	"Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0"
	"Rsat.VolumeActivation.Tools~~~~0.0.1.0"
)

#endregion Configuration

#region Logging Functions

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "$Timestamp [$Level] $Message"

    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry
}

#endregion Logging Functions

#region Pre-Requisites

if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

try {
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

    if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "ERROR: Unable to validate Administrator privileges."
    Write-Host $_.Exception.Message
    exit 1
}

#endregion Pre-Requisites

#region Windows Component Check

function Test-WindowsComponentInstalled {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Component
    )

    $Capability = Get-WindowsCapability -Online -Name $Component -ErrorAction Stop
    return $Capability.State -eq "Installed"
}

#endregion Windows Component Check

#region Windows Component Installation

Write-Log "Script started."
Write-Log "Computer name: $($env:COMPUTERNAME)"
Write-Log "OS: $($PSVersionTable.OS)"
Write-Log "PowerShell: $($PSVersionTable.PSVersion)"

$FailedComponents = @()

foreach ($Component in $WindowsComponents) {
    try {
        if (Test-WindowsComponentInstalled -Component $Component) {
            Write-Log "$Component is already installed."
        }
        else {
            Write-Log "Installing Windows capability: $Component"

            Add-WindowsCapability -Online -Name $Component -ErrorAction Stop | Out-Null
            Write-Log "Installation command completed for $Component."

            if (Test-WindowsComponentInstalled -Component $Component) {
                Write-Log "Verification successful for $Component."
            }
            else {
                throw "Capability verification failed."
            }
        }
    }
    catch {
        Write-Log "Failed to install $Component. $($_.Exception.Message)" "ERROR"
        $FailedComponents += $Component
    }
}

#endregion Windows Component Installation

#region Summary and Exit Code

if ($FailedComponents.Count -gt 0) {
    Write-Log "One or more Windows capability installations failed." "ERROR"

    foreach ($Component in $FailedComponents) {
        Write-Log "Failed Component: $Component" "ERROR"
    }

    Write-Log "Script completed with errors." "ERROR"
    exit 1
}

Write-Log "All Windows capabilities are installed successfully."
Write-Log "Script completed successfully."

exit 0

#endregion Summary and Exit Code