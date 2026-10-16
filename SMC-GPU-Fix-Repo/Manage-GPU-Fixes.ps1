<#
.SYNOPSIS
  Fix A - teach the game about newer GPUs (device compatibility tables).

.DESCRIPTION
  The game looks up your GPU name in res/confs/mobile_device_level.json. Modern
  chips (Adreno 830/840, Immortalis-G925, Xclipse 940 ...) are not in that table,
  so every phone with one falls into the engine's "unknown GPU" branch. This
  script delivers a version of the table with 42 extra GPUs, using the game's own
  res_patch override folder (same channel the community already proved works for
  res/confs/*.json).

  Nothing is deleted and no APK changes. One file is written into the game's own
  data folder, and -Remove takes it away again.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Fix-A-DeviceTables.ps1
      apply the fix (pushes the GPU table only)

.EXAMPLE
  ... .\Fix-A-DeviceTables.ps1 -QualityOverride
      also pin quality/resolution for Adreno 829 phones (experiment, see README)

.EXAMPLE
  ... .\Fix-A-DeviceTables.ps1 -GpuSkinPatch
      also push shader overrides that stop the "does not support GpuSkin" CPU-skinning fallback

.EXAMPLE
  ... .\Fix-A-DeviceTables.ps1 -Status
      read-only: show what the phone has right now

.EXAMPLE
  ... .\Fix-A-DeviceTables.ps1 -Remove
      put the phone back exactly as before

.EXAMPLE
  ... .\Fix-A-DeviceTables.ps1 -PullLog
      copy the game log next to this script so you can send it
#>
[CmdletBinding()]
param(
    [switch]$Remove,
    [switch]$Status,
    [switch]$PullLog,
    [switch]$QualityOverride,
    [switch]$GpuSkinPatch,
    [string]$Adb = '',
    [string]$Serial = ''
)

$ErrorActionPreference = 'Stop'
$Package = 'com.netease.g93na'
$Smc = "/sdcard/Android/data/$Package/files/netease/smc"
$Payload = Join-Path $PSScriptRoot 'payload'

# file name in the game's VFS -> res_patch address (hash64 and bucket hash64 % 1023)
$Targets = @(
    [pscustomobject]@{ Name = 'mobile_device_level.json'; Local = (Join-Path $Payload 'res_patch\942\14911336842006735291'); Remote = "$Smc/res_patch/942/14911336842006735291" },
    [pscustomobject]@{ Name = 'device_quality_conf.json'; Local = (Join-Path $Payload 'res_patch\554\6362951946433427327'); Remote = "$Smc/res_patch/554/6362951946433427327" }
)
if (-not $QualityOverride) { $Targets = @($Targets | Where-Object { $_.Name -ne 'device_quality_conf.json' }) }

# GPU-skinning fallback fix targets (shaders that cannot skin on GPU but receive skinned meshes)
$GpuSkinTargets = @(
    [pscustomobject]@{ Name = 'dissolve_void.fx'; Local = (Join-Path $Payload 'res_patch\230\9126629151205861481'); Remote = "$Smc/res_patch/230/9126629151205861481" },
    [pscustomobject]@{ Name = 'lightmap_nx2_mobile.fx'; Local = (Join-Path $Payload 'res_patch\902\16250989156789984091'); Remote = "$Smc/res_patch/902/16250989156789984091" },
    [pscustomobject]@{ Name = 'split_texture.fx'; Local = (Join-Path $Payload 'res_patch\654\4772179034807473074'); Remote = "$Smc/res_patch/654/4772179034807473074" }
)
if ($GpuSkinPatch) { $Targets += $GpuSkinTargets }

function Say($m)  { Write-Host $m }
function Step($m) { Write-Host ''; Write-Host "== $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  OK   $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  !!   $m" -ForegroundColor Yellow }
function Stop2($m) {
    Write-Host ''
    Write-Host "STOPPED: $m" -ForegroundColor Red
    Write-Host 'Nothing further was changed. Send this whole window text if you need help.'
    exit 1
}

function A {
    param([string[]]$AdbArgs)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $full = @()
        if ($Serial) { $full += @('-s', $Serial) }
        $full += $AdbArgs
        $lines = & $AdbPath @full 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $prev }
    [pscustomobject]@{ Code = $code; Text = (($lines | Out-String).Trim()) }
}

# ---------------------------------------------------------------- adb + phone
$AdbPath = $null
$cands = @()
if ($Adb) { $cands += $Adb }
$cands += (Join-Path $PSScriptRoot '..\platform-tools\adb.exe')
$cands += (Join-Path $PSScriptRoot '..\kit\platform-tools\adb.exe')
$cands += 'C:\android-sdk\platform-tools\adb.exe'
foreach ($c in $cands) { if ($c -and (Test-Path $c)) { $AdbPath = (Resolve-Path $c).Path; break } }
if (-not $AdbPath) { Stop2 'adb.exe not found. Expected it in "kit\platform-tools\adb.exe" next to this script.' }
Say "adb: $AdbPath"

Step 'Looking for the phone'
$found = @()
foreach ($line in ((A @('devices')).Text -split "`r?`n")) {
    if ($line -match '^(\S+)\s+device$') { $found += $Matches[1] }
}
if ($found.Count -eq 0) { Stop2 'no phone found over adb. Plug the cable in, unlock the phone, turn on USB debugging, accept the "allow debugging" pop-up.' }
if ($found.Count -gt 1 -and -not $Serial) { Stop2 ('several phones: ' + ($found -join ', ') + '. Run again with  -Serial <one-of-those>.') }
if ($found.Count -eq 1) { $Serial = $found[0] }
$gpu = (A @('shell', 'getprop', 'ro.product.model')).Text
Ok "phone: $gpu   serial: $Serial"

$p = (A @('shell', 'pm', 'path', $Package)).Text
if ($p -notmatch 'package:') { Stop2 'the game is not installed on this phone. Install it first (Install-SMC-All.ps1).' }
Ok 'the game is installed'

# Which GPU name does this phone report? That exact lower-case string is the key the
# game looks up in mobile_device_level.json, so we check the payload covers it.
Step 'Which GPU does this phone report'
$sf = (A @('shell', 'dumpsys', 'SurfaceFlinger')).Text
$gpuLine = ''
foreach ($line in ($sf -split "`r?`n")) { if ($line -match '^\s*GLES:\s*(.+)$') { $gpuLine = $Matches[1].Trim(); break } }
if (-not $gpuLine) { Warn 'could not read the GLES line from SurfaceFlinger; skipping the GPU check.' }
else {
    Say "  as reported : $gpuLine"
    $parts = $gpuLine -split ','
    if ($parts.Count -lt 2) { Warn "unexpected GLES line format, cannot find the GPU name: $gpuLine"; $parts = @('', $gpuLine) }
    $key = ($parts[1].Trim().ToLower())
    Say "  key the game looks for : '$key'"
    $tblFile = Join-Path $Payload 'mobile_device_level.patched.json'
    if (Test-Path $tblFile) {
        $tbl = Get-Content $tblFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($tbl.PSObject.Properties.Name -contains $key) {
            Ok ("this phone's GPU IS in the new table (score " + $tbl.$key + ")")
        } else {
            Warn ("this phone's GPU is STILL not in the table. The game will keep treating it as unknown.")
            Warn ("send this exact key so it can be added: '" + $key + "'")
        }
    } else { Warn 'payload table missing - re-copy the fix-gpu folder.' }
}

if ($PullLog) {
    Step 'Copying the game log'
    $dest = Join-Path $PSScriptRoot ("phone-log-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".txt")
    $r = A @('pull', "$Smc/log.txt", $dest)
    if ($r.Code -eq 0 -and (Test-Path $dest)) {
        Ok "saved: $dest"
        $hits = @(Select-String -Path $dest -Pattern 'adreno|device_quality|default_quality|GLES|series of' -AllErrors:$false -ErrorAction SilentlyContinue)
        Say ("  lines mentioning GPU / quality / GLES in that log: " + $hits.Count)
        $hits | Select-Object -First 15 | ForEach-Object { Say ("    " + $_.Line.Trim()) }
    } else {
        Warn "could not read $Smc/log.txt : " $r.Text
        Warn 'Start the game once, let it reach the lobby, close it, then try again.'
    }
    exit 0
}

function Show-Status {
    Step 'What the phone has now'
    $r = (A @('shell', "ls -l '$Smc/res_patch/942' 2>/dev/null")).Text
    if ($r) { Say "  res_patch/942 : $r" } else { Say '  res_patch/942 : (nothing there)' }
    $r2 = (A @('shell', "ls -l '$Smc/res_patch/554' 2>/dev/null")).Text
    if ($r2) { Say "  res_patch/554 : $r2" } else { Say '  res_patch/554 : (nothing there)' }
    $stock = (A @('shell', "cat '$Smc/res_patch/942/14911336842006735291' 2>/dev/null | wc -c")).Text.Trim()
    if ($stock -and $stock -ne '0') { Ok "our GPU table override is in place ($stock bytes)" } else { Say '  our GPU table override is NOT in place' }
}

if ($Status) { Show-Status; exit 0 }

if ($Remove) {
    Step 'Removing Fix A'
    $null = A @('shell', 'am', 'force-stop', $Package)
    foreach ($t in @(
        [pscustomobject]@{ Remote = "$Smc/res_patch/942/14911336842006735291"; Bak = "$Smc/res_patch/942/14911336842006735291.pre-gpufix" },
        [pscustomobject]@{ Remote = "$Smc/res_patch/554/6362951946433427327"; Bak = "$Smc/res_patch/554/6362951946433427327.pre-gpufix" }
    )) {
        $has = (A @('shell', "test -e '$($t.Bak)' && echo YES || echo NO")).Text
        if ($has -match 'YES') {
            $null = A @('shell', "mv '$($t.Bak)' '$($t.Remote)'")
            Ok "restored the previous file at $($t.Remote)"
        } else {
            $null = A @('shell', "rm -f '$($t.Remote)'")
            Ok "removed $($t.Remote)"
        }
    }
    Show-Status
    Say ''
    Say 'Start the game again - it is back to the stock behaviour.'
    exit 0
}

# ---------------------------------------------------------------- apply
Step 'Checking the payload files'
foreach ($t in $Targets) {
    if (-not (Test-Path $t.Local)) { Stop2 ("missing payload file: " + $t.Local) }
    $len = (Get-Item $t.Local).Length
    Ok ("{0}  {1} bytes" -f $t.Name, $len)
}

Step 'Stopping the game (so it cannot be halfway through reading a file)'
$null = A @('shell', 'am', 'force-stop', $Package)

foreach ($t in $Targets) {
    Step ("Writing override for " + $t.Name)
    $dir = $t.Remote.Substring(0, $t.Remote.LastIndexOf('/'))
    $null = A @('shell', "mkdir -p '$dir'")

    $exists = (A @('shell', "test -f '$($t.Remote)' && echo YES || echo NO")).Text
    $hasBak = (A @('shell', "test -f '$($t.Remote).pre-gpufix' && echo YES || echo NO")).Text
    if ($exists -match 'YES' -and $hasBak -notmatch 'YES') {
        $null = A @('shell', "cp '$($t.Remote)' '$($t.Remote).pre-gpufix'")
        Ok 'kept a copy of what was there before (-Remove gives it back)'
    }

    $r = A @('push', $t.Local, $t.Remote)
    if ($r.Code -ne 0) { Stop2 ('push failed: ' + $r.Text) }
    $remoteSize = (A @('shell', "stat -c '%s' '$($t.Remote)'")).Text.Trim()
    $localSize = (Get-Item $t.Local).Length
    if ($remoteSize -ne [string]$localSize) { Stop2 ("the size on the phone ($remoteSize) does not match the file we sent ($localSize)") }
    Ok ("placed at " + $t.Remote + " (" + $remoteSize + " bytes)")
}

Show-Status
Say ''
Say 'NEXT:'
Say '  1. Start the game on the phone.'
Say '  2. Check the phones that used to be "not compatible" - do they now reach the lobby?'
Say '  3. When you want the log for comparison:  .\Fix-A-DeviceTables.ps1 -PullLog'
Say '  4. To take it back:                        .\Fix-A-DeviceTables.ps1 -Remove'
