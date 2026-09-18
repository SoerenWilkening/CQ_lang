# Session 2026-09-22 — start here

**Owner instruction 2026-09-21:** *"`./tools/show_pipeline.sh
example/grover/grover_oracle_uncompute.c` fails again. We need to fix that first."*
That is **bd `fn1q`**, and it comes before the bd `s82e` work (§4).

Read `CLAUDE.md` (§4g is new; §4d moved to `docs/CLAUDE-HISTORY.md`; the §5 Q-R1-1
paragraph has a correction block), then `$PREV/{CLOSING_REPORT,GATES,PROTOCOL}.md`,
`PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-21-orchestrator/`.
Then `bd prime` and `bd show test_C_libtooling-fn1q`.

```
main e107a177 · cq-opt 3368af1262695d7e4c… · libCQPass.so 48b8b4db61777082e9…
ctest 472/472 · lit 2112 · fixtures 2112 · goldens 406
LLVM = /usr/local/opt/llvm@19/bin   (NOT on PATH)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.

## 1. WHAT IS ACTUALLY WRONG — and it is NOT a regression, and NOT the script

The owner **edited** `grover_oracle_uncompute.c` into a new, harder program: a
knapsack-style loop with **two classical constant arrays** and **two carried
handles**.

```c
int Z = 5, P = 0, n = 3;
int p[] = {3,2,1}; int z[] = {1,2,3}; bool b0[n];
for (int i = 0; i < n; ++i) {
    if (Z >= z[i]) b0[i] = cq_theta(b0[i], 0.5);
    if (b0[i]) { Z -= z[i]; P += p[i]; }
}
```

⚠ **The old CLAUDE.md §4e cascade still compiles on this binary (exit 0, 90 lowered
lines).** Nothing broke. Measured 2026-09-21:

| variant | verdict |
|---|---|
| cascade + **array-valued threshold** `if (Z >= z[i])` | **DECLINE** — `iteration-local value read after the loop` (clause (c3)) |
| cascade + **two carried handles in one arm** `{Z -= 3; P += 2;}` | **ACCEPT**, 89 lines — supported, not the problem |
| cascade + **array value in the arm** `P += p[i]` | **DECLINE** — `value-arm swap-route under quantum control` |

⚠⚠ **BOTH DECLINES ARE OVER-DECLINES, AND THE FLAT TWIN IS THE PROOF**: hand-unroll
either one and it **compiles** (74 and 66 lowered lines). The compiler is refusing
a circuit it can already build. By the owner's 2026-09-11 ruling that is a defect
to remove, not a safety margin.

**What the values are, and why this should lower:** `z[i]` and `p[i]` are
**classical compile-time constants at a classical index**. `-O1` leaves them as a
per-trip `load i32, ptr getelementptr(@__const.main.p, …)` because the loop is
rolled. There is no quantum content in either operand — this is **not** QRAM, and
the tainted-index fence is not what fires.

## 2. The job

**Two separate increments, two separate fences. Do NOT fix them in one change.**
Each is an accept-direction widening, so each owes its own Rule-13 round **and** the
standing rolled-vs-unrolled probe with a trailing non-diagonal gate on every
register the condition reads.

1. **The condition wall** (clause (c3), `LoopLowering.cpp`): re-derive
   "iteration-local value read after the loop" for a load whose **address** is
   loop-invariant and whose **value** is classical and re-read per trip. Start by
   asking whether the (c3) premise is about the VALUE or about the TEMP.
2. **The value-arm wall**: ⚠ the string `value-arm swap-route under quantum control`
   is one of the **two decline strings `CLAUDE.md` records as naming a mechanism
   that no longer exists** (6 sites, 28 fixtures; renaming is bd `OQ-13`). The value
   arm is a CONTROLLED-COPY MERGE today. **Read the predicate, not the message** —
   and consider whether fixing bd `OQ-13` first makes this one legible.

## 3. DO THIS FIRST — 15 minutes, and it is why this was reported as a script bug

`tools/show_pipeline.sh` has `set -euo pipefail` and no failure banner, so a
**compiler decline** at stage 2 kills the script after a full stage-1 IR dump,
leaving one bare `error:` line on stderr. It reads as a broken script. Give stage 2
a trap that prints a `STAGE 2 · DECLINED` banner with the diagnostic and says
plainly that this is a compiler decline, not a script error.

⚠ **And file-scope context worth knowing before you touch any of it:** `example/` is
**not in the repository** (excluded via `.git/info/exclude`, `git ls-files example/`
= 0). No gate, no corpus sweep and no reviewer can see these files — which is
exactly why a fortnight-old frontend break (bd `1fev`) and this decline both
surfaced only when the owner ran the script by hand. That is bd `zwtm`, and these
two are its consequences.

## 4. AFTER bd `fn1q` — the standing owner ruling

Pay down P1 correctness debt, starting with **bd `s82e`**. ⚠ **Re-measure before
writing any fix: it may already be fixed.** On this binary, after bd `tu9q` P0+P3
landed, the **malign (R-diverge) half** — `trackS/IMPL_S.md`'s `s1_live_shift`, the
cell it says *"must NOT be blessed; it is a wrong unitary"* — is now
**byte-identical to its hand-unrolled twin at 14 trace lines**, up from the recorded
10. One pair, not the class; re-measure the whole exhibit set first. Details in
`bd show test_C_libtooling-s82e`.

Then bd `a945`, bd `a3z7` / bd `0njv`, bd `yiid` (owner decision), bd `lo7u`.

## 5. Carried lessons that will bite here
* Use `$PREV/probes/entangle.py` (edge-complete, 18 controls), **not**
  `$PREV/probes/dephase.py`, which ships marked SUPERSEDED with its two misses.
* **Capture `$?` immediately, never after a pipe.** It cost time twice on 2026-09-21.
* A probe for a control-flow shape must be checked **at stage 1 for the shape it
  claims** (bd `46oo`).
* An e2e slice whose `main` returns nonzero fails with **zero output and no diff**
  (bd memory `e2e-slice-main-return-value-trap`) — and this program returns
  `cq_measure(Z) + cq_measure(P)`, so watch for it when you turn it into a slice.
