# GATES — loop-group merge + fix, session 2026-09-15

**A gate result is a fact about a BINARY** (PROTOCOL.md). Every row below is keyed by the
`shasum -a 256` of the `cq-opt` it ran against, and no row is quoted from another track's record.
⚠ An unfinished gate is an **ABSENCE**, not a failure and not a green; the absences are listed last.

| tag | binary `shasum -a 256 build/ir-pass/cq-opt` |
|---|---|
| **ORACLE** (`main` `74eabd2c`, read-only at `~/Desktop/CQ_lang/build`) | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` |
| **PREFIX** (merged, pre-fix, commit `212a913a`) | `ce3f8f3ddf611acc77b1c5f2a791005aaed7958752e47a436ad7e84fe3610202` |
| **FIX** (merged + bd `emkg`) | `9dd81edb9f949bb584d9dde333193a24e009110954103d014ebe01f5bacb0fff` |
| plugin, FIX | `libCQPass.so` `700b47976704c6dad32ca3aa5e110e048062e68117384968f5f1951675fa1659` |

**PREFIX and FIX were each built TWICE** (a stash / rebuild / unstash / rebuild cycle to obtain the
pre-fix binary for attribution) and each came back **bit-identical both times**. Deterministic build
confirmed, not assumed.

**Both targets, always** — `cmake --build build --target CQPass cq-opt -j2`. The `--target CQPass`
alone false-green trap and Track T's third form (a `cq-opt` segfaulting where the same build's
`libCQPass.so` worked) were guarded by running one module through **both** entry points:

```
opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering n2.s1.ll   -> same diagnostic
build/ir-pass/cq-opt  -load-pass-plugin …        -passes=cq-lowering n2.s1.ll   -> same diagnostic
```
cited: FIX

---

## Gates RUN

| # | gate | command | binary | result |
|---|---|---|---|---|
| G1 | RED baseline, the 3 first fixtures | `cd build && lit ir-pass/test --filter 'nested_(marked\|iterlocal\|iic)_inner\|nested_outer_no_own_rail'` | PREFIX | **3 FAIL, 1 PASS** — the intended red |
| G2 | full lit, pre-fix | `cd build && lit ir-pass/test` | PREFIX | **2043 pass, 1 XFAIL, 5 FAIL** (the 3 red-first + the 2 of FIX.md §1a) — 92.87 s |
| G3 | GREEN, the 4 new fixtures | same filter as G1 | FIX | **4 PASS** |
| G4 | the whole `loop_leak_dephase*` family | `cd build && lit ir-pass/test --filter 'loop_leak_dephase'` | FIX | **11 PASS** |
| G5 | full lit, fixed | `cd build && lit ir-pass/test` | FIX | **2046 pass, 1 XFAIL, 2 FAIL** — the 2 of §1a, then converted |
| G6 | **hand-off gate** | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | FIX | **1/1 Passed, 82.56 s** (2051 fixtures, 1 XFAIL) |
| G7 | injection matrix, 8 accept fixtures | `CQ_T_BUILD=$PWD/build python3 trackT/probes/inject_T.py <8 fixtures>` | FIX | **57 mutations, MISSED 0, N/A 7**, exit 0 |
| G7a | instrument self-attack | `… inject_T.py` with NO fixture argument | FIX | **exit 2** — the "0 mutations, MISSED 0" vacuity trap is armed |
| G8 | corpus sweep, 2051 modules × 3 binaries | `probes/sweep.sh <build> <out>` | ORACLE / PREFIX / FIX | see below |
| G8a | sweep instrument self-attack | `probes/sweep.sh /tmp/definitely-not-a-build out` | — | **exit 2, REFUSE** |
| G9 | binary-mutation validation, per decline fixture | run each `…reject_nested_*.ll` on PREFIX | PREFIX | **all 4 exit 0** ⇒ the fixtures cannot pass there ⇒ non-vacuous |
| G10 | probe harness self-attack | `probes/lv.sh` on a 0-byte `.c` and a quantum-free `.c` | — | **`VACUOUS-NO-QUANTUM` both**, never ACCEPT |
| G11 | twin measurements | `probes/lv.sh` over 11 rolled/unrolled pairs | ORACLE + FIX | in FIX.md §1a, §3, §4 |

### G8 — corpus sweep result

```
ORACLE  2051 rows, accepts=1012 declines=1039
PREFIX  2051 rows, accepts=1018 declines=1033
FIX     2051 rows, accepts=1014 declines=1037

PRE-FIX MERGED -> FIXED (THIS FIX ALONE): 4 movers   A->D 4,  D->A 0,  D->D 0
    A -> D  loop_leak_dephase_reject_nested_depth3_middle_rail.ll
    A -> D  loop_leak_dephase_reject_nested_iic_inner.ll
    A -> D  loop_leak_dephase_reject_nested_iterlocal_inner.ll
    A -> D  loop_leak_dephase_reject_nested_marked_inner.ll

ORACLE -> FIXED (the whole loop group): 13 movers   A->D 2, D->A 4, D->D 7
```

**Every mover of this fix is one of its own new fixtures; no pre-existing module moves, and nothing
moves in the accept direction.** The ANY→ALL half of the change moves **0 of 2051** — stated as an
unwitnessed half, not as a clean bill.

⚠ **G8's FIRST SPELLING WAS A LIE AND IS RECORDED AS ONE.** It reported "0 movers" while all 2050
rows on both sides were exit **127** (`cq-opt` not at the path it was handed). Caught by reading the
`<NO-DIAGNOSTIC-TEXT>` tags, not by the headline. `probes/sweep.sh` now refuses to emit a file unless
the binary and plugin exist, no row is 127, and both verdicts occur (G8a).

---

## Gates NOT RUN — ABSENCES, owed to the merge-and-gate agent (PROTOCOL reserves them)

* `cq-opt-equivalence-full` — **owed**, and specifically: Track S′ moved a decline string and 5
  fixtures mirror it.
* `ctest -R '^e2e-'` and the full `ctest -j6` — **owed**. No e2e layer was run here at all.
* one `e2e-loop-twin-matrix` on a quiet box — **owed**. ⚠ Note that it **cannot see** any shape in
  this landing (no nested-LOOP axis, bd `test_C_libtooling-vsr6`); running it is a check that nothing
  ELSE moved, not a witness for this work.
* `frontend-lit`, `runtime` — not run; nothing here touches `CQ.h`, the YAML or the runtime.

## Box conditions

Load averages ranged **25–54** during this work. Timings above are therefore **not** comparable with
quiet-box figures and are recorded only to show a gate finished. No binary was relinked under a
running measurement, and `pkill` was never used.
