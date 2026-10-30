# The mech crashes these configs came from

## Where the reports came from

These three paths come from crash reports sent in by community members on a Samsung
Galaxy S25 Ultra (Adreno 840), plus the same missing-file lines in that device's
log. They are **not** requests my own test phone makes during boot - which is worth
saying out loud, because it means the fix ships three configs whose crash I could
not reproduce locally. What I could verify locally is the part that had been wrong
before: that the files land at addresses the loader actually opens, and that the
JSON shapes match what the game's own sibling configs use.

| Request path | Mech | Reported symptom | Bucket here |
|---|---|---|---|
| `confs\soft_bone_param_8003_8003.json` | Aurora (8003) | crash during jump + boost | 293 |
| `confs\soft_bone_param_8004_s03.json` | Hotsteel (8004) | instant crash on transformation, `MODEL HAS NOT AIM IK SOLVER` | 166 |
| `confs\mecha_skin_201800300_trigger_res.json` | mecha skin trigger | crash on skin-triggered FX | 346 |

`Arthur` came up in the same reports and was clean: it has complete configs and no
leak during its dash.

## Why an empty config stops the crash

The engine reads these files into a bone/animation parameter structure and then
walks it. When the open fails it carries a null into that walk, and the walk is what
dies. A config that parses but holds nothing makes the walk a no-op: bone simulation
and skin-triggered FX for that mech simply switch off, instead of the engine guessing.

The payload shape is not invented. `soft_bone_param_*` configs in the game's own
archives have exactly four keys, and `mecha_skin_*_trigger_res` has exactly four:

```json
{ "simulation_steps": 30, "air_friction_idle": 1.0, "bone_cols": {}, "bone_chains": {} }
```

```json
{ "anim_id": {}, "anim_effect": {}, "dynamic_effect": {}, "effect_description": {} }
```

The two numbers are the values the sibling configs use; the four collections are
left empty on purpose. v2.0 shipped `version`, `mech_id`, `soft_bone_params` and a
`note` key here - a shape the reader never looks at, which is the second reason it
did nothing (the first being the bucket).

## What is NOT fixed here

**Firefox (8002).** v2.2 claimed this was fixed with two stubs - a 36-byte `.gim`
in bucket 72 and a 32-byte `.sfx` in bucket 52, for `effect\mesh\common\mecha\8002\
feng_sk_01.gim` and `effect\fx\scenes\common\sidou\shamo_yanchen.sfx`. Both premises
are wrong:

- neither file is missing. Both are served by the phone's own archives
  (`aab_res6.npk`, `aab_res7.npk`), so `res_patch` is never consulted for them;
- both stubs were hex-named, and the loader reads decimal names, so they could not
  have been opened even at a reachable address.

A 36-byte empty container at a live address would *replace* a working asset, which
is worse than the crash. Those stubs are removed from this repo. The honest next
step for Firefox is one logcat session around the dash + scroll on a device that
actually crashes, not another guessed file.

**The `_h` variants.** Some sessions ask for suffixed names too - e.g.
`soft_bone_param_8034_s01_h.json`, `soft_bone_param_8008_8008_h.json`. `_h` is not a
global quality rule, it is a per-mech/per-preset spelling, so a stub only covers the
spelling a log actually shows. These three payloads do not include suffixed keys, and
I have not measured whether serving an empty `_h` config changes anything on a device
that tolerates the miss. If your crash log names a `_h` path, send the log line and I
will place that key too rather than guess.

## Verifying an install

```powershell
adb logcat -d | Select-String "JsonConf cannot open"
```

Past the login screen and inside a match, the three paths above should no longer be
there. A crash you can no longer reproduce is the real test, and that one needs the
device that had it.
