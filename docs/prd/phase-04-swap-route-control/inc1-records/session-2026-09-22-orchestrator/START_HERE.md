# Session 2026-09-22 — start here

**OWNER INSTRUCTION 2026-09-21: BOTH WALLS IN bd `fn1q` HAVE TO BE FIXED.**
Not one, not "whichever is cheaper" — both. They are what stands between the
compiler and the owner's own canonical customer program,
`example/grover/grover_oracle_uncompute.c`, as it is written today.

Read `CLAUDE.md` (§4g is new; §4d moved to `docs/CLAUDE-HISTORY.md`; the §5 Q-R1-1
paragraph carries a correction block), then `$PREV/{CLOSING_REPORT,GATES,PROTOCOL}.md`
where `PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-21-orchestrator/`.
Then `bd prime` and `bd show test_C_libtooling-fn1q`.

```
main e107a177 · cq-opt 3368af1262695d7e4c… · libCQPass.so 48b8b4db61777082e9…
ctest 472/472 · lit 2112 · fixtures 2112 · goldens 406
LLVM = /usr/local/opt/llvm@19/bin   (NOT on PATH)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.

## 0. The program, and what is and is not broken

```c
int Z = 5, P = 0, n = 3;
int p[] = {3,2,1}; int z[] = {1,2,3}; bool b0[n];
for (int i = 0; i < n; ++i) {
    if (Z >= z[i]) b0[i] = cq_theta(b0[i], 0.5);
    if (b0[i]) { Z -= z[i]; P += p[i]; }
}
```

⚠ **NOT A REGRESSION.** The old `CLAUDE.md` §4e cascade still compiles on this
binary (exit 0, 90 lowered lines). The owner **edited** the file into this harder
program. ⚠ **NOT THE SCRIPT EITHER** — see §3.

Measured 2026-09-21, bisected:

| variant | verdict |
|---|---|
| cascade + array-valued threshold `if (Z >= z[i])` | **DECLINE** `iteration-local value read after the loop` |
| cascade + two carried handles in one arm `{Z -= 3; P += 2;}` | **ACCEPT**, 89 lines — supported, leave it alone |
| cascade + array value in the arm `P += p[i]` | **DECLINE** `value-arm swap-route under quantum control` |

⚠⚠ **BOTH ARE OVER-DECLINES AND THE FLAT TWIN IS THE PROOF.** Hand-unroll either
and it **COMPILES** — 74 and 66 lowered lines. The compiler is refusing a circuit
it can already build, which is the owner's 2026-09-11 ruling's definition of a
defect. `z[i]` and `p[i]` are **classical compile-time constants at a classical
index**; there is no quantum content in either operand and this is **not** QRAM.

## 1. WALL A — the value arm (`P += p[i]`)

**Candidate sites** (determine which one actually fires; do not guess):
`ir-pass/src/ArmClassify.cpp:6140` and `:6193`, `ir-pass/src/ArmHomogeneity.cpp:204`.
`ArmClassify.cpp:21` documents the taxonomy: *"impure value arm"* for one cause,
*"Q+Q link → value-arm swap-route"* for another.

⚠ **A HYPOTHESIS ALREADY TESTED AND REFUTED — DO NOT RE-CHASE IT.** `:6193`'s
comment attributes this string to an **OUT-OF-ARM hoisted** value op (*"the in-arm
walks consumed nothing"*). **That is not this program.** The stage-1 IR puts both
the load and the add INSIDE the arm block:

```llvm
19:                                    ; the ARM
  %20 = getelementptr inbounds [3 x i32], ptr @__const.main.p, i64 0, i64 %12
  %21 = load i32, ptr %20, align 4          ; CLASSICAL load, IN the arm
  %22 = add nsw i32 %21, %13                ; %13 = the carried handle (tainted)
  br label %23
23:
  %24 = phi i32 [ %22, %19 ], [ %13, %11 ]
```

So the real question is **why a Q+C `add` whose classical operand is a LOAD is not
treated as Q+C**. Two readings worth testing first: the classifier sees the `load`
and calls the arm **impure**; or it cannot prove `%21` classical and falls through
to the Q+Q link case. ⚠ **The string will mislead you either way**: `value-arm
swap-route` names a mechanism **that no longer exists** (6 sites, 28 fixtures;
`CLAUDE.md` records it as one of two such strings, renaming is bd `OQ-13`). The
value arm is a **controlled-copy merge** today. **Read the predicate, not the
message** — and consider whether doing bd `OQ-13` first makes this legible.

**The lowering already exists**, which is why this is a classification gap and not
a feature: `emitValueRegion` hoists the arm's pure chain into the pred and merges
by controlled copy, and the 6.5 `ClassicalCallArmEmit` already hoists an
all-classical-args computation out of a tainted-condition arm. A load from
`@__const` at a loop-invariant-shape address is pure, side-effect-free and
classical. ⚠ Confirm that claim about the address before relying on it.

## 2. WALL B — the condition (`if (Z >= z[i])`)

`ir-pass/src/LoopLowering.cpp:6894` (and its detection-time twin
`ir-pass/src/ArmClassify.cpp:5765` — **one question, two sites, same string by
design**; Rule 14 says fix the question, not one spelling). The firing predicate is
`iterationLocalTaintEscape(L, taint)` under clause **(c3)**, bd `8h7d.12`.

The premise to re-derive: **is (c3) about the VALUE or about the TEMP?** Here the
escaping candidate is a per-trip `load` whose ADDRESS is a loop-invariant-shape GEP
and whose VALUE is classical and re-read every trip. "Iteration-local value read
after the loop" is a claim about a tainted temp outliving its activation; a
classical per-trip load is not that.

⚠ **(c3) HAS ALREADY BEEN NARROWED ONCE** (bd `8h7d.12`, blast radius one fixture in
2106). Read that history before touching it, and re-measure the blast radius: this
is the clause `CLAUDE.md` §4e names as one of the owner's rolled-cascade walls.

## 3. DO THIS FIRST — 15 minutes, and it is why this was reported as a script bug

`tools/show_pipeline.sh` runs under `set -euo pipefail` with **no failure banner**,
so a **compiler decline** at stage 2 kills the script after a full stage-1 IR dump
and leaves one bare `error:` line on stderr. It reads as a broken script. Add a
trap on stage 2 that prints a `STAGE 2 · DECLINED` banner with the diagnostic and
says in words that this is a compiler decline, not a script error.

## 4. HOW TO LAND THEM — and this is not negotiable

**TWO INCREMENTS, TWO FENCES, TWO ROUNDS. Do NOT fix both in one change.** Each is
an ACCEPT-direction widening of a loop/arm fence, so each owes, separately:
* Rule-12 red-green: the decline fixture FIRST, watched failing, then the minimal
  implementation; plus the injection-matrix check that the fixture is non-vacuous.
* Its own **Rule-13 round by an agent that did not write it** — the measured hit
  rate in this area is that the first round on new code finds something.
* The standing **rolled-vs-unrolled probe with a trailing non-diagonal gate** on
  every register the condition reads (session protocol item 5).
* A corpus A/B over all fixtures with a **null control run before the real sweep**,
  and a full `ctest -j6`.

**The acceptance target is the owner's file itself**: `./tools/show_pipeline.sh
example/grover/grover_oracle_uncompute.c` exits 0, stderr clean, stage 2b STRICT,
and its trace is adjudicated against the hand-unrolled twin — **byte identity is an
instrument here, not the target** (§4e ruling 2), so read the divergences rather
than requiring zero.

⚠ **FILE-SCOPE CONTEXT YOU MUST KNOW BEFORE YOU START.** `example/` is **NOT IN THE
REPOSITORY** — excluded via `.git/info/exclude`, `git ls-files example/` = 0. No
gate, no corpus sweep and no reviewer can see it, which is exactly why this decline
and a fortnight-old frontend break (bd `1fev`) both surfaced only when the owner ran
the script by hand. That is bd `zwtm`. **Whatever you fix here, land a tracked
fixture and an e2e slice for it**, or the next frontend change breaks it in silence
again.

## 5. Carried lessons that will bite here
* Use `$PREV/probes/entangle.py` (edge-complete, 18 controls) — **not**
  `$PREV/probes/dephase.py`, which ships marked SUPERSEDED with its two misses.
* **Capture `$?` immediately, never after a pipe.** It cost time twice on 2026-09-21.
* Check a control-flow probe **at stage 1 for the shape it claims** (bd `46oo`).
* An e2e slice whose `main` returns nonzero fails with **zero output and no diff**
  (bd memory `e2e-slice-main-return-value-trap`) — this program returns
  `cq_measure(Z) + cq_measure(P)`, so use `(void)…; return 0;`.

## 6. After bd `fn1q` — the standing owner ruling
Pay down P1 correctness debt, starting with **bd `s82e`** — ⚠ **re-measure first, it
may already be fixed** by the 2026-09-21 landing (its malign half is now
byte-identical to its twin). Then bd `a945`, bd `a3z7`/bd `0njv`, bd `yiid` (owner
decision), bd `lo7u`.
