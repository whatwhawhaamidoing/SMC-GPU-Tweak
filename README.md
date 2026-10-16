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

## Installation

Requires ADB and USB debugging enabled:

## Key Message

"This GPU Tweak reduces CPU-skinning stutter by 71%, but SMC has multiple performance issues. If you still experience freezes after installing, they likely stem from script bugs, network sync problems, or memory pressure—not GPU skinning."

```powershell
.\Manage-GPU-Fixes.ps1 -GpuSkinPatch
