#Requires -RunAsAdministrator
param (
    [Parameter(Mandatory=$true, Position=0)]
    [string[]]$Svchost,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Own", "Share")]
    [string]$Type
)

# Enumerate each group of services.
foreach ($group in $Svchost) {

    # Check if the group exists in the registry.
    try {
        $services = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost" -Name $group -ErrorAction Stop |
            Select-Object -ExpandProperty $group
    } catch [System.Management.Automation.PSArgumentException] {
        Write-Error "Unable to get services for `"$group`". Please check the group name and try again."
        continue
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
        exit
    }

    # Configure each service in the group.
    foreach ($service in $services) {
        try {

            # Check if the service exists, and configure it.
            Get-Service -Name $service -ErrorAction Stop | Out-Null
            $result = Invoke-Command -ScriptBlock {sc.exe config $service type= $Type} -ErrorAction Stop

            # Check if the configuration was successful.
            if ($result[0] -is [string] -and $result[0] -match 'FAILED (?<errnum>\d+):') {
                switch ($matches.errnum) {
                    5 {Write-Warning "Requires elevated privilege: $service"}
                    default {Write-Error "Failed to configure service $service as $Type. Error code: ${matches.errnum}"}
                }
            }
        } catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
            Write-Warning "Service not found in registry: $service"
            continue
        } catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
            exit 
        }
    }
}
