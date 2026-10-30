# The two GPU device tables

These are the files behind "new phones get proper settings instead of the floor":

| File | What it is |
|---|---|
| `mobile_device_level.json` | the GPU performance database: stock rows untouched, **478 rows total** (309 modern chips added - Adreno 8xx, Immortalis-G925/G935, Mali-G615/G620/G715/G720/G725/G925, Xclipse 940-960, Apple A18-A21). Verified a strict superset: nothing dropped, nothing re-graded. |
| `device_quality_conf.json` | the per-device quality override: stock rows untouched, two added (Adreno 829, Mali-G615 MC2). |

A chip missing from the first table is graded `2.0`, which is the floor. That is the
problem these files solve.

## Do NOT drop them into `res_patch`

I shipped them there in v2.0 through v2.4, at buckets 942 and 554, with correct keys.
They loaded nothing, ever. Measured on 2026-10-31 by putting one of them at the *same
key* in two channels with two different answers:

```
res_patch  is CREATED after every archive in the APK  -> only answers a request
                                                         no archive can answer
patch_npk  is INSERTED before them                    -> overrides a shipped file
```

Both of these paths already exist inside `aab_res.npk`, so `res_patch` is never asked
about them. Putting one of these files in `res_patch` gives you a file that parses,
sits there, and does nothing - the most convincing kind of failure, because the folder
looks correct.

## Where the 478-row table file is

`device_quality_conf.json` (316 bytes, four rows) is in this folder. The GPU
performance table is 13,712 bytes of pure data, and it is not re-uploaded here
because it is already byte-identical in this repo's history - it was the v2.0
"bucket 942" payload, and v2.5 changed only *where* it belongs:

```
13,712 B   md5 05c1e7ad994819f2bbef8e2763acd936
https://github.com/whatwhawhaamidoing/SMC-GPU-Tweak/blob/d76bf0c80db0df86fd6de80117ecc3225f45eee7/SMC-GPU-Fix-Repo-v2.0/res_patch/942/14911336842006735291
```

Same bytes, verified against the payload that the full setup writes into
`patch_npk\p_res_1.npk`. Check it yourself:

```powershell
# after downloading the file above
certutil -hashfile downloads\14911336842006735291 MD5
```

## How they get installed instead

They have to be *added as entries into a `.npk` pack* that the game loads from
`patch_npk\`. The hash key rule is the same inside a pack, so an entry can be appended
without unpacking anything. That means:

- pull the phone's own `patch_npk\p_res_1.npk`,
- add these two files as new entries at their hash keys,
- write it back and let the kit rebuild `patch_npk_info.config` (it builds the config
  from whatever packs it finds, so the pack size never has to be tracked by hand),
- back the original up first, so it is reversible.

The full community setup does exactly this and ships the resulting pack (43 MB), which
is why it is not here: dropping someone else's 43 MB pack over yours would delete
whatever your own pack held. This repo stays small and universal, and these two files
are here as the *content* for whoever builds a pack - or as a reference for what the
full setup already put in yours.

## What to expect from a working install

A served table row sets the **default a fresh install begins with**. It does not
outvote a stored choice: on the phone I test with, the session where the pack said
`quality 1, resolution 1` still applied `quality 2`, and the resolution, worker limit
and vertex-half settings matched the no-table run exactly. The graphics slider, once
touched, wins.

So the honest readout is not the setting line:

```
device_compatibility.py:540  It is custom_default_quality check: device:<model>
device_compatibility.py:557  Use custom quality:2, resolution:2.....     <- use this
global_display_setting.py:659 set display quality to 2 current quality 2 <- not this
```

`:557` absent means the pack did not serve the row. `:659` tells you what the game
finally used, which the table often does not control.

If you want to see whether the tables are live in your install, do a clean install
(or clear the game's data) and watch the quality the game starts on before you touch
anything.
