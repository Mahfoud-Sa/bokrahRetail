<#
.SYNOPSIS
    Builds the Inno Setup installer for Bokrah Retail.
#>
param(
    [string]$Version,
    [string]$OutputBaseFilename
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Get-Item $scriptDir).Parent.FullName
$issFile = Join-Path $scriptDir "setup.iss"

# Determine Version if not provided
if (-not $Version) {
    $pubspecPath = Join-Path $rootDir "pubspec.yaml"
    if (Test-Path $pubspecPath) {
        $versionLine = Get-Content $pubspecPath | Where-Object { $_ -match '^version:\s*(.+)$' } | Select-Object -First 1
        if ($versionLine -and ($versionLine -match '^version:\s*([^\+]+)')) {
            $Version = $matches[1].Trim()
        }
    }
    if (-not $Version) {
        $Version = "3.5.1"
    }
}

if (-not $OutputBaseFilename) {
    $OutputBaseFilename = "bokrah-retailer-setup-$Version"
}

# Locate ISCC.exe
$isccPaths = @(
    (Get-Command iscc.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    "C:\Program Files\Inno Setup 7\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)

$iscc = $isccPaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $iscc) {
    Write-Error "Inno Setup compiler (ISCC.exe) not found. Please install Inno Setup 7."
    exit 1
}

Write-Host "Using Inno Setup Compiler: $iscc"
Write-Host "Compiling installer version $Version ($OutputBaseFilename.exe)..."

& $iscc "/DMyAppVersion=$Version" "/DOutputBaseFilename=$OutputBaseFilename" "$issFile"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Installer created successfully in dist\$OutputBaseFilename.exe"
