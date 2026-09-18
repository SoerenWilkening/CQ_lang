# bd `fn1q` increment 5 (the RAIL φ at E6) — SCOUTING MEASUREMENTS, not an increment

⚠ **NOT IMPLEMENTED.** This file answers the three measurements the 2026-09-23 brief
demanded *before* any design, and it reframes the question. Nothing here is a fix.

```
SUBJECT cq-opt (post bd cfmv)   ORACLE a0e31e03… (pre-increments 3/4)
```

## 0. THE OWNER'S PROGRAM NOW HAS EXACTLY ONE WALL

Measured, after increments 3 and 4:
```
CQ_PREDMUX_DBG: leave @main entry= merge= gate=E6-condtree
                at:   br i1 %cq.bank1, label %33, label %38
```
`gate=E6-condtree` and **nothing else**. At session start it sat behind THREE gates
(E2-cycle, E6-condtree, E4-gep).

## 1. ⚠ THE CONDITION IS NOT WHAT THE BRIEF'S NAME SUGGESTS — MEASURE IT BEFORE DESIGNING

The brief calls increment 5 "the RAIL φ". In the SOURCE the owner's condition is
`if (b0[i])` — a read of a `bool` ARRAY, i.e. a `trunc` of an `i8` load from the rail bank.
It is a φ only because a stage earlier in the pipeline made it one:

```
CQLoweringPass.cpp:196   while (promoteRailBankCells(M, taint))      <-- FIRST
CQLoweringPass.cpp:374   while (flattenPredMuxRegions(M, taint))     <-- LATER
```

so by the time E6 looks, the bank cell IS register-resident and the branch reads

```llvm
  %cq.bank1 = phi i1 [ %31, %30 ], [ false, %23 ]
  br i1 %cq.bank1, label %33, label %38
```

That answers the brief's question **(c)** — *"what does the RAIL BANK do for the owner's φ
that it does not do for the probe's?"* — **it CREATES it.** The probe's φ is hand-written
into the same shape; the owner's is manufactured by `promoteRailBankCells`. Both arrive at
E6 as the same two-incoming `i1` φ, one incoming a `cq_theta_i1` result and the other the
constant `false`.

## 2. (a) WHERE THE TWO PROBES DECLINE TODAY

| probe | today | with E6 bypassed (previous session) |
|---|---|---|
| `railphi_tainted_prep.ll` | `gate=E6-condtree` (+ a `W-witness` leave) | **ACCEPTS** |
| `railphi_classical_prep.ll` | `gate=E6-condtree` | **still DECLINES** |

So admitting the shape at E6 is **not sufficient** for the classical-prep spelling: the
downstream proves a rail φ through `preppedRailPhiRegionIdx`, which needs a CLAIMED
state-prep region, and a prep under a classical condition is not a region at all.

## 3. (b) THE DESIGN QUESTION, SHARPENED — AND IT IS A REAL TRADE-OFF, NOT A GAP

E6 **cannot** ask `preppedRailPhiRegionIdx`: PredMux runs at `CQLoweringPass.cpp:374/398/427`,
`detectControlRegions` at `:582`, so there is no `ControlPlan` yet. The brief already
refuted the obvious fallback — *"is the φ's defining branch TAINTED?"* — by measurement: the
owner's own prep branch is untainted at that slot, so a taint test would refuse the very
program this bead exists for.

**A structural test IS available**, and it needs neither a plan nor taint:

> a 2-incoming `i1` φ each of whose incomings is either a value `isCondRailLeaf` accepts
> (a `cq_theta_i1` CALL) or an `i1` CONSTANT.

⚠ **BUT IT DOES NOT DISCRIMINATE THE TWO PROBES** — both have exactly that shape. So the
choice is genuinely between:

* **(i) claim-then-decline.** E6 admits the shape; the downstream declines what it cannot
  prove. Increment 2's round 2 already accepted three such shapes as an honest disposition,
  and PredMux is ACCEPT-ONLY by construction, so nothing half-lowers.
  ⚠ **Its cost is DETECT-BEFORE-MUTATE**, and that cost is not hypothetical: bd `cfmv`'s
  round 2 (R4R2-1) filed exactly this — a region CLAIMED AND FLATTENED before a
  contingent owner declined it — as a P2.
* **(ii) a pre-claim test that is necessarily approximate**, refusing some shapes the
  downstream could lower (an over-decline, which the owner's 2026-09-11 ruling calls a
  defect).

**This is an owner decision, not a developer one.** It is the shape of Rule 17's "stop and
bring questions back to the owner": not *"the lowering is hard"*, but *"two dispositions are
each defensible and they trade a known, filed cost against a known, ruled-against one."*

## 4. WHAT IS NOT MEASURED HERE

No implementation, no fixture, no A/B. The downstream behaviour of the owner's program with
E6 bypassed was measured by the PREVIOUS session (it compiles — 106 lines, rolled, 2b
STRICT clean), NOT re-measured here after increments 3 and 4 changed two other gates. ⚠ That
re-measurement is the first thing increment 5 owes, because a route proof taken before two
gates moved is a route proof about a different binary.
