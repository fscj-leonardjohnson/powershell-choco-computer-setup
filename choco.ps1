<#
.SYNOPSIS
    Installs Chocolatey (if not already installed) and installs a list of applications.

.DESCRIPTION
    This script:
    - Verifies it is running with Administrator privileges
    - Installs Chocolatey if necessary
    - Installs one or more applications via Chocolatey
    - Logs all actions to C:\Temp\ChocoInstall.log
    - Verifies installations
    - Returns a non-zero exit code if any installation fails

.NOTES
    Compatible with:
    - Windows 10
    - Windows 11
    - Windows Server 2019
    - Windows Server 2022
#>

#Requires -RunAsAdministrator

#region Configuration

$LogDirectory = "C:\Temp"
$LogFile = Join-Path $LogDirectory "ChocoInstall.log"

# Add additional packages as needed
$Applications = @(
    "keepass",
    "omnissa-horizon-client",
    "powershell-core",
    "python314",
    "git",
    "vscode",
    "vscode-powershell",
    "vscode-python",
    "vscode-ansible",
    "vscode-kubernetes-tools",
    "vscode-terraform"
)

# Skip packages on VDI
$SkipApplications = @(
    "omnissa-horizon-client"
)

#endregion Configuration

#region Logging Functions

function Write-Log {
    <#
    .SYNOPSIS
    Writes out log messages to both the screen and log file.

    .PARAMETER Message
    The message to output to the log.

    .PARAMETER Level
    The log level identifier. INFO is set if no level is passed.

    #>
    param(
        [Parameter(
            Mandatory,
            HelpMessage = "This is the text that will appear in the log."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO","WARN","ERROR")]
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

#region Chocolatey Installation

function Test-ChocolateyInstalled {
    <#
    .SYNOPSIS
    Tests to see wheter Chocolatey is installed.

    #>
    try {
        $null = Get-Command choco.exe -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Install-Chocolatey {
    <#
    .SYNOPSIS
    Installs Chocolatey if it is not detected on the system.

    #>
    try {
        Write-Log "Chocolatey not detected. Beginning installation."

        Set-ExecutionPolicy Bypass -Scope Process -Force
        Write-Log "Execution policy set to Bypass for current process."

        [System.Net.ServicePointManager]::SecurityProtocol = `
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Write-Log "TLS 1.2 enabled."

        $InstallScript = ((New-Object System.Net.WebClient).DownloadString(
            'https://community.chocolatey.org/install.ps1'
        ))

        Invoke-Expression $InstallScript

        Write-Log "Chocolatey installation completed."

        # Refresh PATH for current session
        $env:Path = [System.Environment]::GetEnvironmentVariable(
            "Path",
            [System.EnvironmentVariableTarget]::Machine
        ) + ";" + `
        [System.Environment]::GetEnvironmentVariable(
            "Path",
            [System.EnvironmentVariableTarget]::User
        )

        Write-Log "Environment variables refreshed."

        if (-not (Test-ChocolateyInstalled)) {
            throw "Chocolatey installation verification failed."
        }

        Write-Log "Chocolatey verification successful."
    }
    catch {
        Write-Log "Chocolatey installation failed. $($_.Exception.Message)" "ERROR"
        throw
    }
}

if (Test-ChocolateyInstalled) {
    Write-Log "Chocolatey is already installed."
}
else {
    Install-Chocolatey
}

#endregion Chocolatey Installation

#region Package Check

function Test-PackageInstalled {
    <#
    .SYNOPSIS
    Checks to see if the current package is already installed on the system.

    #>
    param (
        [Parameter(
            Mandatory,
            HelpMessage = "This is the package name to check to see if it is already installed."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Package
    )

    $InstalledPackages = choco list

    if ($InstalledPackages -match "^$Package(\s|\.|$)"){
        return $true
    }
    else {
        return $false
    }
    
}

function Test-SkipVDIInstall {
    <#
    .SYNOPSIS
    Checks to see if the current package needs to be installed on the VDI.

    #>
    param (
        [Parameter(
            Mandatory,
            HelpMessage = "This is the package name to check to see if it needs to be installed on a VDI."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Package
    )

    if ($env:COMPUTERNAME -match "VDI*") {
        if ($Package -in $SkipApplications) {
            return $true
        }
    }
    return $false
}


#endregion Package Check

#region Package Installation

Write-Log "Script started."
Write-Log "Computer name: $($env:COMPUTERNAME)"
Write-Log "OS: $($PSVersionTable.OS)"
Write-Log "PowerShell: $($PSVersionTable.PSVersion)"

$FailedPackages = @()

foreach ($Application in $Applications) {

    try {

        if (Test-PackageInstalled($Application)) {
            Write-Log "$Application already installed."
        }
        elseif (Test-SkipVDIInstall($Application)) {
            Write-Log "Skipping $Application installation because the system is VDI."
        }
        else {
            Write-Log "Installing package: $Application"

            choco install $Application -y --no-progress

            if ($LASTEXITCODE -ne 0) {
                throw "Chocolatey returned exit code $LASTEXITCODE."
            }

            Write-Log "Installation command completed for $Application."

            if (Test-PackageInstalled($Application)) {
                Write-Log "Verification successful for $Application."
            }
            else {
                throw "Package verification failed."
            }
        }
    }
    catch {
        Write-Log "Failed to install $Application. $($_.Exception.Message)" "ERROR"
        $FailedPackages += $Application
    }
}

#endregion Package Installation

#region Summary and Exit Code

if ($FailedPackages.Count -gt 0) {

    Write-Log "One or more package installations failed." "ERROR"

    foreach ($Package in $FailedPackages) {
        Write-Log "Failed Package: $Package" "ERROR"
    }

    Write-Log "Script completed with errors." "ERROR"
    exit 1
}

Write-Log "All applications installed successfully."
Write-Log "Script completed successfully."

exit 0

#endregion Summary and Exit Code