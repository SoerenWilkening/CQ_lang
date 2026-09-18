# GATES — session 2026-09-20

Every row is hash-keyed to the binary it was measured on. Nothing is copied
forward; each line was run on the binary named.

```
ORACLE    cq-opt e7bbfd69a9e25d38…   libCQPass.so 84061321f9d6f974…   (main 00c36e93)
SUBJECT   cq-opt b1f3fd903e62531e…   libCQPass.so …                   (branch 11qv-narrow-carried-handle, d79bd31a)
```

⚠ **REPRODUCIBILITY, worth its own line**: a from-scratch configure+build of the
worktree at `main` reproduced the primary binary **BIT-IDENTICALLY**
(`e7bbfd69…` / `84061321…`). The tree and the shipped binary agree. Rule-13
round 3 independently reproduced the same hash, and also reproduced
`30b80d7f`'s own cited hash for `tu9q-p0-p3-wip`.

| gate | result | cited on |
|---|---|---|
| corpus A/B, all fixtures, exit + stderr + lowered-IR | **0 A→D · 2 D→A · 0 D→D(string) · 1 A→A(stream)** over **2107** | `e7bbfd69…` vs `b1f3fd90…` |
| peel-mutation matrix, clause **(P4)** | **0 movers, 0 crashes** / 2106 | scratch peel build `b3655ac1…` |
| peel-mutation matrix, clause **(P0)** | **0 movers, 0 crashes** / 2106 (the new dead-φ fixture post-dates the glob and is measured separately) | `b3655ac1…` |
| peel-mutation matrix, the **`HandleWidth` record** | **0 movers, 0 crashes** / 2107 | `b3655ac1…` |
| peel **NULL-TAG boundary control** | **0 movers** — the control that caught the harness lying | `b3655ac1…` |
| fixture non-vacuity, `accept_narrow_width` | ORACLE **DECLINES** the module | `e7bbfd69…` |
| fixture non-vacuity, `accept_guarded`, `accept_guarded_no_preheader` | ORACLE **DECLINES** both | `e7bbfd69…` |
| fixture non-vacuity, `accept_dead_phi_unpromoted` | `NOMINT` prefix **FAILS** on ORACLE; the `CHECK` prefix passes there and pins nothing — **stated in the header** | `e7bbfd69…` |
| the width axis, `_Bool`/`char`/`short`/`int`/`long long` | 4 × **D→A**, `int` unmoved; owner's cascade at `short` = **50 trace lines, STRICT 2b clean** | both |
| cross-width structural identity | `i8`/`i16`/`i64` rolled traces **IDENTICAL to `i32`** modulo the width token, except the pre-existing unsigned literal rendering (bd `ix2v`) | `b1f3fd90…` |
| h1ip, one binary at three trip counts | n=0 → `alloc_i32(7)` + `measure` · n=1 → 14 lines · n=2 → the full chain twice, `h0→h3→h7` | `b1f3fd90…` |
| h1ip owed probe (rolled vs flat, trailing non-diagonal gate) | rolled **DECLINES** in both spellings; flat **ACCEPTS** in one → rolled is strictly **more conservative** | both |
| duplicate-body fixture scan (L8, after two renames) | **9** duplicate groups, **0 contradictory verdicts**, both renamed files **ABSENT** (no resurrection) | — |
| `tests/e2e/CMakeLists.txt` post-union checks | **0 duplicate `add_test` names**, count 454 → **456**, sweep still LAST | — |
| full `ctest -j6` (pre-round-4-fix) | **466/466 in 594.30 s** ⚠ under concurrent agent load (the round-4 reviewer was building; load avg peaked ~44) — **not comparable with a quiet-box figure**, and quoted with its load per Rule 19 | `b1f3fd90…` |

## Rule-13 rounds (independent agents, neither wrote the code)

| round | subject | verdict | P1 | records |
|---|---|---|---|---|
| 2 | bd `zujr` residuals (break loops, the two backstop escapes, `AsLowered`) | `CLEAR-WITH-ITEMS` | **0** | `round2/` (409 lines, 45 probes) |
| 3 | bd `zujr` × bd `tu9q` P0+P3 × `drbq.12` × `xdu2` — the COMPOSITION | `CLEAR-WITH-ITEMS` | **0** | `round3/` (4 binaries, 60 probes) |
| 4 | bd `11qv` + bd `h1ip` (this session's own changes) | **`FINDINGS`** | **1** | `round4/` (27 probes + 4 harnesses, each with a null control) |

⚠ **NEITHER ROUND 2 NOR ROUND 3 RAN A SUITE, BY INSTRUCTION**, so that they could
not perturb the binaries they were measuring. Round 3 ran no lit either, so **no
`FileCheck` line was executed in it**; its corpus is a superset of the IR property
and a subset of the assertions. Both said so themselves.


## Counts at close (re-measured, not quoted)

| quantity | value | was (2026-09-19) |
|---|---|---|
| ctest entries | **466** | 464 |
| `^e2e-` | **456** | 454 |
| `^e2e-slice-` | **398** | 396 |
| `twin-identical` | **44** | 44 (unchanged) |
| `ls ir-pass/test/*.ll` | **2109** | 2106 |
| `ls tests/e2e/*.expected.log` | **400** | 398 |
| twin matrix | **312** expected + **70** quarantine = 382 | unchanged |

⚠ **RE-MEASURED AT THE PUSH, and it had moved again**: the table above first said
**2108**, counted before round 4's red-green fixture
(`loop_carried_handle_reject_narrow_untyped_call_user.ll`) landed. The corpus
sweeps quoting 2107/2108 were each correct for the binary they ran on; the
closing number is **2109**. Re-measure, never quote.

⚠ The fixture count moved by **+3, not +5**: four files were ADDED and two were
RE-DERIVED FROM REJECTS (`reject_narrow_width` → `accept_narrow_width`,
`reject_guarded` → `accept_guarded`), which is a rename, not an addition. A
duplicate-body scan after the renames found **9 groups, 0 with contradictory
verdicts**, and both old names **ABSENT** — no resurrection (L8).


## ROUND 4 — the one that found something, and what it cost

`FINDINGS`: **1 P1, 2 P2, 3 P3**, all on THIS session's own two increments.

| # | severity | what |
|---|---|---|
| F-1 | **P1** | (P4) allowed a user by callee NAME PREFIX (`cq_`/`cqrt_`) — **exactly the three prefixes `declineTaintEscapes` EXEMPTS** — so `opt` **ABORTED at exit 134 from plain C** where the ORACLE declined cleanly. Rule 1 violated by the clause written to uphold it. **FIXED**: the question is the callee's DECLARED PARAMETER TYPE, plus membership of `ThetaCalls`/`MeasureCalls`. ⚠ A name test cannot separate the two cases that matter (`cqrt_copy_<W>_controlled` is also `cqrt_*` and its slot IS `i32` — the retype repairs it); an intermediate membership-list fix refused it and broke the increment's own headline. The clause now asks the same of the LATCH VALUE, for a PRE-EXISTING defect whose loop-free twin aborts on the ORACLE — **verified here, not taken on report** |
| F-2 | **P2** over-accept | the whole bypass φ was whitelisted on ONE proved incoming — a φ over three registers admitted. **FIXED** |
| F-3 | **P2** over-accept | nothing kept `GuardBB` outside an ENCLOSING loop: a nested nest lowered with the trip-1 register minted once per OUTER trip. **FIXED** |
| F-4 | P3 (L7) | the `HandleWidth` justification named a STRUCTURALLY UNREACHABLE consumer. Real one: `lowerOps`' cast capture. **CORRECTED AT THE SOURCE** |
| F-5 | P3 | the narrow-literal ABI rendering — already filed as bd `ix2v` before the round reported; the round adds that this diff ships the FIRST golden pinning it |
| F-6 | P3 | (Z3) admitted i80/i128 by shape. **FIXED** — gated on `widthHasReversibleCopy`, which `OpcodeSupport.h` says in writing to use instead of `.empty()` |

### Re-measured on the FIXED binary `8280ea8d…` (`libCQPass.so` `01fbe0c1…`)

| gate | result |
|---|---|
| the F-1 repro `c2_p4_from_c.c` | **exit 1, clean loud decline** (was exit 134 abort) |
| the F-2/F-3 probes `a1` / `a2` / `b1` | **decline identically on BOTH binaries** |
| corpus A/B, 2108 fixtures | **0 A→D · 3 D→A · 0 string · 1 stream** |
| `loop_carried_handle` family lit | **10/10** |
| new fixture non-vacuity | CHECK **FAILS** on the ORACLE |
| full `ctest -j6` | **466/466 in 482.00 s** |

⚠ **Round 4 ran no full ctest, no corpus A/B, no twin matrix and no mutation
matrix** (the orchestrator owns those); its only test-layer claim is
`lit --filter 'loop_carried'` = 13, **stated with its denominator**. It also
records the L1 dead-φ round-1-grant residual as *not attacked to completion*,
**not cleared**.
