# SMC-GPU-Tweak
Make Super Mecha Champions run smoother on modern phones. Fixes stuttering  caused by GPU skinning issues and adds proper support for new chipsets like  Snapdragon 8 Gen series and Dimensity chips.

Performance optimization package for Super Mecha Champions (Android) that reduces 
micro-stutters and improves compatibility with modern GPUs.

## What It Does

- **Reduces CPU-skinning overhead by 71%** (122 → 35 fallbacks per session)
- **Adds 42+ modern GPUs** to the game's device compatibility table
- **Fixes shader validation issues** for scenery meshes and effects
- **Works through official override system** - no APK modification required

## Quick Stats

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| GpuSkin Fallbacks | 122 | 35 | 71% ↓ |
| Micro-stalls/sec | 2.49 | 0.84 | 66% ↓ |
| Supported GPUs | ~50 | ~92 | +84% |

## Compatibility Requirements

### Will Work On:
- ✅ Any SMC Global Android build using package `com.netease.g93na`
- ✅ Official NetEase releases (v2.0+)
- ✅ Most private server builds (if they use standard NeoX engine)
- ✅ Custom APKs with same package name and data structure

### Won't Work On:
- ❌ iOS devices (different architecture)
- ❌ Builds with different package names (without script modification)
- ❌ Heavily modified engines that disable res_patch system

### How to Check Your Build:
```powershell
adb shell pm path com.netease.g93na
```
## Clarified

"This GPU Tweak reduces CPU-skinning stutter by 71%, but SMC has multiple performance issues. If you still experience freezes after installing, they likely stem from script bugs, network sync problems, or memory pressure—not GPU skinning."

## Installation

Requires ADB and USB debugging enabled:

```powershell
.\Manage-GPU-Fixes.ps1 -GpuSkinPatch
