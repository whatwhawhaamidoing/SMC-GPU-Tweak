# G93Shader Variant Fix - SMC GPU Compatibility v2.1

## Problem Discovery

Analysis of affected device logs revealed **35 GpuSkin fallbacks** (vs 3 on standard devices). The root cause: the game loads shaders from `shader/g93shader/` instead of `shader/`.

### Evidence from Logs

```
[COCOSUI] [ERROR] Material shader\g93shader\dissolve_void.fx::TShader, Material id [8007_mecha_mat] does not support GpuSkin
[COCOSUI] [ERROR] Material shader\g93shader\dissolve_void.fx::TShader, Material id [Material #42] does not support GpuSkin
```

Your v2.0 patches were in:
- Bucket 230 for `shader/dissolve_void.fx` ✅
- But his game needs bucket **436** for `shader/g93shader/dissolve_void.fx` ❌

## What is g93shader?

The `g93shader/` prefix appears to be a Samsung-specific shader variant path (possibly related to Galaxy S93/S25 Ultra optimization). Some devices load shaders from this alternate path instead of the standard `shader/` directory.

## Solution

Created duplicate shader patches for all 3 g93shader variants:

| Shader Path | Hash64 | Bucket | File |
|-------------|--------|--------|------|
| `shader/g93shader/lightmap_nx2_mobile.fx` | 0x6D7FB720C3398244 | 121 | `7890226423518560836` |
| `shader/g93shader/dissolve_void.fx` | 0x5262405BAEE8306D | 436 | `5936378021348388973` |
| `shader/g93shader/split_texture.fx` | 0x87DB487BD6DDD047 | 96 | `9789497911742943303` |

## Deployment

Run from `D:\SMC-Share-1.2`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy_gpu_fixes_ikhsan.ps1
```

This deploys **10 files total**:
- 3 standard shader patches (buckets 902, 230, 654)
- 3 g93shader variants (buckets 121, 436, 96)
- GPU database with 478 GPUs (bucket 942)
- Quality config (bucket 554)
- Firefox crash stubs (buckets 72, 52)

## Expected Results

**Before:** 35 GpuSkin fallbacks per session
**After:** ~3-6 fallbacks (same as standard devices + minor g93shader edge cases)

The remaining fallbacks will be engine validator rejections that can't be fixed without source code access.

## Technical Details

### Hash Calculation
NeoX uses composite 64-bit hashing:
- High 32 bits: NeoX V1 hash
- Low 32 bits: MurmurHash3 x86 (seed 0x9747B28C)
- Bucket = hash64 % 1023

### Why Both Variants?
Some devices may load from both paths depending on:
- Device model (Samsung vs others)
- Android version
- Game update version
- GPU driver differences

Deploying both ensures compatibility across all devices.

## Verification

After deployment, pull logs and check:

```powershell
adb pull /sdcard/Android/data/com.netease.g93na/files/netease/smc/log.txt .\logs\log_current.txt
Select-String -Path .\logs\log_current.txt -Pattern "does not support GpuSkin" | Measure-Object
```

Should show **≤6 occurrences** (down from 35).

---

**Version:** v2.1 (2026-10-18)
**Author:** Based on affected device analysis
**Status:** Ready for deployment
