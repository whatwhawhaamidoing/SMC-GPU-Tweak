# Mech Crash Fixes - SMC v2.2

## Overview

This document covers all mech-specific crash fixes deployed in v2.2, including Firefox, Aurora, and Hotsteel.

## Fixed Mechs

### 1. Firefox (8002) - Resource Leak Fix ✅

**Symptoms:**
- Crash during dash + screen scroll animation in TDM
- GPU memory exhaustion on high-end devices (Adreno 840)

**Root Cause:**
Missing resource files causing NULL pointer dereference:
- `effect\mesh\common\mecha\8002\feng_sk_01.gim` (mesh)
- `effect\fx\scenes\common\sidou\shamo_yanchen.sfx` (smoke FX)

**Fix:**
Created minimal stub files placed in res_patch:
- Bucket **72**: `76e121ba2c99e13c` (36 bytes GIM stub)
- Bucket **52**: `2850f9bfd7a0e471` (32 bytes SFX stub)

**Result:** Game loads stubs instead of crashing on NULL pointer.

---

### 2. Aurora (8003) - Missing Config Fix ✅

**Symptoms:**
- Crash during jump + boost animation
- Similar pattern to Firefox but with missing configs instead of resources

**Root Cause:**
Missing configuration files:
- `confs/mecha_skin_201800300_trigger_res.json` (trigger resources)
- `confs/soft_bone_param_8003_8003.json` (bone simulation)

**Fix:**
Created stub JSON configs:
- Bucket **186**: `1453597915289340138` (trigger res config)
- Bucket **616**: `10050766292890922830` (soft bone config)

**Result:** Engine loads valid configs instead of failing on missing files.

---

### 3. Hotsteel (8004) - Missing Config Fix ✅

**Symptoms:**
- Instant crash on mech transformation
- Error: "MODEL HAS NOT AIM IK SOLVER!"
- Error: "JsonConf cannot open confs/soft_bone_param_8004_s03.json"

**Root Cause:**
Missing soft bone parameter config for skin variant s03:
- `confs/soft_bone_param_8004_s03.json`

**Fix:**
Created stub JSON config:
- Bucket **236**: `10477915440876417011` (soft bone config)

**Result:** Bone solver initializes with empty params instead of crashing.

---

### 4. Arthur - No Issues ✅

Arthur works fine because it has:
- Complete soft bone configs
- No resource leaks during animations
- Properly managed material lifecycle

---

## Deployment

Run from `D:\SMC-Share-1.2`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy_gpu_fixes_v2.2.ps1
```

This deploys **13 files total**:
- 3 standard shader patches (buckets 902, 230, 654)
- 3 g93shader variants (buckets 121, 436, 96)
- GPU database with 478 GPUs (bucket 942)
- Quality config (bucket 554)
- Firefox crash stubs (buckets 72, 52)
- Hotsteel soft bone config (bucket 236)
- Aurora trigger res config (bucket 186)
- Aurora soft bone config (bucket 616)

---

## Expected Results

| Mech | Before | After | Status |
|------|--------|-------|--------|
| Firefox | Crash on dash+scroll | Stable | ✅ Fixed |
| Aurora | Crash on jump+boost | Stable | ✅ Fixed |
| Hotsteel | Crash on transform | Stable | ✅ Fixed |
| Arthur | Stable | Stable | ✅ Already OK |

GpuSkin fallbacks should also drop from 35 to ~3-6 (g93shader fix).

---

## Technical Details

### Hash Calculation
All files use NeoX composite 64-bit hashing:
- High 32 bits: NeoX V1 hash
- Low 32 bits: MurmurHash3 x86 (seed 0x9747B28C)
- Bucket = hash64 % 1023
- Filename = full 64-bit hash value

### Stub File Structures

**GIM Stub (Firefox mesh):**
```
Magic: 'GIM\x00'
Version: 1
Counts: all 0
End marker: 0xFFFFFFFF
Size: 36 bytes
```

**SFX Stub (Firefox effect):**
```
Magic: 'SFX\x00'
Version: 1
Duration: 0.0f
Counts: all 0
Size: 32 bytes
```

**JSON Stubs (Aurora/Hotsteel configs):**
```json
{
    "version": 1,
    "mech_id": <id>,
    "skin_variant": "<variant>",
    "soft_bone_params": [],
    "ik_solver_enabled": false,
    "note": "Stub config - prevents crash"
}
```

---

## Verification

After deployment, pull logs and verify no crash-related errors:

```powershell
adb pull /sdcard/Android/data/com.netease.g93na/files/netease/smc/log.txt .\logs\log_current.txt
Select-String -Path .\logs\log_current.txt -Pattern "Leak|NULL|crash|cannot open" | Select-Object -First 20
```

Should show **no mech-specific crashes** (scene resource leaks may still appear but are non-critical).

---

**Version:** v2.2 (2026-10-18)
**Author:** Based on high-end device crash analysis
**Status:** Ready for deployment
**Tested on:** Samsung Galaxy S25 Ultra (Adreno 840), Redmi (Mali-G615 MC2)
