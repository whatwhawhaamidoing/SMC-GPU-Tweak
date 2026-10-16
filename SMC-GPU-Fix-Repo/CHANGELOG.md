# Changelog

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

## Future Updates

### Planned for v1.1
- [ ] Test on additional GPU families (Adreno, PowerVR)
- [ ] Add more shader variants if needed
- [ ] Improve fallback count further (if possible)
- [ ] Add automatic device detection

### Under Investigation
- Additional lightmap shader variants (lightmap93, lightmap_tree, common_lightmap)
- Thermal throttling interaction
- ANGLE/Vulkan backend compatibility

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

---

## Repository Maintenance

### When to Update
- New GPU families released
- Game updates change shader requirements
- Community reports issues on specific devices
- Better patching strategies discovered

### How to Contribute
1. Test on your device
2. Document results (before/after counts)
3. Share log excerpts showing issues
4. Suggest improvements via community channels
