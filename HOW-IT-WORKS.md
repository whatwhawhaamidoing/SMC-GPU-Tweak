# How the override channels actually work

Everything published in this repo rests on the two facts below. Both were measured
on a phone, not read out of a decompiler, and the second one is the reason the
headline feature of v2.0 through v2.4 did nothing.

## 1. Placement: how a file in `res_patch` is named

The engine says its own rule in the boot log:

```
init file system config, enable_string_id: 1, ... config root: ...\smc\res_patch
hash folder count: 1023, loader_tag is patch
```

So:

```
normalised path = request path, "/" -> "\", lowercased, a leading "res\" dropped
hash64          = NeoX composite 64-bit hash (V1 high 32 + MurmurHash3 x86 low 32, seed 0x9747B28C)
file            = res_patch/<hash64 % 1023>/<hash64 written in DECIMAL>
```

Two things cost me weeks of dead payloads:

- **The path is normalised before it is hashed.** The path printed in the log is a
  display string, usually with forward slashes. Hash that spelling and you get a
  bucket the loader never asks about. v2.2 and v2.3 shipped three configs exactly
  that way, at buckets 616, 510 and 159; the correct ones are 293, 166 and 346.
- **Names are decimal, not hex.** v2.0's shader stubs were hex-named, so they could
  never have been opened even at a reachable address.

Independent confirmation that the rule is right, from the phone rather than from
me: the engine writes its own PNG into `res_patch/952/17859796411857743767` during
its session, and `17859796411857743767 % 1023 == 952`. Decimal names, bucket rule,
engine's own output.

There is a second, dumber channel that needs no hashing at all:

```
<smc>\res\<request path>          e.g. <smc>\res\confs\preview_-1.json
```

The boot log creates it as the literal loader (`enable_string_id: 0, root ...\smc\res`) -
the same directory the engine drops its audio downloads and `effect_cache` into.

## 2. Priority: `res_patch` can only fill a gap, `patch_npk` can override

The log uses two different verbs for its file loaders, and that difference is the
whole priority mechanism:

```
Succeeded to CREATE FileLoader, opener asset, loader npk, root aab_res ... ch3
Succeeded to CREATE FileLoader, opener sys,   loader discrete, root ...\smc\res_patch
Succeeded to CREATE FileLoader, opener sys,   loader discrete, root ...\smc\res
[patch_npk_before] insert res npk loader: ...\smc\patch_npk\p_res_1.npk success
```

- `res_patch` and `res` are **created after** every archive in the APK: they are
  gap fillers. A request an earlier loader can answer never reaches them.
- packs in `patch_npk` are **inserted before** them: they win against files the
  game already ships.

I confirmed this on 2026-10-31 with exactly one variable. I put
`confs\device_quality_conf.json` at the same key in both channels, with two
different answers - the `patch_npk` copy said quality 1 / resolution 1, the
`res_patch` copy said the shipped 2 / 2 - and the boot printed:

```
device_compatibility.py:540  It is custom_default_quality check: device:<model>
device_compatibility.py:557  Use custom quality:1, resolution:1.....
```

`1, 1` means the pack answered. Those two lines are absent from every session in
which the pack did not carry the file - including the session where `res_patch/554`
held a matching row for that exact device. So:

- a `res_patch` bucket for a path an archive already serves is **decoration**.
  Buckets 942 and 554 (`mobile_device_level.json`, `device_quality_conf.json`) were
  that for the entire life of v2.0 through v2.4, and this repo shipped them as the
  headline feature.
- the same rule held for `.mesh` and `.ktx` overrides, so it is about the loader,
  not the file type.

## 3. Measuring: use `:557`, never `:659`

"Served" is not "effective". The session that read `1, 1` out of the pack applied
the same settings as the run that read nothing at all:

```
global_display_setting.py:659  set display quality to 2 current quality 2
init_game.py:81                resolution new:1949*900
init_game.py:198               Skip enter low mem mode
init_game.py:244               use_vertex_half 2
```

because a stored user setting outvotes the device table at the apply step. So a
served table row sets the **default a fresh install begins with** and changes
nothing for a profile that has already been touched. If you test a device-table
change, grep `Use custom quality` - what the config returned - and not
`set display quality` - what the game finally used.

## 4. Why the shader patches were withdrawn

The obvious fix was `#define GPU_SKIN_ENABLE 0` in `shader\lightmap_nx2_mobile.fx`,
guarded the way 117 of the 147 shipped `.fx` files with a skinning path already do.
The edit is correct and it still cannot work, because the engine does not read the
`.fx` at runtime - it opens the compiled `.nfx` next to it, and it supplies the
macro itself per object type:

```
[RENDER] [WARNING] Using Gpu Skinning on Android platform is not recommended!
         Because it might cause system failure(rebooting) on some device such as ZTE V988

EffectMgr::CreateObj, filename: shader\vbr_toon_mecha_nx2_mobile.nfx. macros:
    #define GPU_SKIN_ENABLE TRUE     <- object type GPUSkinnedMesh
    #define GPU_SKIN_ENABLE FALSE    <- object type StaticMesh
```

GPU skinning is off by default on Android by design, not because of a stale define.
Patching a source file is the wrong layer, whichever way the define points.

For the record, the real measured number of fallbacks on the device I test with, in
a played match, was 29 - and 28 of them came from `dissolve_void.fx`, one of the
three shaders v2.0 rewrote, which contains no skinning path at all (no `u_bone_vec`,
no blend inputs). Its rewrite also returned `float4(1, 1, 1, alpha)`, i.e. it would
have rendered white instead of dissolving. Two leads are open instead of guessing:
the device's own compiled pipeline cache under `res\effect_cache\shader\`, whose
permutation names are macro bitfields, and the `DEVICE_NEED_LIMIT_GPU_SKIN` check
that lives in `p_script.npk`, behind script extraction.
