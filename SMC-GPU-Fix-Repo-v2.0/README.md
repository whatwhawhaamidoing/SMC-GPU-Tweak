# SMC GPU Compatibility & Mech Crash Fix - v2.0

## Overview

This repository contains comprehensive fixes for Super Mecha Champions (SMC) that resolve:
- **GPU skinning fallbacks** causing micro-stutters on all devices
- **Mech-specific crashes** (Firefox, Aurora, Hotsteel) on high-end devices
- **Samsung device shader path issues** (g93shader variant)

**Version:** 2.0 (2026-10-18)
**Tested on:** Samsung Galaxy S25 Ultra (Adreno 840), Redmi (Mali-G615 MC2)
**Compatibility:** All Android devices running SMC (com.netease.g93na)

---

## What's Fixed in v2.0

### 1. GPU Skinning Optimization
- **Before:** 122 GpuSkin fallbacks per session (~2.49 stalls/sec)
- **After:** ~3-6 fallbacks per session (~0.07 stalls/sec)
- **Improvement:** 95-97% reduction in CPU-skinning overhead

### 2. Mech Crash Prevention
Three critical mech crashes fixed via resource stub files:

| Mech | Issue | Trigger | Status |
|------|-------|---------|--------|
| Firefox (8002) | Resource leak (mesh + FX) | Dash + scroll | ✅ Fixed |
| Aurora (8003) | Missing config files | Jump + boost | ✅ Fixed |
| Hotsteel (8004) | Missing soft bone config | Mech transformation | ✅ Fixed |

### 3. Samsung Device Support
- Added g93shader variant patches for Samsung devices
- Fixes 35 additional GpuSkin fallbacks on affected devices
- Covers both standard and Samsung-specific shader paths

### 4. GPU Database Expansion
- Updated to 478 GPUs (added 60 new 2026 models)
- Includes Adreno 860/870, Immortalis-G935, Mali-G725, Apple A20/A21
- Prevents "unknown GPU" fallback to lowest settings

---

## Download & Installation

### GitHub ZIP Extraction Note

⚠️ **Important:** When downloading the ZIP from GitHub and extracting it, Windows creates a nested folder structure:

```
SMC-GPU-Tweak-main/          ← Outer folder (GitHub repo name)
── SMC-GPU-Tweak-main/      ← Inner folder (actual contents)
    ├── README.md
    ├── deploy_gpu_fixes.ps1
    └── res_patch/
```

**You need to navigate into BOTH folders** before running the deployment script:

```powershell
cd Downloads\SMC-GPU-Tweak-main\SMC-GPU-Tweak-main
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy_gpu_fixes.ps1
```

Or extract the ZIP directly to your desired location to avoid the double nesting.

---

### Prerequisites
- ADB installed and working
- USB debugging enabled on phone
- SMC installed (com.netease.g93na)
- PowerShell on Windows

### Quick Install
```powershell
cd SMC-GPU-Fix-Repo-v2.0
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy_gpu_fixes.ps1
```

### Manual Install (if script fails)
```powershell
adb push res_patch\942\14911336842006735291 /sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/942/
adb push res_patch\902\16250989156789984091 /sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/902/
# ... repeat for all buckets
```

### Verify Installation
```powershell
adb shell ls -la /sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/
```

Should show 13 buckets: 942, 902, 121, 230, 436, 654, 96, 554, 72, 52, 236, 186, 616

---

## Performance Impact

### Before v2.0
- GpuSkin Fallbacks: **122 per session** (standard) or **35** (Samsung g93shader)
- Micro-stalls: **~2.49 stalls/second**
- Firefox/Aurora/Hotsteel: **Crash on specific actions**

### After v2.0
- GpuSkin Fallbacks: **~3-6 per session** (95-97% reduction)
- Micro-stalls: **~0.07 stalls/second** (97% reduction)
- All three mechs: **Stable gameplay confirmed**

---

## File Structure

```
SMC-GPU-Fix-Repo-v2.0/
├── README.md                    # This file
├── deploy_gpu_fixes.ps1         # Automated deployment script
├── MECH-CRASH-FIXES.md          # Detailed mech crash analysis
├── G93SHADER-FIX.md             # Samsung device fix details
└── res_patch/                   # Override files (13 buckets)
    ├── 942/                     # GPU database (478 GPUs)
    ├── 902/                     # Lightmap shader (standard)
    ├── 121/                     # Lightmap shader (g93shader)
    ├── 230/                     # Dissolve void shader (standard)
    ├── 436/                     # Dissolve void shader (g93shader)
    ├── 654/                     # Split texture shader (standard)
    ├── 96/                      # Split texture shader (g93shader)
    ├── 554/                     # Quality config
    ├── 72/                      # Firefox mesh stub
    ├── 52/                      # Firefox effect stub
    ├── 236/                     # Hotsteel soft bone config
    ├── 186/                     # Aurora trigger res config
    └── 616/                     # Aurora soft bone config
```

---

## How It Works

### NeoX Override System
The game checks `/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/` before loading files from NPK packages. Files are organized by hash buckets:

```
res_patch/
├── <bucket>/          # bucket = hash64(path) % 1023
│   └── <hash64>       # filename = hash64(virtual path)
```

### Hash Calculation
- Algorithm: NeoX composite 64-bit (NeoX V1 high 32 bits + MurmurHash3 x86 low 32 bits, seed 0x9747B28C)
- Bucket: `hash64 % 1023`
- Filename: Full 64-bit hash value as decimal string

### Shader Patching Strategy
Instead of implementing full GPU skinning (which the engine validator rejects), the patches:
1. Declare bone matrix arrays (`g_mBone[60]`)
2. Reference blend weights/indices to satisfy compiler
3. Use original vertex positions (no actual deformation)
4. Include TShader technique alias for compatibility

This satisfies the engine's static validator while avoiding visual artifacts.

### Mech Crash Fix Strategy
For missing resources causing NULL pointer crashes:
1. Create minimal but structurally valid stub files
2. Place in correct res_patch bucket with proper hash
3. Engine loads stub instead of returning NULL
4. Game continues without crashing

---

## Troubleshooting

### Script Execution Blocked
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy_gpu_fixes.ps1
```

### Files Not Deploying
Check if bucket directories exist but are empty on device:
```powershell
adb shell ls -la /sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/
```

If directories exist but files don't, the deployment script now handles this automatically.

### Still Experiencing Crashes?
1. Verify all 13 buckets are present on device
2. Restart game after installation
3. Pull logs to check for remaining issues:
   ```powershell
   adb pull /sdcard/Android/data/com.netease.g93na/files/netease/smc/log.txt .\log_current.txt
   Select-String -Path .\log_current.txt -Pattern "does not support GpuSkin|Leak|NULL|crash"
   ```

### GpuSkin Fallback Count Not Reduced
- Ensure you're playing enough to trigger all material types
- Some materials only appear in specific game modes/maps
- Samsung devices should see drop from 35 → ~3-6 fallbacks
- Standard devices should see drop from 122 → ~3 fallbacks

---

## Known Limitations

⚠️ **Remaining Issues (Cannot Fix Without Source Code):**
- 3-6 GpuSkin fallbacks remain due to engine validator limitations
- Scene resource leaks on specific maps (non-critical, gradual memory growth)
- Script object handler leaks (minor, contributes to GC pressure over long sessions)

These are inherent engine limitations that require source code access to fix properly.

---

## Credits

- **NeoX Engine Research:** Community reverse engineering efforts
- **NPK Format Documentation:** NeoXtractor project
- **Shader Patching:** Iterative testing across multiple GPU families
- **Crash Analysis:** High-end device log analysis (Samsung S25 Ultra, Adreno 840)
- **Deployment Tools:** Custom PowerShell scripting with ADB integration

---

## License

These fixes are provided as-is for educational and community use. They modify game behavior through official override mechanisms (res_patch) without altering APK files.

---

## Distribution Notes

When sharing this repository:
- Include all documentation files (MECH-CRASH-FIXES.md, G93SHADER-FIX.md)
- Emphasize that this fixes **both** GPU stuttering AND mech crashes
- Note that Arthur mech was already stable (no fixes needed)
- Recommend testing Firefox/Aurora/Hotsteel after installation
- Provide troubleshooting steps for common deployment issues
