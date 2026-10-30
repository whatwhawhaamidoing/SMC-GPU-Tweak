<#
.SYNOPSIS
  Applies the SMC GPU fix v2.5 to a phone that already has the game. Pushes
  res_patch\ (the three mech configs) and moves the dead buckets left behind by
  v2.0 / v2.2 / v2.3 aside. Nothing outside res_patch\ is touched, and nothing
  in res_patch\ on the phone is deleted.

.EXAMPLE
  .\deploy_gpu_fixes.ps1                push the configs and retire the dead buckets
  .\deploy_gpu_fixes.ps1 -CheckOnly     report what would change, touch nothing
  .\deploy_gpu_fixes.ps1 -KeepRetired   push, but leave the dead buckets where they are
  .\deploy_gpu_fixes.ps1 -Serial XYZ    only needed when more than one device is up
  .\deploy_gpu_fixes.ps1 -AdbPath "C:\platform-tools\adb.exe"   when adb is not on PATH
#>
[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [switch]$KeepRetired,
    [string]$Serial = '',
    [string]$AdbPath = ''
)

$ErrorActionPreference = 'Stop'
$Root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Package = 'com.netease.g93na'
$Smc     = "/sdcard/Android/data/$Package/files/netease/smc"
$DestRp  = "$Smc/res_patch"

if ($AdbPath) {
    $Adb = $AdbPath
} elseif (Test-Path (Join-Path $Root 'platform-tools\adb.exe')) {
    $Adb = Join-Path $Root 'platform-tools\adb.exe'
} else {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { $Adb = $cmd.Source }
    else { Write-Host '[!] no adb found: install platform-tools, or pass -AdbPath C:\path\to\adb.exe' -ForegroundColor Red; exit 1 }
}
if (-not (Test-Path $Adb)) { Write-Host "[!] no adb at $Adb" -ForegroundColor Red; exit 1 }

# Buckets that v2.0 / v2.2 / v2.3 left on phones. None of them loads anything:
# the keys were computed from the wrong spelling of the request path, and the
# shader and device-table payloads sit in paths an archive already serves, which
# res_patch is never asked about. Measured 2026-10-31; see HOW-IT-WORKS.md.
# They are moved, not deleted, so they stop being mistaken for active patches.
$Retired = @('902', '121', '230', '436', '654', '96', '236', '186', '72', '52',
             '616', '510', '159', '942', '554')

function Adb {
    param([string[]]$AdbArgs)
    # adb writes progress to stderr, which ErrorActionPreference=Stop would turn
    # into a terminating error on a push that worked.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $a = @()
        if ($Serial) { $a += @('-s', $Serial) }
        $a += $AdbArgs
        $lines = & $Adb $a 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    [pscustomobject]@{ Code = $code; Text = (($lines | Out-String).Trim()) }
}

# A res_patch tree is <bucket>/<hash64>; flatten it into pushable rows.
function Payload($dir) {
    Get-ChildItem -Path $dir -Directory | Sort-Object Name | ForEach-Object {
        $b = $_.Name
        Get-ChildItem -Path $_.FullName -File | Sort-Object Name |
            ForEach-Object { [pscustomobject]@{ Bucket = $b; Name = $_.Name;
                       FullName = $_.FullName; Length = $_.Length } }
    }
}

$dev = @(($(Adb @('devices')).Text) -split "`r?`n") | Where-Object { $_ -match "`tdevice$" }
if ($dev.Count -eq 0) { Write-Host '[!] no device connected' -ForegroundColor Red; exit 1 }
Write-Host ("[ok] " + ($dev -join '; ')) -ForegroundColor Green

$files = @(Payload (Join-Path $Root 'res_patch'))
if ($files.Count -eq 0) { Write-Host '[!] res_patch\ has no bucket folders' -ForegroundColor Red; exit 1 }

$manifest = Join-Path $Root 'res_patch\manifest.json'
$version = 'v2.5'
if (Test-Path $manifest) {
    $m = Get-Content $manifest -Raw | ConvertFrom-Json
    if ($m.version) { $version = $m.version }
}

Write-Host ''
Write-Host "GPU fix $version - res_patch\ holds $($files.Count) payload(s) in $(($files.Bucket | Select-Object -Unique).Count) bucket(s):" -ForegroundColor Cyan
foreach ($f in $files) {
    Write-Host ("  {0,6}  {1}  {2,9:N0} B" -f $f.Bucket, $f.Name, $f.Length)
}

if (-not $KeepRetired) {
    Write-Host ''
    Write-Host 'checking for dead buckets to retire:' -ForegroundColor Yellow
    $found = @()
    foreach ($b in $Retired) {
        $r = Adb @('shell', "test -d '$DestRp/$b' && echo present || echo absent")
        if ($r.Text -match 'present') { $found += $b }
    }
    if ($found.Count -eq 0) {
        Write-Host '  none - this phone has no v2.0/v2.2/v2.3 leftovers'
    } else {
        foreach ($b in $found) { Write-Host ("  {0,6}  present -> will move to retired/" -f $b) }
    }
}

if ($CheckOnly) { Write-Host '' '-CheckOnly: nothing was pushed.' -ForegroundColor Cyan; exit 0 }

foreach ($b in ($files.Bucket | Select-Object -Unique)) {
    $null = Adb @('shell', 'mkdir', '-p', "$DestRp/$b")
}
$i = 0
foreach ($f in $files) {
    $i++
    Write-Host ("  [{0}/{1}] bucket {2}: {3}" -f $i, $files.Count, $f.Bucket, $f.Name) -NoNewline
    $r = Adb @('push', $f.FullName, "$DestRp/$($f.Bucket)/$($f.Name)")
    if ($r.Code -ne 0) { Write-Host ' FAILED' -ForegroundColor Red; Write-Host $r.Text; exit 1 }
    Write-Host ' ok' -ForegroundColor Green
}

if (-not $KeepRetired) {
    $null = Adb @('shell', 'mkdir', '-p', "$DestRp/retired")
    $moved = @()
    foreach ($b in $Retired) {
        $pre = Adb @('shell', "test -d '$DestRp/$b' && echo present || echo absent")
        if ($pre.Text -notmatch 'present') { continue }
        # The second test keeps a re-run from burying the folder inside itself:
        # mv into an existing directory of that name would nest.
        $null = Adb @('shell', "if [ -d '$DestRp/$b' ] && [ ! -e '$DestRp/retired/$b' ]; then mv '$DestRp/$b' '$DestRp/retired/'; fi")
        $post = Adb @('shell', "test -d '$DestRp/$b' && echo still-there || echo moved")
        if ($post.Text -match 'moved') { $moved += $b } else { $moved += "$b (blocked: retired/$b already exists)" }
    }
    Write-Host ''
    if ($moved.Count -gt 0) {
        Write-Host ("moved {0} dead bucket(s) to {1}/retired/ (nothing was deleted):" -f $moved.Count, $DestRp) -ForegroundColor Green
        Write-Host ('  ' + ($moved -join ', '))
    } else {
        Write-Host 'no dead buckets to move; nothing on the phone was changed beyond the push.' -ForegroundColor Green
    }
}

Write-Host ''
Write-Host 'verifying sizes on the phone:' -ForegroundColor Cyan
$bad = @()
foreach ($f in $files) {
    $r = Adb @('shell', "stat -c '%s' '$DestRp/$($f.Bucket)/$($f.Name)'")
    $remote = 0
    if ($r.Code -eq 0 -and $r.Text.Trim() -match '^\d+$') { $remote = [int64]$r.Text.Trim() }
    if ($remote -ne $f.Length) { $bad += "$($f.Bucket)/$($f.Name) (got $remote, want $($f.Length))" }
    else { Write-Host ("  {0,6}  {1}  matches" -f $f.Bucket, $f.Name) -ForegroundColor Green }
}
if ($bad.Count -gt 0) {
    Write-Host ''
    Write-Host ('[!] these did not land right: ' + ($bad -join ', ')) -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Done. Restart the game, then check the two things this can actually change.' -ForegroundColor Cyan
Write-Host ''
Write-Host '1. The mech configs: the "JsonConf cannot open" lines for these three paths' -ForegroundColor Yellow
Write-Host '   should be gone from the log.'
Write-Host "   adb logcat -d | Select-String 'JsonConf cannot open'" -ForegroundColor White
Write-Host ''
Write-Host '2. The device-table readout (only moves with the full setup, which puts the' -ForegroundColor Yellow
Write-Host '   tables inside patch_npk\p_res_1.npk - see gpu-tables\README.md):'
Write-Host '   adb logcat -d | Select-String "Use custom quality"' -ForegroundColor White
Write-Host ''
Write-Host 'A GpuSkin fallback count that does not move is expected: that decision is the' -ForegroundColor DarkGray
Write-Host "engine's own, and the game loads the compiled .nfx, not the .fx source." -ForegroundColor DarkGray
