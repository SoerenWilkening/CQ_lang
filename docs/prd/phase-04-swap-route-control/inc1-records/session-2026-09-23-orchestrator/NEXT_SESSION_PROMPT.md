# NEXT SESSION — bd `test_C_libtooling-fn1q`, increments 3–5

Read, in this order:
```
CLAUDE.md          (§4i is NEW and it CORRECTS §4h, which corrected the bead.
                    §4h moved to docs/CLAUDE-HISTORY.md)
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-23-orchestrator/
    MEASUREMENT.md   ← the re-derived fence map, with its probes
    IMPL_INC2.md · GATES.md · CLOSING_REPORT.md
    probes/README.md · probes/inc2/README.md · probes/r13r1/README.md · probes/r13r2/README.md
```
Then `bd prime`, `bd show test_C_libtooling-fn1q`, `bd show test_C_libtooling-cfmv`.

```
main 2ca1b785
cq-opt       a0e31e0316496f71a6843cf8c31aebb81bcfbdc6fea162b5d34c0d32cc4d000b
libCQPass.so 7920b44cc1ac809b8c51570524181a35d57c5b76a3a82bba68b9501ef6f778f1
ctest 474/474 in 545.99 s (load 21→53) · lit 2130 (2129 + 1 XFAIL)
fixtures 2130 · goldens 408 · LLVM = /usr/local/opt/llvm@19/bin (NOT on PATH)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.
**This binary is the ORACLE for your A/B.**

---

## 0. ⚠ TWO FENCE MAPS FOR THIS BEAD HAVE NOW BEEN FALSIFIED BY MEASUREMENT. DO NOT TRUST A THIRD ON PAPER.

The bead's own map was corrected on 2026-09-22. **That correction's first fence is also
wrong** — removing `MergePhiPeel` P9 changes `owner.c` not at all, and the peel cannot
lower the shape in any form (both merge φ are ARM-DEFINED; `phiPeelable`'s contract
forbids hoisting one out). **A CORRECTED BISECTION IS STILL A BISECTION AND INHERITS
THE SAME BURDEN.** Measure a fence by REMOVING THE CLAUSE, never by reading it.

**The map that is measured** (§4i, `MEASUREMENT.md`): the owner's program sits behind
`PredMuxFlatten`'s **E2-cycle**, **E6-condtree** and **E4-gep**, and with all three
bypassed it compiles verbatim — rolled, 106 lines, 2b STRICT clean, shipped idiom, no
new symbol. Owner ruled that route on 2026-09-23, with **E4 admitted only with a PROOF**
of in-bounds-ness.

**Increment 2 (the E6 rail LEAF) is LANDED.** Increments 3–5 remain.

---

## 1. ⚠ INCREMENT 3 (the rail φ) IS NOT A ONE-LINE WIDENING, AND ITS OBVIOUS DISCRIMINATOR IS ALREADY REFUTED

`isCondRailPhiShape` (`SelectClassify.h`) recognises the SHAPE — any 2-incoming `i1` φ
— and is **WEAK BY DESIGN**. Its downstream consumers do not rely on it alone: the 4.4
select path gates it behind `AllowRailPhi` and PROVES it by asking
`preppedRailPhiRegionIdx` whether a CLAIMED state-prep region owns the φ.

⚠ **E6 CANNOT ASK THAT PROOF.** `PredMuxFlatten` runs at `CQLoweringPass.cpp:366/390/419`,
**before** `detectControlRegions` (`:582`), so there is no `ControlPlan` yet.

**MEASURED, and this is the part that kills the obvious alternative.** All three
candidate programs have the IDENTICAL IR shape:
```llvm
  br i1 %cond, label %prep, label %join
prep:
  %b = call i1 @cq_theta_i1(…)        ; a rail LEAF
  br label %join
join:
  %rp = phi i1 [ %b, %prep ], [ false, … ]
  br i1 %rp, …                        ; the region's condition
```
and they differ only in `%cond`:

| probe | `%cond` | with E6 bypassed |
|---|---|---|
| `probes/inc2/railphi_tainted_prep.ll` | tainted compare | **ACCEPTS** |
| `probes/inc2/railphi_classical_prep.ll` | classical compare | **still DECLINES** |
| the owner's `%cq.bank1` | `icmp slt %25, %28` on the carried `Z` | (needs all three gates) |

So the natural discriminator is *"is the φ's defining branch TAINTED?"* — **and it is
refuted**: measured on the oracle, the owner's own prep branch prints
`condBr tainted=0` while the bank φ itself prints `tainted=1`. `Z` is only tainted after
the VALUE region seeds it in round 2, and **`repropagateControlMerges` does NOT re-run
the PredMux fixpoint** (round 2 verified this). A taint-based test at E6 would refuse the
very program this bead exists for.

**So the first job of increment 3 is to find what actually separates them, and to
MEASURE it, not reason it.** Open questions, in the order worth attacking:
1. Where exactly does `railphi_classical_prep.ll` decline downstream with E6 bypassed?
   (It is a classical branch muxing a rail against `false` — is that
   `declineClassicalMuxes`, and is that decline CORRECT?)
2. If it is correct, is a pre-claim test available at all, or is a claim-then-decline
   the honest disposition here? (Round 2's P2-2a already names three surviving
   claim-then-decline shapes as acceptable, so this is a hygiene call, not a blocker.)
3. What does the RAIL BANK do for the owner's φ that it does not do for the probe's?
   `markRailBankAllocas` / `rewriteRailBankCellTypes` are the difference, and neither
   probe exercises them.

⚠ **AND ONE CAVEAT ROUND 2 LEFT UNPROVEN, RE-MEASURED AT THE CLOSE:** it worried that
`isCondRailPhiShape` would be defeated at bd `cfmv`'s eraser with no attribute lie.
`probes/r13r2/X_phi_orphan.ll` **DECLINES on both binaries** — the caveat still has no
subject. It stays unproven in the harmless direction; do not quote it as safe.

## 2. INCREMENT 4 — E2, the acyclic region strictly inside a loop body

The gate is `for (BasicBlock *B : R.InRegion) if (OnCycle.count(B)) return leave("E2-cycle")`.
The shape to admit is a region whose OWN blocks are acyclic and contain neither the
loop header nor a latch. ⚠ This is the neighbourhood CLAUDE.md calls *"eight findings
over six adversarial rounds on one function"*; budget the rounds. The downstream is
already cleared for it — `probes/loop2phi_const.c` **ACCEPTS on the oracle**, which is
the same in-loop multi-value shape with an arm `-O1` happens to if-convert.

## 3. INCREMENT 5 — E4, and the owner ruled its shape

Admit a classical-index load from a const global **only where the access is PROVED
in-bounds for every trip** (`isDereferenceableAndAlignedInLoop` / a SCEV bound). Failure
to prove is a loud decline, so an unprovable index keeps today's behaviour and §4h's
`flat_qc_load` ruling stands unchanged. ⚠ The existing QROM admission
(`classifyQromReadUnderControl`) is NOT the way in: measured, it refuses at its
**index-TAINT** gate, and a power-of-two table still declines (`probes/loop2phi_p2.c`).

## 4. HOW TO LAND EACH ONE — not negotiable

Rule-12 red-green (decline fixture first, watched failing) + a mutation check that it is
non-vacuous · **its own Rule-13 round by an agent that did not write it** · the standing
rolled-vs-unrolled probe with a trailing non-diagonal gate · corpus A/B with the NULL
CONTROL RUN FIRST · a full `ctest -j6` reported WITH ITS LOAD · a tracked fixture AND an
e2e slice (`example/` is not in the repo).

⚠ **BUDGET TWO ROUNDS, NOT ONE.** Increment 2's round 1 returned **BLOCKED** with a P1
that no gate in this tree could see, and round 2 — on the FIXES — returned 0 P1 but
found the same class one eraser over. Both rounds earned their cost.

## 5. SEVEN LESSONS THIS SESSION PAID FOR

1. **A corrected bisection is still a bisection.** Measure a fence by removing it.
2. **When you replace a STRUCTURAL containment with a predicate, ENUMERATE WHAT THE
   STRUCTURE WAS HOLDING.** Paid in increment 1 (a `cq_phi` hoisted and deleted) and
   again in increment 2 (a `cq_theta_i1` swept and deleted), one increment apart.
3. **A ruling written in one stage does not propagate to its sibling by being true.**
   `RegionFlatten.cpp:107` had the exact conjunct and the exact reason.
4. **"Narrow by construction" is a claim that owes an enumeration.** Increment 2's fold
   had a second producer nobody looked for, and the corpus was structurally incapable of
   showing it.
5. **A closed count, or the count is "at least N".** An injected ninth gate slipped past
   four prefixes.
6. **Naming a FileCheck directive in PROSE creates one.** A backticked count token
   failed a fixture.
7. **`bd update --notes` REPLACES.** It wiped two sessions of notes on this bead; they
   were recovered only from the live transcript. Use `--append-notes`.
