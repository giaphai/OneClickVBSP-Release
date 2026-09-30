param(
    [string]$TargetVersion = "v2026.09.30"
)

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = "d:\Git\OneClickVBSP\dev" }
$rootDir = Split-Path -Parent $scriptDir

$srcFile = Join-Path $scriptDir "decompressed_source.ps1"
$verFile = Join-Path $rootDir "version.txt"

if (Test-Path $srcFile) {
    $c = [System.IO.File]::ReadAllText($srcFile, [System.Text.Encoding]::UTF8)
    $c = [regex]::Replace($c, '(?m)^\$toolVersion\s*=\s*"[^"]+"', ('$toolVersion = "' + $TargetVersion + '"'))
    [System.IO.File]::WriteAllText($srcFile, $c, [System.Text.Encoding]::UTF8)
    Write-Host "[OK] Da cap nhat toolVersion trong decompressed_source.ps1 thanh $TargetVersion" -ForegroundColor Green
}

# Cap nhat currentVer trong OneClickVBSP.bat va OneClickVBSP_2026.ps1 (bootstrap header)
$batFile = Join-Path $rootDir "OneClickVBSP.bat"
if (Test-Path $batFile) {
    $c = [System.IO.File]::ReadAllText($batFile, [System.Text.Encoding]::UTF8)
    $c = [regex]::Replace($c, '-currentVer\s*"[^"]+"', ('-currentVer "' + $TargetVersion + '"'))
    $c = [regex]::Replace($c, '\[string\]\$currentVer\s*=\s*"[^"]+"', ('[string]$currentVer = "' + $TargetVersion + '"'))
    [System.IO.File]::WriteAllText($batFile, $c, [System.Text.Encoding]::UTF8)
    Write-Host "[OK] Da cap nhat currentVer trong OneClickVBSP.bat thanh $TargetVersion" -ForegroundColor Green
}

$ps1File = Join-Path $rootDir "OneClickVBSP_2026.ps1"
if (Test-Path $ps1File) {
    $c = [System.IO.File]::ReadAllText($ps1File, [System.Text.Encoding]::UTF8)
    $c = [regex]::Replace($c, '-currentVer\s*"[^"]+"', ('-currentVer "' + $TargetVersion + '"'))
    $c = [regex]::Replace($c, '\[string\]\$currentVer\s*=\s*"[^"]+"', ('[string]$currentVer = "' + $TargetVersion + '"'))
    [System.IO.File]::WriteAllText($ps1File, $c, [System.Text.Encoding]::UTF8)
    Write-Host "[OK] Da cap nhat currentVer trong OneClickVBSP_2026.ps1 thanh $TargetVersion" -ForegroundColor Green
}

[System.IO.File]::WriteAllText($verFile, ($TargetVersion + [Environment]::NewLine), [System.Text.Encoding]::UTF8)
Write-Host "[OK] Da cap nhat version.txt thanh $TargetVersion" -ForegroundColor Green
