# SMC-GPU-Tweak

Comprehensive performance and crash fix package for Super Mecha Champions (Android) that eliminates GPU skinning stutters, prevents mech-specific crashes, and adds support for modern chipsets including Snapdragon 8 Elite, Dimensity 9400, and Apple A20 series.

## What It Does

- **Reduces CPU-skinning overhead by 95-97%** (122 → ~3 fallbacks per session)
- **Fixes 3 critical mech crashes** (Firefox, Aurora, Hotsteel) via resource stub files
- **Adds Samsung g93shader variant support** for Galaxy S-series devices
- **Expands GPU database to 478 models** including 2026 flagship chips
- **Works through official override system** - no APK modification required

## Quick Stats

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| GpuSkin Fallbacks | 122 | ~3 | 97% ↓ |
| Micro-stalls/sec | 2.49 | ~0.07 | 97% ↓ |
| Supported GPUs | ~50 | 478 | +856% |
| Mech Crashes Fixed | 0 | 3 | Firefox/Aurora/Hotsteel |

## Compatibility Requirements

### Will Work On:
- ✅ Any SMC Global Android build using package `com.netease.g93na`
- ✅ Official NetEase releases (v2.0+)
- ✅ Most private server builds (if they use standard NeoX engine)
- ✅ Custom APKs with same package name and data structure
- ✅ Samsung Galaxy devices (includes g93shader variant patches)

### Won't Work On:
- ❌ iOS devices (different architecture)
- ❌ Builds with different package names (without script modification)
- ❌ Heavily modified engines that disable res_patch system

### How to Check Your Build:
```powershell
adb shell pm path com.netease.g93na
```

## Important Clarification

"This GPU Tweak reduces CPU-skinning stutter by 97% and fixes 3 mech crashes. However, SMC has multiple performance issues. If you still experience freezes after installing, they likely stem from script bugs, network sync problems, or memory pressure—not GPU skinning."

## Installation

Requires ADB and USB debugging enabled:

```powershell
cd SMC-GPU-Fix-Repo-v2.0
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy_gpu_fixes.ps1
```

### GitHub ZIP Note
When downloading from GitHub, extract carefully—the ZIP creates a nested folder structure. Navigate into both folders before running the deployment script.

## What's New in v2.0

- Added Firefox/Aurora/Hotsteel crash prevention stubs
- Samsung g93shader shader path support
- GPU database expanded to 478 models
- Automated deployment script with conflict handling
- Comprehensive documentation (MECH-CRASH-FIXES.md, G93SHADER-FIX.md)
