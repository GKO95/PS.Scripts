# URL: https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki
# Package: Precompiled Binaries for 64-bit Windows (.NET Framework 4.6)

#Requires -RunAsAdministrator
param (
    [Parameter(Mandatory=$false, Position=0)]
    [ValidatePattern('^[^\\\/:*?"<>|]+\.srd$')]
    [string]$Repository = "C:\ProgramData\Microsoft\Windows\AppRepository\StateRepository-Machine.srd",
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[^\\\/:*?"<>|]+\.dll$')]
    [string]$SQLite = "*.SQLite.dll"
)

# Resolve the path to the SQLite assembly.
$pathSQL = Resolve-Path -Path $SQLite
if ($pathSQL.Length -eq 0) {
    Write-Error "No assembly found."
    exit
} else {
    if ($pathSQL.Length -gt 1) {
        Write-Warning "Multiple assemblies found. Selecting the first SQLite assembly found..."
    }

    New-Variable -Name "assembly"
    New-Variable -Name "erract" -Value $ErrorActionPreference

# Load the SQLite assembly.
# The SQLite assembly is the first assembly that has the scope name "System.Data.SQLite.dll".
    $ErrorActionPreference = "SilentlyContinue"
    foreach ($path in $pathSQL) {
        Clear-Variable -Name "assembly"
        $assembly = [Reflection.Assembly]::LoadFile($path)
        if (($assembly -ne $null) -and ($assembly.Modules[0].ScopeName -eq "System.Data.SQLite.dll")) {
            Write-Host "SQLite path: $($path) (version $($assembly.GetName().Version))"
            break
        }
        Clear-Variable -Name "assembly"
    }
    if ($null -eq $assembly) {
        Write-Error "No SQLite assembly found."
        exit
    }
    $ErrorActionPreference = $erract

    Remove-Variable -Name "erract"
    Remove-Variable -Name "assembly"
}

# Resolve the path to the repository.
$pathRepo = Resolve-Path -Path $Repository
if ($pathRepo.Length -eq 0) {
    Write-Error "No repository found."
    exit
} elseif ($pathRepo.Length -gt 1) {
    $pathRepo = $pathRepo[0]
    Write-Warning "Multiple repositories found. Selected the first repository found: $pathRepo"
}
Write-Host "Repository path: $pathRepo"

# Read the repository with SQLite.
# Note: Bundle package do not require SQLite.Interop.dll dependency.
try {
    $sqliteDBConnection = New-Object System.Data.SQLite.SQLiteConnection -ErrorAction Stop
    $sqliteDBConnection.ConnectionString = "data source=$($pathRepo)"
    $sqliteDBConnection.open()

    $sqliteDBCommand=$sqliteDBConnection.CreateCommand()
    $sqliteDBCommand.Commandtext="SELECT * from PACKAGE"
    $sqliteDBCommand.CommandType = [Data.CommandType]::Text
    $dbReader = $sqliteDBCommand.ExecuteReader()

    $index = 0
    while ($dbReader.HasRows) {
        if ($dbReader.Read()) {
            Write-Host ("{0:000}. {1}" -f ++$index, $dbReader['PackageFullName'])
        }
    }
    $dbReader.Close()
    $sqliteDBConnection.Close()
} catch {
    $PSCmdlet.ThrowTerminatingError($PSItem)
}
