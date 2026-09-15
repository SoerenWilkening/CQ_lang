# Track D — probes and instruments (bd `test_C_libtooling-bbu0`, owner ruling E6, option D)

Three scripts, and the order they are meant to be run in:

| # | script | what it is | what it must NOT be read as |
|---|---|---|---|
| 1 | `fence_pop.sh <BASE_CQOPT> <out>` | derives THE POPULATION — every module on which the BASE binary emits `declineDephasingUnmarkedLoopRails`' literal | a list anyone maintains by hand. `MEASUREMENT.md`'s denominator IS this file's output, so the number and its population cannot drift apart |
| 2 | `bbu0_measure.sh <population> <out>` | THE MEASUREMENT — per population member, does `warnLiveRecordRotations` fire once the fence's decline is deferred past it | a verdict on options A/B/C. It produces the number those are ruled on next session; it rules nothing |
| 3 | `corpus_D.sh <out> [BASE_CQOPT] [SUBJ_ROOT]` | the NO-VERDICT-MOVED gate — BASE vs SUBJECT with the env var UNSET | a correctness gate on the fence. It says only that the instrument is invisible when it is off |

## The one instrument lesson this track had to build in, not inherit

A harness that scored "0 occurrences of the warning" as SILENT would be measuring
its own reachability: the fence is at `CQLoweringPass.cpp:772`, the warn stage at
`:864`, and `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so
on a shipped binary EVERY declining row has 0 warnings **by preemption**. That is
exactly the trap `QUESTION_bbu0.md` §3 names.

So `bbu0_measure.sh` scores `SILENT` **only** when the instrument's own marker
line

```
cq bbu0 instrument: dephasing decline DEFERRED past the warn stage
```

is present. That line can only be printed by `emitDeferredDephasingDecline`,
which is called AFTER `warnLiveRecordRotations` in both entry points — so its
presence is a proof that the warn stage ran. Marker absent ⇒ bucket `PREEMPTED`,
never `SILENT`.

## Committed outputs (facts about named binaries, per PROTOCOL)

| file | binary it is a fact about |
|---|---|
| `population_min.txt` | BASE `15f6a75a50faba7a` — the 17 rows / 12 programs the fence declines |
| `measure_dd5887fc.txt` | SUBJECT `cq-opt` `dd5887fc2852612c` |
| `measure_d4bf79c1_plugin.txt` | SUBJECT `libCQPass.so` `d4bf79c1473ea26d` via stock `opt` — **fields 1-6 diff EMPTY against the `cq-opt` run**, which is Track T's two-binary discriminator answered rather than assumed |
| `oracle_3way_0e280fc6.txt` | the frozen session ORACLE — the five accept-mode controls and the seven `†` rows |
| `corpus_dd5887fc.txt` | BASE vs SUBJECT, env UNSET — the no-verdict-moved gate |

The same marker is pinned character-for-character by
`ir-pass/test/loop_leak_dephase_reject_inloop_rotation.ll`'s `DEFER` prefix,
whose RUN line is a `not %cq-opt` — so the fixture fails if the gated mode ever
turns the decline into an accept.
