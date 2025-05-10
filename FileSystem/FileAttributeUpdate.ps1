# Reference 1: https://devblogs.microsoft.com/scripting/use-a-powershell-cmdlet-to-work-with-file-attributes/
# Reference 2: https://devblogs.microsoft.com/scripting/use-powershell-to-toggle-the-archive-bit-on-files/

param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Path = $null,
    [Parameter(Mandatory=$false, ParameterSetName="AttributeSelection", Position=1)]
    [ValidateSet("ReadOnly", "Hidden", "System", "Directory", "Archive", "Device", "Normal", "Temporary", "SparseFile", "ReparsePoint", "Compressed", "Offline", "NotContentIndexed", "Encrypted", "IntegrityStream", "NoScrubData", "EA", "Pinned", "Unpinned", "RecallOnDataAccess", "RecallOnOpen", "SequentialScan", "RandomAccess", "NoBuffering", "WriteThrough", "Overlapped", "NoOverlapped", "DeleteOnClose", "BackupSemantics", "PosixSemantics", "SessionAware", "OpenReparsePoint", "OpenNoRecall", "FirstPipeInstance")]
    [string[]]$Attribute = $null,
    [Switch]$Set,
    [Switch]$Clear
)

if ((Test-Path -Path $Path -PathType Leaf) -eq $false) {
    if (Test-Path -Path $Path -PathType Container) {
        Write-Error -Message "Path is a directory, not a file: $Path"
    } else {
        Write-Error -Message "File not found : $Path"
    }
    exit
} elseif ($Set -and $Clear) {
    Write-Error -Message "Cannot set and clear attributes at the same time"
    exit
}

if ($null -eq $Attribute) {
    $attributes = [io.fileattributes].GetEnumNames()
} else {
    $attributes = $Attribute
}

foreach ($item in $attributes) {
    if ($Set) {
        Set-ItemProperty -Path $Path -Name Attributes -Value ((Get-ItemProperty -Path $Path).Attributes -bor [io.fileattributes]::$item)
        #$file.Attributes = $file.Attributes -bor [io.fileattributes]::$item
    }
    elseif ($Clear) {
        Set-ItemProperty -Path $Path -Name Attributes -Value ((Get-ItemProperty -Path $Path).Attributes -band -bnot [io.fileattributes]::$item)
        #$file.Attributes = $file.Attributes -bxor [io.fileattributes]::$item
    }
}

if ($Set -or $Clear) {
    Write-Host -ForegroundColor Yellow "Attributes for ${Path} have been updated"
    Write-Host -ForegroundColor Yellow "New attributes for ${Path}:"
} else {
    Write-Host -ForegroundColor Yellow "Attributes for ${Path}:"
}

foreach ($item in $attributes) {
    if ((Get-ItemProperty -Path $Path).Attributes -band [io.fileattributes]::$item) {
        Write-Host -ForegroundColor Green "$item is set"
    } else {
        Write-Host -ForegroundColor Red "$item is not set"
    }
}
