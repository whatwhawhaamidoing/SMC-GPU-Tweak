# Deploy GPU Fixes v2.0 (g93shader variant + mech crash fixes)
# This version includes patches for shader/g93shader/ paths and missing mech configs

$adb = ".\platform-tools\adb.exe"

Write-Host "=== SMC GPU Fix v2.0 Deployment (g93shader + mech crash fixes) ===" -ForegroundColor Cyan
Write-Host ""

# Check device connection
$result = & $adb devices
if ($result -notmatch "device") {
    Write-Host "[ERROR] No device connected!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Device connected" -ForegroundColor Green
Write-Host ""

# Define files to deploy
$files = @(
    @{src="res_patch\942\14911336842006735291"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/942/"; desc="GPU Database (478 GPUs)"},
    @{src="res_patch\902\16250989156789984091"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/902/"; desc="Lightmap Shader (standard)"},
    @{src="res_patch\121\7890226423518560836"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/121/"; desc="Lightmap Shader (g93shader)"},
    @{src="res_patch\230\9126629151205861481"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/230/"; desc="Dissolve Void Shader (standard)"},
    @{src="res_patch\436\5936378021348388973"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/436/"; desc="Dissolve Void Shader (g93shader)"},
    @{src="res_patch\654\4772179034807473074"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/654/"; desc="Split Texture Shader (standard)"},
    @{src="res_patch\96\9789497911742943303"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/96/"; desc="Split Texture Shader (g93shader)"},
    @{src="res_patch\554\6362951946433427327"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/554/"; desc="Quality Config"},
    @{src="res_patch\72\76e121ba2c99e13c"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/72/"; desc="Firefox Mesh Stub"},
    @{src="res_patch\52\2850f9bfd7a0e471"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/52/"; desc="Firefox Effect Stub"},
    @{src="res_patch\236\10477915440876417011"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/236/"; desc="Hotsteel Soft Bone Config"},
    @{src="res_patch\186\1453597915289340138"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/186/"; desc="Aurora Trigger Res Config"},
    @{src="res_patch\616\10050766292890922830"; dst="/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/616/"; desc="Aurora Soft Bone Config"}
)

$success = 0
$failed = 0

foreach ($file in $files) {
    $srcPath = Join-Path $PSScriptRoot $file.src
    if (Test-Path $srcPath) {
        $filename = Split-Path $file.src -Leaf
        $dstPath = "$($file.dst)$filename"
        Write-Host "Deploying: $($file.desc)..." -NoNewline
        & $adb push $srcPath $dstPath 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " [OK]" -ForegroundColor Green
            $success++
        } else {
            Write-Host " [FAILED]" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host "Missing: $($file.desc) - File not found: $srcPath" -ForegroundColor Yellow
        $failed++
    }
}

Write-Host ""
Write-Host "=== Deployment Summary ===" -ForegroundColor Cyan
Write-Host "Success: $success / $($files.Count)" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "Failed: $failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart SMC game" -ForegroundColor White
Write-Host "2. Test Firefox mech dash + scroll animation" -ForegroundColor White
Write-Host "3. Pull logs to verify GpuSkin fallback count" -ForegroundColor White
Write-Host ""
Write-Host "Expected result: GpuSkin fallbacks should drop from 35 to ~3-6" -ForegroundColor Green
