<#
.SYNOPSIS
Installs and configures OpenSSH Server on Windows 10/11 or Windows Server.

.DESCRIPTION
This script must be run as Administrator. It installs the OpenSSH.Server capability,
sets the service to start automatically, starts the service, and ensures port 22 is open.
#>

# 1. Check for Administrator Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator. Please right-click PowerShell, select 'Run as Administrator', and try again."
    Exit
}

Write-Host "Starting OpenSSH Server installation..." -ForegroundColor Cyan

# 2. Install OpenSSH Server
Try {
    $sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    
    if ($sshCapability.State -ne 'Installed') {
        Write-Host "Downloading and installing OpenSSH Server capability..." -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name $sshCapability.Name -ErrorAction Stop
        Write-Host "OpenSSH Server installed successfully." -ForegroundColor Green
    } else {
        Write-Host "OpenSSH Server is already installed on this system." -ForegroundColor Green
    }
} Catch {
    Write-Error "Failed to install OpenSSH Server. Ensure you have an active internet connection or WSUS access. Error: $_"
    Exit
}

# 3. Configure and Start the SSH Service
Write-Host "Configuring the sshd service to start automatically..." -ForegroundColor Cyan
Try {
    Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction Stop
    Start-Service -Name sshd -ErrorAction Stop
    
    $serviceStatus = Get-Service -Name sshd
    if ($serviceStatus.Status -eq 'Running') {
        Write-Host "SSH Service (sshd) is configured and currently running." -ForegroundColor Green
    } else {
        Write-Warning "The SSH Service is configured, but it does not appear to be running."
    }
} Catch {
    Write-Error "Failed to configure or start the SSH service. Error: $_"
}

# 4. Configure Windows Firewall
Write-Host "Verifying Firewall Rules..." -ForegroundColor Cyan
Try {
    # The installation usually creates an 'OpenSSH-Server-In-TCP' rule by default.
    $firewallRule = Get-NetFirewallRule -Name *OpenSSH-Server-In-TCP* -ErrorAction SilentlyContinue
    
    if ($firewallRule) {
        Write-Host "Default OpenSSH firewall rule is present." -ForegroundColor Green
    } else {
        Write-Host "Default rule missing. Creating new Firewall rule for SSH (Port 22)..." -ForegroundColor Yellow
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction Stop
        Write-Host "Firewall rule created successfully." -ForegroundColor Green
    }
} Catch {
    Write-Warning "Failed to verify or set firewall rules. You may need to manually open port 22. Error: $_"
}

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Setup Complete! You can connect to this machine using:" -ForegroundColor White
Write-Host "ssh $env:USERNAME@$env:COMPUTERNAME" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan