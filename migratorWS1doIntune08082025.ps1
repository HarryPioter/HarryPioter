# === Zmienna do logowania ===
$logPath = "C:\ProgramData\MDM_Reenroll\reenroll_log.txt"
$null = New-Item -Path (Split-Path $logPath) -ItemType Directory -Force

# === Log funkcji ===


function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $message"
}
$KeepAppsInstalled = "true" #Próbuje zachować aplikacje na komputerze przez WS1

# === Deinstal i wyrejestrowanie z WS1 ===  
#Uninstall SFD Agent
if ($KeepAppsInstalled -eq "true") {
    $SFDAgent = Get-WmiObject -Class win32_product -Filter "Name like '%SFD%'"
    $Arguments = "/x $($SFDAgent.IdentifyingNumber) /q /norestart"
    try {
        Write-Log   "Starting uninstallation agenta SFD."
        Start-Process msiexec -ArgumentList $Arguments -Wait -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Error while uninstalling agenta SFD: $_"
        }
    }
  Write-Log "Deinstalation SFD Agent zakonczona."  


#Uninstall Agent - requires manual delete of device object in console
Write-Log "Starting to uninstall Workspace ONE Intelligent Hub."
$HUB = Get-WmiObject -Class win32_product -Filter "Name like '%Workspace ONE Intelligent%'"
$Arguments = "/x $($HUB.IdentifyingNumber) /q /norestart"
try {
    Write-Log "I m uninstalling Workspace ONE Intelligent Hub."
    # Start the uninstall process
   Start-Process msiexec -ArgumentList $Arguments -Wait -ErrorAction SilentlyContinue 
}
catch {
    write-Log "Error while uninstalling Workspace ONE Intelligent Hub: $_"
}

Write-Log "Workspace ONE Intelligent Hub uninstallation complete."

Start-Sleep -Seconds 120
Write-Log "Waited 120 seconds after agent uninstallation."

#uninstall WS1 App
Write-Log "Removing application WS1 (AirWatchLLC)."
try {
    Write-Log "Removing application WS1 (AirWatchLLC)."
    Get-AppxPackage *AirWatchLLC* | Remove-AppxPackage -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error removing application WS1 (AirWatchLLC): $_"
}

Write-Log "Application WS1 (AirWatchLLC) deleted."

#Delete reg keys
Write-Log "Deleting Airwatch registry keys."
try {
    Remove-Item -Path HKLM:\SOFTWARE\Airwatch -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys Airwatch: $_"
}

try {
    Remove-Item -Path HKLM:\SOFTWARE\AirwatchMDM -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys AirwatchMDM: $_"
}

#Remove enrollment specific entries
Write-Log "Deleting registry keys related to enrollments."
try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Enrollments\$($EnrollmentKey)" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to enrollments: $_"
}
try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\$($EnrollmentKey)" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to EnterpriseResourceManager: $_"
}
try {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxDefault\$($EnrollmentKey)" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to PolicyManager AdmxDefault: $_"
}
try{
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled\$($EnrollmentKey)" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to PolicyManager AdmxInstalled: $_"
}
try{
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\_ContainerAdmxDefault\*" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to PolicyManager current _ContainerAdmxDefault: $_"
}
try{
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\device\ApplicationManagement\*" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to PolicyManager device ApplicationManagement: $_"
}
try {
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\$($EnrollmentKey)" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to PolicyManager Providers: $_"
}
try{
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Session\$($EnrollmentKey)" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to Provisioning OMADM Session: $_"
}
try{
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsAnytimeUpgrade\Attempts\*" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to Windows Anytime Upgrade Attempts: $_"
}

#Cleanup other registry
Write-Log "I am cleaning up the remaining registry keys related to MDM."
try{
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Provisioning\omadm\Accounts\* -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to Provisioning omadm Accounts: $_"
}
try{
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger\* -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to Provisioning OMADM Logger: $_"
}
try{
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\*\MSI\* -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting registry keys related to EnterpriseDesktopAppManagement MSI: $_"
}
 
#Delete folders
try {
    Write-Log "I am deleting folders related to AirWatch."
    $path = "$env:ProgramData\AirWatch"
     Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Error deleting folder AirWatch: $_"
}

try {
    Write-Log "I am deleting folders related to AirWatchMDM."
    $path = "$env:ProgramData\AirWatchMDM"
Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue 
}
catch {
    Write-Log "Error deleting folder AirWatchMDM: $_"
}

try{
    Write-Log "I am deleting folders related to SfdAgent."
    $path = "$env:ProgramData\VMware\SfdAgent"
    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
} 
catch {
    Write-Log "Error deleting folder VMware SfdAgent: $_"
}
try {
#Clean Scheduled Tasks - SFD
Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\$($EnrollmentKey)\*" | Unregister-ScheduledTask  -Confirm:$false

$scheduleObject = New-Object -ComObject Schedule.Service
$scheduleObject.connect()
$rootFolder = $scheduleObject.GetFolder("\Microsoft\Windows\EnterpriseMgmt")
$rootFolder.DeleteFolder("$($EnrollmentKey)", $null)
}
catch {
    Write-Log "Error while deleting scheduled tasks related to SFD: $_"
}
try{
#Clean Scheduled Tasks - SFD
Get-ScheduledTask -TaskPath "\vmware\SfdAgent\*" | Unregister-ScheduledTask  -Confirm:$false

$scheduleObject = New-Object -ComObject Schedule.Service
$scheduleObject.connect()
$rootFolder = $scheduleObject.GetFolder("\vmware")
$rootFolder.DeleteFolder("SfdAgent", $null)
}
catch {
    Write-Log "Error when deleting scheduled tasks related to SfdAgent: $_"
}
#Delete user certificates
$UserCerts = Get-ChildItem cert:"CurrentUser" -Recurse
$UserCerts | Where-Object { $_.Issuer -like "*AirWatch*" -or $_.Issuer -like "*AwDeviceRoot*" } | Remove-Item -Force

#Delete device certificates
$DeviceCerts = Get-ChildItem cert:"LocalMachine" -Recurse
$DeviceCerts | Where-Object { $_.Issuer -like "*AirWatch*" -or $_.Issuer -like "*AwDeviceRoot*" } | Remove-Item -Force
# === End Deinstalation and unregister from WS1 ===  
# === Cleaning politics MDM ===
# Path to politics MDM
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"
if (Test-Path $regPath) {
    $autoEnroll = (Get-ItemProperty -Path $regPath -Name AutoEnrollMDM -ErrorAction SilentlyContinue).AutoEnrollMDM
    $credType   = (Get-ItemProperty -Path $regPath -Name UseAADCredentialType -ErrorAction SilentlyContinue).UseAADCredentialType

    Write-Log "Stan polityki MDM na tym komputerze:" -ForegroundColor Cyan
    Write-Log "AutoEnrollMDM: $autoEnroll"
    Write-log "UseAADCredentialType: $credType"

    if ($autoEnroll -eq 1 -and $credType -eq 1) {
        Write-log "Find Setting: Turn on with User Credentials." -ForegroundColor Yellow
        # Czyszczenie:
        Remove-Item -Path $regPath -Recurse -Force
        # gpupdate /force
    }
    else {
        Write-Log "Policy MDM not required cleaning."
    }
}
else {
    Write-Log "Lack of politics MDM in registry cleaning is not necessary."
}

# Turn on automatic registration MDM with user credentials
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"
New-Item -Path $path -Force | Out-Null
Set-ItemProperty -Path $path -Name "AutoEnrollMDM" -Value 1 -Type DWord
Set-ItemProperty -Path $path -Name "UseAADCredentialType" -Value 1 -Type DWord

# === Enroll do Intune ===     
Write-Log "Starting registration process devices to Intune"
Write-LOG "=== Enforce refreshing PRT from Azure AD ==="
dsregcmd /debug /refreshprt

Start-Sleep -Seconds 5

Write-Log "=== Check status AAD ==="
$dsregStatus = dsregcmd /status

if ($dsregStatus -match "AzureAdJoined\s*:\s*YES" -or $dsregStatus -match "DomainJoined\s*:\s*YES") {
    Write-Log "Device is connected with AAD or Hybrid AAD Join. Continue enrollment..."
} else {
    Write-Log "Device isn't Registered in Azure AD. Cancelling."
    exit 1
}

$enrollerPath = "$env:SystemRoot\System32\deviceenroller.exe"

# Set MDM Enrollment URL's
$key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'
$keyinfo = Get-Item "HKLM:\$key"
$url = $keyinfo.name
$url = $url.Split("\")[-1]
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"

New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force -ErrorAction SilentlyContinue
New-ItemProperty -LiteralPath $path  -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force -ErrorAction SilentlyContinue
New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force -ErrorAction SilentlyContinue

# === Path to tool enroller ===
$enrollerPath = "$env:SystemRoot\System32\deviceenroller.exe"
Write-Log "Starting: $enrollerPath /c /AutoEnrollMDM"
    try {
        Start-Process -FilePath $enrollerPath -ArgumentList "/c /AutoEnrollMDM" -Wait -NoNewWindow
        Write-Log "Register to MDM finished (no errors on system level)."
    }
    catch {
        Write-Log "Errors in starting registration: $_"
    }
# === System restart after 1 minutes (can be changed) ===
Write-Log "System restart for 5 minutes to complete the MDM enrollment process."
shutdown.exe /r /t 300 /c "Computer will be restared in 5 MINUTES to complete the MDM enrollment process."

# === End ===
Write-Log "Script ended"
