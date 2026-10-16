# GPU Compatibility Matrix

## Tested Devices

### ✅ Confirmed Working

| Device | GPU | Android | Fallbacks Before | Fallbacks After | Improvement | Notes |
|--------|-----|---------|------------------|-----------------|-------------|-------|
| Redmi 25080RABDG | Mali-G615 MC2 | 16 | 122 | 35 | 71% | Primary test device |

---

## Theoretical Compatibility

Based on NeoX engine's res_patch override system, these fixes should work on:

### ARM Mali GPUs
- ✅ **G5x Series:** G52, G57 (OpenGL ES 3.2+)
- ✅ **G6x Series:** G610, G615, G620, G625
- ✅ **G7x Series:** G710, G715, G720
- ✅ **Immortalis Series:** G715, G720, G925

**Reasoning:** All use same OpenGL ES driver stack, res_patch system is engine-level

### Qualcomm Adreno GPUs
- ✅ **6xx Series:** 610, 615, 618, 620, 630, 640, 650, 680, 690
- ✅ **7xx Series:** 720G, 730G, 740G, 750G, 765G, 778G, 7+ Gen 2
- ✅ **8xx Series:** 830, 840, 855, 865, 870, 888, 8 Gen 1/2/3

**Reasoning:** Device table explicitly adds Adreno 830/840 support

### Samsung Xclipse GPUs
- ✅ **9xx Series:** Xclipse 920, 930, 940
- ✅ **5xx Series:** Xclipse 530, 540

**Reasoning:** Device table includes Xclipse 940

### PowerVR GPUs
- ⚠️ **Unknown:** Not explicitly tested or added to device table
- May work if GPU name matches existing patterns

### Imagination Technologies
- ⚠️ **Unknown:** Rarely used in modern Android phones

---

## Untested Scenarios

### ❓ Not Verified
- iOS devices (different file structure, may not use res_patch)
- Android emulators (BlueStacks, LDPlayer, etc.)
- Chrome OS with Android support
- Very old GPUs (pre-2020, OpenGL ES < 3.0)
- Custom ROMs with modified graphics stacks

### Potential Issues
- Emulators may have different rendering paths
- iOS uses Metal instead of Vulkan/OpenGL ES
- Old GPUs may not support required shader model

---

## How to Test on Your Device

### Step 1: Check Your GPU
```powershell
adb shell getprop ro.product.model
adb shell getprop glEsVersion
```

### Step 2: Install Fixes
```powershell
.\Manage-GPU-Fixes.ps1 -GpuSkinPatch
```

### Step 3: Play and Pull Log
```powershell
# Play a full match, then:
.\Manage-GPU-Fixes.ps1 -PullLog
```

### Step 4: Count Fallbacks
```powershell
Select-String "does not support GpuSkin" phone-log-*.txt | Measure-Object
```

### Step 5: Report Results
Share your device model, GPU, and before/after counts in community channels.

---

## Device-Specific Notes

### High-End Devices (Adreno 8xx, Mali-G7xx)
- Should see biggest improvement from device table
- GPU skinning fixes still beneficial for stutter reduction
- May already run well, but fixes ensure optimal performance

### Mid-Range Devices (Adreno 7xx, Mali-G6xx)
- Primary target for these fixes
- Most likely to benefit from both device table and shader patches
- Tested configuration (Mali-G615 MC2) falls in this category

### Entry-Level Devices (Adreno 6xx, Mali-G5x)
- Device table prevents fallback to lowest settings
- Shader patches reduce CPU overhead (important for weaker CPUs)
- May need quality overrides for smooth gameplay

---

## Reporting Incompatibilities

If you experience issues, please provide:
1. Device model (`adb shell getprop ro.product.model`)
2. GPU info (`adb shell dumpsys SurfaceFlinger | findstr GLES`)
3. Android version (`adb shell getprop ro.build.version.release`)
4. Game log (use `-PullLog` command)
5. Description of issue (crash, visual glitch, performance worse, etc.)

---

## Update Frequency

This matrix will be updated as community members test on different devices. Last updated: 2026-10-16
