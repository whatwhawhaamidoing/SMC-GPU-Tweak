# Changelog

## Version 2.0 (2026-10-18)

### Major Release - Comprehensive Crash & Performance Fixes

#### Added
- **Mech crash prevention system** with stub resource files
  - Firefox (8002): Mesh + FX stubs for dash animation
  - Aurora (8003): Config stubs for jump+boost animation
  - Hotsteel (8004): Soft bone config stub for transformation
- **Samsung g93shader variant support**
  - Lightmap shader patch (bucket 121)
  - Dissolve void shader patch (bucket 436)
  - Split texture shader patch (bucket 96)
- **GPU database expansion** to 478 GPUs
  - Added 60 new 2026 models (Adreno 860/870, Immortalis-G935, Mali-G725, Apple A20/A21)
- **Automated deployment script** (`deploy_gpu_fixes.ps1`)
  - Handles directory conflicts automatically
  - Verifies device connection
  - Reports success/failure per file

#### Performance
- GpuSkin fallbacks: **122 → ~3** (standard devices, 97.5% reduction)
- GpuSkin fallbacks: **35 → ~3-6** (Samsung g93shader devices, 83-91% reduction)
- Micro-stalls: **~2.49/sec → ~0.07/sec** (97% reduction)
- Mech crashes: **Firefox/Aurora/Hotsteel now stable**

#### Testing
- Primary test device: Mali-G615 MC2 (Redmi phone)
- Secondary test device: Adreno 840 (Samsung Galaxy S25 Ultra)
- Verified stable gameplay on all three previously-crashing mechs
- No visual artifacts or crashes confirmed

#### Documentation
- Complete README with installation guide
- MECH-CRASH-FIXES.md: Detailed crash analysis and fixes
- G93SHADER-FIX.md: Samsung device-specific fix details
- Troubleshooting section for common issues

---

## Version 1.0 (2026-10-16)

### Initial Release

#### Added
- Device compatibility table with 42+ modern GPUs
- GPU skinning shader patches for 3 shader types:
  - lightmap_nx2_mobile.fx (scenery/buildings)
  - dissolve_void.fx (effects)
  - split_texture.fx (glass/bullets)
- Quality configuration overrides
- PowerShell management tool (Manage-GPU-Fixes.ps1)

#### Performance
- 71% reduction in GpuSkin fallbacks (122 → 35)
- 66% reduction in micro-stalls (2.49/sec → 0.84/sec)
- Proper GPU recognition for modern chips

#### Testing
- Primary test device: Mali-G615 MC2 (Redmi 25080RABDG)
- Verified stable gameplay
- No visual artifacts or crashes

#### Known Limitations
- 35 fallbacks remain (engine validator limitation)
- Not tested on iOS or emulators
- Requires Android USB debugging enabled

---

## Development History

### Iteration Results (Shader Patching)

**Patch 1:** Declared g_mBone but no usage
- Result: 62 fallbacks (49% reduction)
- Status: Partial success

**Patch 2:** Declared g_mBone + fake reference
- Result: 39 fallbacks (68% reduction)
- Status: Good improvement

**Patch 3:** Full bone matrix multiplication
- Result: 149 fallbacks ❌
- Status: Made it worse - engine validator rejected

**Patch 4 (Final):** Fake bone usage + TShader technique
- Result: 35 fallbacks (71% reduction) ✓
- Status: Optimal balance achieved

### Key Learnings
- Engine validator performs static analysis
- Real bone multiplication triggers rejection
- Simple declaration + reference pattern works best
- Technique name matters (TShader vs tech0)

### v2.0 Enhancements
- Discovered g93shader variant path on Samsung devices
- Identified mech-specific crash patterns via log analysis
- Developed stub file strategy for missing resources
- Automated deployment to handle edge cases

---

## Repository Maintenance

### When to Update
- New GPU families released
- Game updates change shader requirements
- Community reports issues on specific devices
- Better patching strategies discovered
- New mech crashes identified

### How to Contribute
1. Test on your device
2. Document results (before/after counts)
3. Share log excerpts showing issues
4. Suggest improvements via community channels
