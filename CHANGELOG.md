# Changelog

## 2.5 (2026-10-31)

The version where the package was measured instead of assumed. Two things changed,
and one of them removes a headline feature.

### Changed
- **The three mech configs are now at the keys the loader reads**: buckets 293, 166
  and 346. Their payloads are also real schemas now (the four keys the game's own
  sibling configs use) instead of invented ones.
- **Repo layout flattened** to the root, so there is no more "extract the zip and
  then go into the folder inside it" step.
- **`deploy_gpu_fixes.ps1` rewritten**: pushes only what loads, moves fourteen dead
  buckets into `res_patch/retired/` (moved, never deleted), re-runs safely, verifies
  remote sizes, works with adb on PATH or `-AdbPath`, and prints the honest readout.

### Removed
- **The 478-GPU device table and the quality override are gone from `res_patch`.**
  Measured 2026-10-31: both paths exist inside `aab_res.npk`, and `res_patch` is
  created *after* the archives, so it is never asked. They were inert in every
  version from 2.0 to 2.4. They belong in a `patch_npk` pack - see `gpu-tables/`.
- **G93SHADER-FIX.md and every shader patch.** The engine loads the compiled `.nfx`
  and supplies `GPU_SKIN_ENABLE` itself per object type; the `.fx` source is the
  wrong layer, and the two variant buckets (121, 436, 96) were unreadable keys too.
- **The Firefox stubs** (buckets 72, 52). Those two files are not missing - the
  phone's own archives serve them - and the stubs were hex-named on top of that.
- **Every performance claim.** "122 → 3 fallbacks", "97% fewer micro-stalls" and
  "71% reduction" were all measured with the patch files sitting at addresses the
  loader never asked about. The numbers were real readings; their cause was not the
  patch. The one honest measured count on my device, in a played match, was 29
  fallbacks, 28 of them from `dissolve_void.fx`, and no res_patch entry moves it.

## 2.4 (2026-10-30)

Fixed the *keys*: the loader normalises the request path (`/` to `\`, lowercase,
leading `res\` dropped) before hashing it, and v2.2/v2.3 had hashed the forward-slash
spelling the log prints for display. The three mech configs moved from 616 / 510 / 159
to 293 / 166 / 346, and payloads became real schemas. This proved the files were
*readable*, which turned out to be only half the requirement - 2.5 fixed which of them
are *reachable*.

## 2.3 (2026-10-29)

Same five payloads as 2.2; the lightmap `.fx` arms were demoted out of the shipped
set. The ten v2.0 buckets were moved aside rather than deleted.

## 2.2 (2026-10-18)

Added the Firefox (72, 52), Aurora (186, 616) and Hotsteel (236) stubs and the
Samsung `g93shader` shader variants (121, 436, 96), and grew the GPU database to 478
rows. Never verified against the loader's own path spelling, so none of it loaded.

## 2.0 (2026-10-18)

First public release: 13 buckets, the GPU database in bucket 942, three shader
rewrites and their Samsung variants, and the mech stubs. Shipped as "95% less
stutter". The keys were computed from the wrong spelling of every path, so the whole
set was decoration.

## 1.0 (2026-10-16)

Device table with 42 GPUs, three `.fx` shader patches, a quality override. The
shader work here is where the `g_mBone` iteration below comes from.

---

## The shader patching iterations, and what they actually meant

Run against `lightmap_nx2_mobile.fx` / `dissolve_void.fx` rewrites placed at
`res_patch/902` and `res_patch/230` - both unreadable keys - and at the wrong layer
(the engine opens the compiled `.nfx`). The fallback counts moved, which I read as
the patch working. It was not attributable.

| Patch | What it did | Fallbacks | Real conclusion |
|---|---|---|---|
| 1 | declared `g_mBone[60]`, never used it | 62 | measurement, not a result |
| 2 | declaration + fake reference | 39 | measurement, not a result |
| 3 | full bone matrix multiplication | 149 | engine validator rejects this |
| 4 | fake usage + `TShader` technique | 35 | measurement, not a result |

What survived from that work, verified independently of the patch:

- fallbacks correlate with micro-stalls on this device (1 fallback → 0.84 stalls/sec,
  82 → 2.49), measured from the game's own log;
- `does not support GpuSkin, so GpuSkin convert to CpuSkin!` is an engine
  material-system decision, not a driver one, so ANGLE or Vulkan does not address it;
- the engine supplies `GPU_SKIN_ENABLE` itself per object type, and warns at boot that
  GPU skinning on Android "is not recommended";
- other stall sources exist besides skinning: script errors on breakable models,
  network-sync errors, and memory pressure around 1.77 GB PSS.

## Open leads

1. `res\effect_cache\shader\<name>.nfx\<16-hex>_1_1_gl.pipe` is the device's own
   compiled-pipeline cache, and the 16 hex digits look like the macro bitfield - so a
   skinning permutation may be addressable if the stock `.nfx` contains one.
2. `device_compatibility.py` runs a `DEVICE_NEED_LIMIT_GPU_SKIN` check at boot. It
   lives in `p_script.npk`, whose entries are all `NXS\x03G93` containers, so this
   needs script extraction first.
