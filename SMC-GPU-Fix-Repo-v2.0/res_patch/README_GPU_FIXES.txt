GPU Compatibility Fixes for SMC
================================

This directory contains performance and compatibility fixes for modern GPUs.
These fixes are automatically installed by Install-SMC-All.ps1 during setup.

What's included:
----------------

1. mobile_device_level.json (bucket 942)
   - Adds support for 42+ modern GPUs not in the original game database
   - Includes Adreno 830/840, Immortalis-G925, Xclipse 940, Mali-G615 MC2, etc.
   - Prevents "unknown GPU" fallback to lowest settings

2. lightmap_nx2_mobile.fx (bucket 902)
   - Shader patch for scenery meshes with GPU_SKIN_ENABLE flag
   - Reduces CPU-skinning fallbacks by ~71% (122 → 35 on Mali-G615 MC2)
   - Eliminates micro-stalls caused by per-object CPU skinning

3. dissolve_void.fx (bucket 230)
   - Shader patch for dissolve effects with skinned meshes
   - Same GPU skinning fix approach as lightmap shader

4. split_texture.fx (bucket 654)
   - Shader patch for glass/bullet effects
   - Ensures GPU skinning compatibility for transparent materials

How it works:
-------------

The NeoX engine checks res_patch/ directories for file overrides before loading
from NPK packages. Files are placed in subdirectories named by hash64 % 1023,
with filenames being the full hash64 of the virtual path (e.g.,
"res/confs/mobile_device_level.json").

Performance impact:
-------------------

Before: 122 GpuSkin fallbacks → frequent micro-stalls (~2.49 stalls/sec)
After:  35 GpuSkin fallbacks → reduced stalls (~0.84 stalls/sec)
Improvement: 71% reduction in CPU-skinning overhead

Note: The remaining 35 fallbacks appear to be a hard limit without access to
original shader source or NeoX validator documentation. The engine's GPU skin
validator performs static analysis that rejects certain shader patterns.

Management:
-----------

To check current GPU fix status on device:
  powershell -File .\kit\Manage-GPU-Fixes.ps1 -Status

To remove GPU fixes:
  powershell -File .\kit\Manage-GPU-Fixes.ps1 -Remove

To reinstall GPU fixes only:
  powershell -File .\kit\Manage-GPU-Fixes.ps1 -GpuSkinPatch

To skip GPU fixes during installation:
  .\Install-SMC-All.ps1 -SkipGpuFix

Credits:
--------

Based on community research into NeoX NPK format and res_patch override system.
Shader patches developed through iterative testing on Mali-G615 MC2 hardware.
