# SMC GPU Fix - v2.5

Make Super Mecha Champions (Global, `com.netease.g93na`) stop crashing on certain
mechs, and stop guessing about what the previous versions of this repo claimed.

**Version:** 2.5 (2026-10-31)
**Works on:** any Android device with the game installed, no root, no APK changes
**Size:** three JSON configs, about 300 bytes total

---

## What this actually fixes

Three configs that the game asks for and that do not exist anywhere in its
archives. When the engine cannot open them it carries on for a while and then dies
on a null pointer - on the reports I got, always on high-end phones.

| File the game asks for | Mech | Symptom |
|------------------------|------|---------|
| `confs\soft_bone_param_8003_8003.json` | Aurora (8003) | crash on jump + boost |
| `confs\soft_bone_param_8004_s03.json` | Hotsteel (8004) | crash on transformation |
| `confs\mecha_skin_201800300_trigger_res.json` | mecha skin trigger | crash on skin-triggered FX |

Each one is replaced by a config with the same four keys the game's own sibling
configs use, in the same shapes, with the collections empty. So bone simulation
and skin-triggered FX switch off instead of the engine guessing. Nothing is
invented: v2.0's versions here used keys the reader never looks at.

## What this does NOT fix, and what v2.0 promised wrongly

I have to be blunt about this, because the v2.0 README here claimed all four of
these things and only one of them was ever true.

- **GPU skinning fallbacks ("122 down to 3, 95% less stutter") - NOT a result.**
  The stutter numbers in the old README were measured while the fix files sat at
  addresses the loader never asks about, so nothing they contained was ever read.
  The real cause of the remaining fallbacks is that the engine loads the compiled
  `.nfx` and decides GPU skinning itself, per object type. No file swap in this
  folder can change that. See HOW-IT-WORKS.md.
- **The 478-GPU device table - NOT delivered by this repo.** It works, but not
  from here: `res_patch` can only answer a request no archive can already answer,
  and both device tables exist inside `aab_res.npk`. They have to be added to a
  `patch_npk` pack instead. Details and the two config files are in
  [gpu-tables/](gpu-tables/).
- **The Firefox (8002) crash - not explained, and its stubs were removed.** The
  two files blamed for it (`feng_sk_01.gim`, `shamo_yanchen.sfx`) are not missing;
  the game's own archives serve them.
- **Samsung `g93shader` shader patches - withdrawn.** G93SHADER-FIX.md is gone
  because the fix it described could never load.
- **Mech configs that DO work** are the three in the table above.

One more honest limit, so nobody files a bug: even the device tables only set the
quality a *fresh install* starts from. If you have already touched the graphics
slider, your stored choice outvotes the table.

## Install

Prerequisites: Windows with PowerShell, ADB (`platform-tools`), USB debugging on,
the game already installed.

```powershell
# 1. extract the zip (Code > Download ZIP), then open PowerShell inside the folder
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 2. look first, change nothing
.\deploy_gpu_fixes.ps1 -CheckOnly

# 3. apply
.\deploy_gpu_fixes.ps1
```

If adb is not on your PATH, point the script at it:

```powershell
.\deploy_gpu_fixes.ps1 -AdbPath "C:\platform-tools\adb.exe"
```

The script pushes `res_patch\` and **moves** the fourteen dead buckets from older
versions into `res_patch\retired/`. It never deletes anything on your phone, and
re-running it is safe.

Everything lands in:

```
/sdcard/Android/data/com.netease.g93na/files/netease/smc/res_patch/
```

Restart the game after it finishes.

## Verify

The game's own log is the measurement:

```powershell
adb logcat -d | Select-String "JsonConf cannot open"
```

Those three `confs\...` paths should no longer appear once you are past the login
screen and into a match. If you want the numbers from a real game session, use the
game's own log file:

```
/sdcard/Android/data/com.netease.g93na/files/netease/smc/log.txt
```

Do not expect the GpuSkin fallback count to move. Nothing in this package changes
it, and I would rather tell you that here than have you chase it.

## Layout

```
.
├── README.md                 this file
├── CHANGELOG.md              what each version did, and what was wrong about it
├── HOW-IT-WORKS.md           the placement rule, the loader priority, the proofs
├── MECH-CRASH-FIXES.md       the crash reports these configs came from
├── deploy_gpu_fixes.ps1      the installer
├── res_patch/                the three configs, at the keys the loader reads
│   ├── manifest.json         path -> bucket/hash64 for every file here
│   ├── 293/1362819922606888115
│   ├── 166/4244815890268553029
│   └── 346/13576069530125611063
└── gpu-tables/               the two device tables, and why they need a .npk
```

## Related

The full community setup (APKs, skin packs, the kit, and the device tables inside
`patch_npk\p_res_1.npk`) is a separate download - it re-installs the game, so take
what you need from there instead of mixing the two by hand.

## Credits

Crash reports and logs from community members on Samsung and Xiaomi flagships.
NeoX hash and NPK format work from the NeoXtractor project. Nothing here modifies
the APKs or the engine.

## License

Community use, as-is. Not affiliated with NetEase. Use at your own risk.
