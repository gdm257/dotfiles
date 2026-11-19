$ErrorActionPreference = "Stop"
$prov = @(Get-AppxProvisionedPackage -Online | ForEach-Object { $_.DisplayName })
$bad = @(Get-AppxPackage -AllUsers |
    Where-Object { $prov -notcontains $_.Name } |
    Select-Object -ExpandProperty Name -Unique | Sort-Object)
foreach ($name in $bad) {
    "MSIX: $name"
}
if ($bad.Count -gt 0) { exit 1 }
exit 0
