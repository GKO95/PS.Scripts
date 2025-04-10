#Requires -RunAsAdministrator
param (
    [Parameter(Position=0)]
    [ValidateSet("RegistryKeyChangeEvent", "RegistryTreeChangeEvent", "RegistryValueChangeEvent")]
    [string]$Class = "RegistryKeyChangeEvent",
    [Parameter(Mandatory=$true)]
    [ValidateSet("HKEY_LOCAL_MACHINE", "HKLM", "HKEY_USERS", "HKU")]
    [string]$Root,
    [Parameter(Mandatory=$true)]
    [string]$Key,
    [Parameter(Mandatory=$false)]
    [string]$Value = $null
)

# Map aliases to full registry root names
switch -Exact ($Root) {
    "HKLM" { $Root = "HKEY_LOCAL_MACHINE" }
    "HKU"  { $Root = "HKEY_USERS" }
}

# Check if the registry value exists if Class is RegistryValueChangeEvent
try {
    $fullKeyPath = "Registry::$(Join-Path -Path $Root -ChildPath $Key)"
    if ($PSBoundParameters.ContainsKey('Value')) {
        if ($Class -eq "RegistryValueChangeEvent") {
            Get-ItemProperty -Path $fullKeyPath -Name $Value -ErrorAction Stop | Out-Null
        } else {
            Write-Warning "The Value parameter is not needed for $Class."
            Get-ItemProperty -Path $fullKeyPath -ErrorAction Stop | Out-Null
        }
    } else {
        Get-ItemProperty -Path $fullKeyPath -ErrorAction Stop | Out-Null
    }
} catch {
    $PSCmdlet.ThrowTerminatingError($PSItem)
}

# Generate a WMI query based on the registry event type
# Adding escape backslashes in the key path if needed
$query = "SELECT * FROM $Class WHERE Hive='$Root'"
switch -Exact ($Class) {
    "RegistryTreeChangeEvent"  { $query += " AND RootPath='$($Key -replace '(?<!\\)\\(?!\\)', '\\')'" }
    "RegistryKeyChangeEvent"   { $query += " AND KeyPath='$($Key -replace '(?<!\\)\\(?!\\)', '\\')'" }
    "RegistryValueChangeEvent" { $query += " AND KeyPath='$($Key -replace '(?<!\\)\\(?!\\)', '\\')' AND ValueName='$Value'" }
}

# Create a ManagementEventWatcher object
$watcher = New-Object System.Management.ManagementEventWatcher $query

# Register an event that gets fired when an event arrives
$evtjob = Register-ObjectEvent -InputObject $watcher -EventName "EventArrived" -Action {
    $evtnew = $event.SourceEventArgs.NewEvent
    Write-Host "Event occurred: $($evtnew.ClassPath)"
} -MaxTriggerCount 1

$watcher.Start()
Write-Host "Listening for registry change on ${Root}:\${Key}..."

while ($evtjob.State -ne "Stopped") {
    Start-Sleep -Seconds 1
}
Write-Host "End of script."
