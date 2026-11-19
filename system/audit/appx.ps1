param(
    [Parameter(Position = 0)][string]$Mode,
    [Parameter(Position = 1)][string]$Path
)
$ErrorActionPreference = "Stop"
switch ($Mode) {
    "probe" {
        if (Get-AppxPackage -AllUsers Microsoft.DesktopAppInstaller) { exit 0 }
        exit 1
    }
    "register" {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    }
    "install" {
        Add-AppxPackage -Path $Path
    }
    default {
        Write-Error "appx: unknown mode $Mode"
        exit 1
    }
}
