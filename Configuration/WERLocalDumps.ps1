#Requires -RunAsAdministrator
param (
    [Parameter(Mandatory=$false, Position=0)]
    [ValidatePattern('^[^\\\/:*?"<>|]+\.exe$')]
    [string]$Process = $null,
    [Parameter(Mandatory=$false)]
    [ValidateSet(0, 1, 2)]
    [Uint32]$DumpType = 1,
    [Parameter(Mandatory=$false)]
    [UInt32]$DumpCount = 10,
    [Parameter(Mandatory=$false)]
    [string]$DumpFolder = "%LocalAppData%\CrashDumps",
    [Parameter(Mandatory=$false)]
    [Uint32]$CustomDumpFlags = 0x121
)

$regWerDump = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps"

# If the registry key for LocalDumps does not exist, create it.
if ((Test-Path -Path $regWerDump -PathType Container) -eq $false) {
    New-Item -Path $regWerDump
}

# If the process name is not empty, create a subkey for the process under LocalDumps.
if ($Process.EndsWith(".exe")) {
    $regWerDump = Join-Path -Path $regWerDump -ChildPath $Process
    New-Item -Path $regWerDump
}

# Set the registry values for WER user mode dumps.
switch -Exact ($PSBoundParameters.Keys)
{
    "DumpType"        {Set-ItemProperty -Path $regWerDump -Name "DumpType" -Type "DWord" -Value $DumpType}
    "DumpCount"       {Set-ItemProperty -Path $regWerDump -Name "DumpCount" -Type "DWord" -Value $DumpCount}
    "DumpFolder"      {Set-ItemProperty -Path $regWerDump -Name "DumpFolder" -Type "ExpandString" -Value $DumpFolder}
    "CustomDumpFlags" {Set-ItemProperty -Path $regWerDump -Name "CustomDumpFlags" -Type "DWord" -Value $CustomDumpFlags}
}
