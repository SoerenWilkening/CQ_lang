# bd `fn1q` increment 5a — Rule-13 ROUND 2 (independent agent, on the ROUND-1 FIXES)

**VERDICT: `BLOCKED` — 1 P1 (A SILENT WRONG UNITARY, REACHABLE FROM PLAIN `CQ.h` C AT `-O1`),
2 P2, 7 P3.**

⚠ **THE HEADLINE IS NOT A DEFECT IN ROUND 1's FIX — IT IS THE HALF OF THE SAME ADMISSION
ROUND 1 NEVER REACHED.** The operating rule for this round was "attack the fix hardest",
and I did: hunks 3 and 4 are each MUTANT-VALIDATED as load-bearing and both are correct
(§4). The P1 is in hunk 2, the original E6 admission, on a path round 1's own "WHAT I DID
NOT DO" pointed at (`A2` in the brief) and which round 1 could not construct.

**Binaries, sha-checked immediately before every verdict quoted below:**

| role | sha-256 (first 16) | what |
|---|---|---|
| ORACLE | `9b9664170fb33f95` | git HEAD `a9a227e4`, no patch. ⚠ **preserved as a byte copy at `$S/r2/cq-opt.ORACLE` BEFORE `wt-oracle` was reused as my mutant tree** — every "ORACLE" row here is that copy, never the worktree path |
| SUBJECT | `5fd7183282ee0d38` | HEAD + increment 5a |
| ASSERTS | `e26fdfed38493013` | SUBJECT, `CMAKE_BUILD_TYPE=Debug` (LLVM `cast<>` assertions live) |
| M2a | `568052cb3fcad2f7` | SUBJECT with **hunk 3 reverted** |
| M2b | `68506afb9243918f` | SUBJECT with **hunk 4 reverted** |
| M3 | `71e352f987d75948` | SUBJECT + my proposed fix, **FIRST spelling — itself a 2-cell regression, see §1** |
| M4 | `fe5805a41df2e173` | SUBJECT + the **corrected** proposed fix |

**Null controls, run before anything was believed.**
* **BUILD null control:** applying `inc5a.patch` to a fresh HEAD worktree and rebuilding
  produced a binary **BIT-IDENTICAL to SUBJECT** (`5fd7183282ee0d38`). The change really is
  only those five files and the build is reproducible.
* **A/B harness null control:** SUBJECT vs SUBJECT → **0 movers**. **Positive control** on
  the same harness (two fixtures known to move) → **2 of 2 caught**. A harness that has only
  been run against a null measures nothing; both directions ran.
* **+Asserts sweep null control:** a module known to abort (`p4_jlast.ll`) appended to the
  corpus list; it must appear in the output.
* ⚠ I injected that null-control fixture into the project's `ir-pass/test/` for ~60 s,
  noticed it, killed the sweep, removed it and re-ran with the probe read from my scratchpad.
  `git status` is back to the session-start set. Recording it because a stray file in a
  shared corpus is how another session's sweep gets a phantom row.

---

## P1 — `R5aR2-1`: a rail φ E6 admits is **never RECORDED**, so `convertPhis` converts it by the **SELECT CHAIN**, and `buildNegation`'s **SECOND unchecked cast** then builds a **WRONG PREDICATE** — silently

### The exhibit: ordinary `CQ.h` C, `clang -O1`, no `volatile`, no attribute `CQ.h` cannot emit

```c
#include "CQ.h"
static const int tbl[4] = {1, 2, 3, 4};
static int slice(int u, int t, int j) {
    int q = cq_theta(u, 0.5);
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(t, 0.5);
    int v = 7, w = 8;
    if (r < 9) {
        bool e; int s;
        if (q > 5) { e = b;    s = tbl[j & 3]; }
        else       { e = true; s = 0; }
        if (!e) { v = tbl[s & 3]; w = tbl[(s + 1) & 3]; }
        else    { v = 5;         w = 6; }
    }
    return cq_measure(v) + cq_measure(w) + cq_measure(b);
}
int main(int argc, char **argv){ (void)argv; return slice(argc, argc + 1, argc); }
```
(`$S/r2/exhibit/c13.c`; `c12.c` is the same defect with a `volatile` index, kept because it
was found first.)

| binary | rc | stderr | result |
|---|---|---|---|
| ORACLE | 1 | `error: … cq controlled lowering: control flow under quantum control` | loud decline, twice at `gate=E6-condtree` on `br i1 %16` |
| **SUBJECT** | **0** | **0 BYTES** | **29-line trace, links, runs** |
| ASSERTS | 134 | `Assertion failed: (isa<To>(Val) && "cast<Ty>() argument of incompatible type!"), Casting.h:578` | names the cast |
| M4 (my fix) | 1 | identical to ORACLE's | loud decline restored |

`free_pairing_check.py` on the SUBJECT's output: **`2 verified, 0 violation(s), 0 unproven`**
— structurally perfect, semantically wrong. `opt -verify` clean. This is the Prime
Directive's named failure mode verbatim.

### The emitted circuit is WRONG, and the rail is not even a control

Emitted (SUBJECT): `h_cmp = icmp_sge(r, 9)`; `out = 7 if h_cmp else 5`;
`out3 = 8 if h_cmp else 6`. **That is the whole circuit.** The `q > 5` compare is ABSENT
from the trace (`grep -c sgt` → 0), the entire `if (!e)` arm and both table reads are gone,
and the rail `h6` is `cqrt_alloc_i1` + `cqrt_ry_i1` + `cqrt_measure_i1` — **never used as a
control anywhere**.

Source, on the basis states `r < 9 ∧ q > 5 ∧ b = 0`: `e = b = 0`, so
`v = tbl[s&3]`, `w = tbl[(s+1)&3]`. Circuit: `v = 5`, `w = 6`. **Wrong unitary.**

### The mechanism, end to end

1. Hunk 2 puts `if (!Strict && isStructuralRailPhi(V)) return true;` **BEFORE** the
   `dyn_cast<PHINode>` arm, so the φ never reaches `isConvertiblePhiCond` and is never
   inserted into `S->Recorded`.
2. `run()` calls `convertPhis(D)` for every region block except `R.Entry`. For a φ **not**
   in `R.BoolAlgPhis` the BoolAlg gate re-checks each incoming with
   `isBooleanCondTree(IV.second, 0)` — **null scope, and a `cq_theta_i1` CALL is off that
   grammar** — so `BoolAlg = false` and the φ falls to the **Inc-1 select chain**.
3. The chain emits `Acc = select(EP, In[0].second, In[1].second)`. For the incoming pair
   `[%rail, %P], [true, %Q]` that is `select(EP, %rail, true)`.
4. `literal(J, 1)` = `buildNegation(select(EP, %rail, true))`. Its select arm is:
   ```cpp
   if (auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue()); FC && FC->isZero()) { …or… }
   auto *TC = cast<ConstantInt>(Sel->getTrueValue());   // UNCHECKED, and TC is UNUSED
   (void)TC;
   return track(B.CreateAnd(buildNegation(Sel->getCondition()),
                            buildNegation(Sel->getFalseValue())));
   ```
   `FalseValue` is `true` (a `ConstantInt`, not zero) so arm 1 is skipped; the terminal cast
   assumes `TrueValue` is the constant `1`. It is `%rail`. **In Release `cast<>` is
   `assert(...)` + `static_cast`, and `TC` is discarded — so there is no crash at all.** The
   function returns `and(¬EP, ¬true)` = `and(¬EP, false)`, which IRBuilder folds to
   **`false`**. The C arm's edge predicate is constant-false, its value is dropped from the
   merge, its whole cone is dead-swept, and the rail disappears from the predicate tree — so
   nothing off-grammar survives for a downstream owner to object to. **The silence is
   structural, not lucky.**

⚠ **THIS ANSWERS THE BRIEF'S TARGET (B), WHICH ROUND 1 LEFT OPEN.** Round 1 asked whether a
bad cast could "yield a garbage `Value*` that builds a WRONG PREDICATE instead of crashing".
For *this* cast the answer is worse than the question: the result is **never read**, so
Release does not crash *or* mis-read — it just proceeds on a false assumption. A `+Asserts`
build catches it; the shipped Release build every gate here runs does not.

### Attribution: hunk 2 alone. NOT round 1's fix.

| mutant | `p4_jlast.ll` (the IR probe) | `…_reject_rail_phi_false_edge.ll` | `acc_false` |
|---|---|---|---|
| SUBJECT | **rc=0 (wrong accept)** | rc=1 decline | rc=0 accept |
| M2a (hunk 3 reverted) | **rc=0 (wrong accept)** | **rc=139 SIGSEGV** | rc=139 SIGSEGV |
| M2b (hunk 4 reverted) | **rc=0 (wrong accept)** | rc=1 decline | rc=1 decline |
| M4 (proposed fix) | rc=1 decline | rc=1 decline | rc=0 accept |

Reverting either half of round 1's fix leaves the P1 intact, so it is not the fix's defect.
(The table also re-validates round 1's F1 non-vacuity claim independently: **hunk 3 reverted
⇒ exit 139**, and hunk 4 reverted ⇒ the negated polarity becomes a claim-then-decline. Both
halves are load-bearing — brief target (F), verified in both directions.)

### The population, measured — exactly one of six incoming shapes goes silent

Same interior-φ CFG, seven variants, ORACLE vs SUBJECT:

| φ incomings | `convertPhis` yields | `buildNegation` | SUBJECT |
|---|---|---|---|
| `[%rail, false]` | `select(EP,%rail,false)` | arm 1 — **correct** | decline |
| `[true, %rail]` | `select(EP,true,%rail)` | arm 2, `TC` really is one — **correct** | decline |
| **`[%rail, true]`** | `select(EP,%rail,true)` | **cast fails, → `false`** | **ACCEPT (the P1)** |
| `[false, %rail]` | `select(EP,false,%rail)` | cast *succeeds* (`false` is a `ConstantInt`) but `isOne()` is never asked → `and(¬EP,¬rail)`, **wrong** | decline (saved downstream) |
| `[%rail1, %rail2]` | `select(EP,r1,r2)` | cast fails → `and(¬EP,¬r2)`, **wrong** | decline (saved downstream) |
| `[true, false]` / `[false, true]` | BoolAlg (re-check passes on `i1` constants) | n/a | **byte-identical to ORACLE** |

The three wrong-but-declining rows are wrong predicates that happen to keep `%rail` in the
tree, where `collectCondTree`'s refusal of an `xor` with a constant operand catches them.
That is a downstream accident, not a fence.

### Proposed fix — MEASURED, and ⚠ MY FIRST SPELLING OF IT WAS ITSELF A REGRESSION

Gate the E6 rail-φ arm on the φ being one this flatten will **not** convert — the exact
mirror of `isConvertiblePhiCond`'s condition 2, which exists for this hazard and says so.

⚠ **THE SPELLING MATTERS AND I GOT IT WRONG FIRST.** My first draft (M3,
`71e352f987d75948`) `return`ed the conjunct's value from inside the arm. That **DECLINED an
all-constant 2-incoming `i1` φ at a region-interior block** — a shape BOTH the ORACLE and
the SUBJECT accept, byte-identically — because such a φ also satisfies
`isStructuralRailPhi`, and returning `false` stopped it reaching `isConvertiblePhiCond`,
which legitimately admits it (an `i1` `ConstantInt` IS in the strict `isBooleanCondTree`
grammar). Two A→D cells, caught by my own probe matrix, not by reasoning. **The arm must
FALL THROUGH, not return.** Corrected as M4 (`fe5805a41df2e173`):

```cpp
  if (!Strict && isStructuralRailPhi(V)) {
    // `run()` converts every region block's phis EXCEPT the entry's. A φ it WILL
    // convert does not stay a φ: `convertPhis` re-checks the BoolAlg grammar
    // scope-lessly, a `cq_theta_i1` CALL incoming fails it, and the φ becomes a
    // general `select` that `buildNegation` mis-negates into a constant.
    // ⚠ FALL THROUGH rather than return false — an all-constant i1 φ also matches
    // this predicate and `isConvertiblePhiCond` legitimately admits it.
    const auto *RP = cast<PHINode>(V);
    BasicBlock *RPB = const_cast<BasicBlock *>(RP->getParent());
    if (S && S->InRegion && (RPB == S->Entry || !S->InRegion->count(RPB)))
      return true;
  }
  if (const auto *P = dyn_cast<PHINode>(V))
    return !Strict && isConvertiblePhiCond(P, S, Depth);
```

Measured on **M4**, 17 probes + 3 C programs + the 3 increment fixtures:
* `c13.c`, `c12.c`, `p4_jlast.ll`, `p9_twofunc.ll`, `p6_nomeasure.ll` → **loud decline, the
  ORACLE's string**.
* **the owner's `slice_grover_oracle_uncompute.c` still compiles and its lowered module is
  BYTE-IDENTICAL to the SUBJECT's** (exit 0, 0 bytes stderr, 88 trace lines, golden match,
  stage 2b STRICT `3 verified, 0 violation(s), 0 unproven`).
* `control_predmux_{accept,reject}_rail_phi_cond.ll` and `…_reject_rail_phi_false_edge.ll`
  keep their verdicts and strings.
* `acc_true`, `acc_false`, `p7_and_tree` → **byte-identical to SUBJECT**.
* the all-constant interior cells `v_true_false` / `v_false_true` → **byte-identical to BOTH
  ORACLE and SUBJECT** (the M3 regression is gone).
* ⚠ It is still a NARROWING of an accept predicate, so L3 applies: it owes its own red-green
  pair (an interior-φ decline fixture whose `DBG:` line pins `gate=E6-condtree`, so it
  cannot pass on the defective binary for someone else's reason) and its own Rule-13 round.
  ⚠ **And take the M3 regression as the warning it is: the corpus A/B I ran did not exist
  when I wrote M3, and the two cells it broke are in NEITHER the committed corpus NOR round
  1's probe set — I only saw them because I had built a variant matrix over the φ's incoming
  shapes.** Whoever lands this owes that matrix, not a spot check.

**A second, independent fix is owed regardless** — see `R5aR2-3`: `buildNegation`'s select
arm should test `TC->isOne()` and refuse otherwise, the way `canonicalizePred`'s twin arm
already does, so that a future producer of a general `select` cannot silently mis-negate.

---

## The rest, severity-ranked, with a disposition per row

| # | sev | finding | disposition |
|---|---|---|---|
| R5aR2-1 | **P1** | above | **BLOCKING.** Fix proposed and mutant-validated; not applied by me (review, not repair). |
| R5aR2-2 | P2 | **The increment's own central claim is FALSE.** *"The VERDICT is preserved and no decline becomes silence"* is written in FOUR places (`SelectClassify.cpp` `isStructuralRailPhi` header, `PredMuxFlatten.cpp` E6 ×2, `control_predmux_reject_rail_phi_cond.ll` header). Round 1's F2 corrected the **string** half of exactly this sentence and left the **verdict** half asserted — and the verdict half is the one that is wrong. `c13.c` turns a loud decline into a running wrong circuit | **NEEDS CORRECTING AT ALL FOUR SITES** in the same change as the fix. ⚠ §4i's lesson literally: *a corrected record that is not applied to the source is not a correction* — this is the second round in a row to find the same sentence wrong, in a different half each time. |
| R5aR2-3 | P2 | **`buildNegation`'s select arm never asks `isOne()`.** It infers "TrueValue is the constant 1" from "FalseValue is not the constant 0". `canonicalizePred`'s twin arm (`PredMuxFlatten.cpp:3946`) DOES test `TC->isOne()`. So the two functions disagree about the same grammar, and the disagreement is on the negating side. Consequence beyond the P1: `select(c, false, X)` passes the `cast<>` **even under `+Asserts`** and yields `and(¬c, ¬X)` where the truth is `c ∨ ¬X` — a wrong predicate NO assertions build can see. Measured live in the `[false, %rail]` row above | **FIX INDEPENDENTLY OF THE P1.** Either test `isOne()` and fall through to a refusal, or spell the general identity `¬select(c,T,F) = select(c,¬T,¬F)`. This is the 3c6m.67 xor lesson one arm over: an unconditional arm that was sound only while the grammar admitted one shape. |
| R5aR2-4 | P3 | **A retirement trigger FIRED and nobody re-derived it.** `sweepDead`'s comment says *"`isCondRailPhiShape` is excluded TOO, ahead of its own increment … **It has no subject at E6 today (the rail-φ leaf is deliberately not admitted).**"* 5a admits it. The **guard is correct and unchanged** — a rail φ is still protected from eraser (2) and from `sweepDead` — but the stated fact is now false, and the trigger explicitly asked the first widening to re-derive it | **RE-DERIVE THE COMMENT.** L7/L8. No behaviour change; this is exactly the class §4i says costs a round when it is left. |
| R5aR2-5 | P3 | **(A1) is FALSE and (A2)-as-the-orchestrator-spelled-it is FALSE.** An all-constant 2-incoming `i1` φ is byte-identical on both binaries at the region entry (`a1_allconst_phi.ll`) **and** interior (`v_true_false`, `v_false_true`). ⚠ The brief's proposed reason (`E6-classicalbr` refuses it) is the right answer for the *entry* case only; the **interior** case is identical for a different reason — `isBooleanCondTree` admits `i1` constants, so `isConvertiblePhiCond` already recorded such a φ on the ORACLE and `convertPhis`' scope-less re-check still passes on the SUBJECT. All seven orchestrator probes: no verdict delta | **CLOSED as refuted**, with the corrected reason recorded so nobody re-derives the wrong one. (A2) as a *class* is true and is the P1; the orchestrator's construction failed only because its φ kept landing at a region entry. |
| R5aR2-6 | P3 | **(A3) answered: a LOOP-CARRIED rail φ declines on both binaries, and moves the string.** `a3_loopcarried.ll`: ORACLE `control flow under quantum control` → SUBJECT `loop-carried tainted value crosses iterations`. Verdict preserved, owner changed, because the region is claimed and flattened before the loop layer speaks. No crash on ASSERTS | **RECORDED.** Another instance of the string-move cost round 1 filed as F2 — a real Rule-12 hazard (a decline fixture in this class may change owner), not a defect. |
| R5aR2-7 | P3 | **A genuinely NEW and CORRECT accept the increment did not claim**: a rail φ at an INTERIOR position of an `and`-tree condition (`and i1 %railφ, %cmp`). ORACLE declines, SUBJECT accepts, and the circuit is right — `toffoli(h_prep, h_cmp) → g`, two X-bracketed controlled copies, full uncompute, `free_pairing_check` `5 verified, 0 violation(s)`, the prep rail read only as a control and never freed. M4 keeps it byte-identical | **RECORDED AS A CAPABILITY, NOT A DEFECT** — but it is an accept surface with **no fixture**, reached by recursion through the and/or arms rather than by the top-level arm the increment fixtured. Rule 12 wants one. |
| R5aR2-8 | P3 | **Erasers (3) and (4) — PROBED WITHOUT A SUBJECT, which is not a clearance.** Brief target (D). `foldConstantConeAndBranches` explicitly skips `PHINode`s in its constant fold, and `removeUnreachableBlocksChecked` only reaps unreachable blocks. Two probes that drive a rail φ's cone to a constant-false predicate (`p4_jlast`, and `p6_nomeasure` where the rail is NOT measured) leave the user's `cqrt_alloc_i1` + `cqrt_ry_i1` **present** (p6 even emits the `_unc`). No vanishing user gate found | **NO FINDING, STATED AS AN ABSENCE OF A PROBE.** I did not construct a module where the rail's defining block becomes unreachable; E4 keeps a `cq_theta` out of a claimed non-entry region, which is the structural reason I could not. |
| R5aR2-9 | P3 | **Round 1's three corroboration fixtures are NOT diverted by hunk 2 on the shipping subject** — the brief asked. `control_predmux_accept_w6_{direct,stranded_merge}_condphi.ll` and `control_predmux_leave_w6_selectchain_phi.ll` all produce **byte-identical IR on ORACLE and SUBJECT** and are clean on **+Asserts**: their φ incomings are compares, so `isStructuralRailPhi` never matches. Round 1's mutant (incoming-check removed) crashed them; the shipped incoming check is what keeps them out | **CLOSED as checked.** The incoming test is doing real work; it is the *placement* question that is missing (the P1). |
| R5aR2-10 | P3 | **THE TREE HAS NEVER HAD A `+Asserts` `cq-opt`, AND BUILDING ONE ABORTS ON FOUR COMMITTED *ACCEPT* FIXTURES.** Sweeping all 2154 with the Debug SUBJECT: `loop_carried_handle_accept_narrow_width.ll` → `All operands to PHI node must be the same type as the PHI node!` (`setIncomingValue`, the bd `11qv` / `RailBankPromote` `mutateType`), and `spec_accept_qrom_read_arm_{coherent_escape,provable_index,two_tables}.ll` → `Invalid operands for select` (`SelectInst::init`). **All four are PRE-EXISTING** — ORACLE and SUBJECT emit byte-identical IR for each, and three of them contain no `phi i1` at all — and all four exit 0 with a verify-clean module in Release, so the violations are transient. ⚠ **This is why nobody could build a `+Asserts` binary, and therefore why an unchecked `cast<>` in this pass has no gate at all**: round 1 recorded "it did not build a `+Asserts` `cq-opt`" as its own boundary; the reason is that doing so reds four accepts | **FILED, NOT 5a's** — but it is the structural reason the P1 class is invisible. A bead is owed: make the four fixtures assertion-clean, then a Debug `cq-opt` becomes usable as a gate and this whole family (round 1's `cast<BinaryOperator>`, my `cast<ConstantInt>`) gets caught by construction. ⚠ Sweep NULL CONTROL: my `p4_jlast.ll` was appended to the list and **is reported**, so the sweep is not silently passing everything. |

---

## What I attacked and did NOT break

* **Both halves of round 1's fix are correct and load-bearing** (brief target (F), verified
  in both directions by mutant — see the M2a/M2b table). Hunk 3's `¬railφ = xor railφ, true`
  is created at the entry terminator and the φ always dominates it (an unconverted φ is
  either the entry's own or defined above the region — an interior one is converted first by
  topological order), so there is no use-before-def. Hunk 4's fold is the exact identity
  `select(¬c,T,F) == select(c,F,T)` and stays fenced to a rail operand, so the
  round-1-P2-1 "module with no rail at all" flip is not re-opened.
* **The negated-polarity ACCEPT the fix creates is a correct circuit.** `acc_false` (the
  shipped accept fixture with its two labels swapped) emits the same stream as `acc_true`
  with **exactly the two controlled copies exchanged** — verified by diff, four lines, the
  `%selop` constants — which is what the source comment claims. No stray `xor`, no stray
  `select`, `free_pairing_check` identical on both polarities.
* **The W6 anti-overlap witness is unaffected.** `StrandedCondPhi` is
  `isSupportedCondTree(cond, Convertible) && !isSupportedCondTree(cond, Downstream)`. On the
  ORACLE a rail φ makes both calls FALSE; on the SUBJECT hunk 2 makes both TRUE; the
  conjunction is `false` either way, and under M3 it is `false && !true`. Three binaries,
  one answer. **No delta, by three different routes** — worth stating, because hunk 2 sits
  above the scope-sensitive arm the witness exists to exercise, and "it ignores the scope"
  looked like it should break it.
* **The owner's own program.** Independently re-run end to end on the SUBJECT: `opt` exit 0,
  **0 bytes of stderr**, stage 2b STRICT `3 verified, 0 violation(s), 0 unproven`, 88 trace
  lines, **byte-identical to the committed golden**. The rail `%h` is read only as a
  `cqrt_cnot` copy source and measured — never `cqrt_x`-bracketed, never freed (Rules 6/7);
  the ancillas `%bf`/`%bf2` are X-bracketed and freed at a proven `|0⟩`. It is also clean on
  the **+Asserts** binary (rc=0, 0 bytes), so no latent assertion sits under it.
* **Cross-function (bd `1yeu`, brief target (I)).** A two-function module carrying the P1
  shape in one function and the shipped accept shape in the other behaves exactly as the
  single-function modules do on all four binaries. The one-function-per-module corpus gap
  neither hides nor changes this defect.
* **`clang -O2` / `-O3` (brief target (G)).** `c1.c` keeps its `phi i1` at both levels; I
  found no shape that crashes or mis-accepts at `-O2`/`-O3` and not at `-O1`. The P1's own
  exhibit is an `-O1` program, so the Rule-9 caveat round 1's P1 carried does not apply to
  this one.
* **`isStructuralRailPhi` itself is tight where it matters.** It refuses `undef`/`poison`
  incomings (so a φ whose shape `convertPhis` would FREEZE cannot be admitted), refuses a
  `ConstantExpr`, and inherits `i1`-ness and 2-incoming-ness from `isCondRailPhiShape`, which
  it CALLS rather than re-derives (Rule 14). Its weakness is not the incoming test — it is
  that it asks nothing about **where the φ lives**, which is the P1.
* **The L1 window (brief target (C)) is closed for this predicate, and I say that with its
  reason.** All five `flattenPredMuxRegions` call sites run strictly before
  `detectControlRegions`, so PredMux is not inside the `repropagateControlMerges` round-2
  window at all. And `isStructuralRailPhi` asks a purely syntactic question about
  `cq_theta_i1` CALLs, which Rule 3 makes stable across every taint round — there is no
  premise here for round 2 to falsify. ⚠ **What IS an L1-shaped hazard, one level down, is
  the P1 itself**: E6 asks its question of the **pre-`convertPhis`** value and
  `buildNegation` consumes the **post-`convertPhis`** one. Same shape as L1, inside one
  stage. Every other φ E6 admits is protected from that by the `Recorded` handshake; the
  rail φ is the first that is not.

---

## §6 — the whole-corpus A/B, and the gate figures

⚠ **A CLEAN CORPUS A/B ON A WIDENING IS WEAK EVIDENCE BY CONSTRUCTION, AND THIS ONE IS THE
PROOF.** The corpus contains **no** module with an interior rail φ — that is exactly the
population 5a admitted — so the sweep below reads clean over the very shape that carries the
P1. I ran it anyway, because it is the only instrument that can see an A→D or a crash-flip in
the population that DOES exist, and because my own first fix spelling (M3) broke two cells
that no shipped gate would have caught either.

**Instrument validation, in both directions, before any row was believed:**

| control | result |
|---|---|
| NULL (SUBJECT vs SUBJECT, all 2154) | **0 movers** |
| POSITIVE (2 fixtures known to move) | **2 of 2 caught** |
| BUILD null (patch re-applied to fresh HEAD) | **bit-identical to SUBJECT** |

**ORACLE (`a9a227e4`) vs SUBJECT, all 2154 fixtures — an oracle that isolates 5a EXACTLY:**

```
A->D = 0 · crash-flips = 0 · IR/stream moves = 0 · D->A = 1 · decline-string moves = 1
control_predmux_accept_rail_phi_cond :: RC(1->0) STR :: A[control flow under quantum control] B[]
DONE 1 movers
```

**Exactly ONE mover, and it is the increment's own new accept fixture.** So on this oracle 5a
contributes **zero stream moves** — which settles the coordinator's `2 vs 3` discrepancy in
the direction round 1's F5 disposition already argued: whatever the third stream move is, it
is **not 5a's**, and the two counts were measured against different oracles and were never
comparable. I did not re-derive F5's own measurement.

**SUBJECT vs M4 (the corrected fix), all 2154 fixtures, on a QUIET box (load 6.9, 3 min 14 s
at `-P 6`):**

```
0 movers
```

The fix moves nothing the tree already tests — which is the good news and the bad news in one
figure, since the shape it fixes is not in the corpus either.

**Gate figures I did not produce myself.** The coordinator supplied a full `ctest` against a
binary I independently verified bit-identical to my SUBJECT: **479/479**, with
`e2e-slice-grover-oracle-uncompute` **PASSED** (11.96 s) and `e2e-loop-twin-matrix` **PASSED**
(1216.16 s), run at load 77–295. I quote it as theirs. ⚠ Their A/B's oracle is `4db66534`,
which predates increments 3, 4 and `cfmv`, so its `D->A = 8` is a four-increment mixture; mine
above isolates 5a.

**On the coordinator's `stream-moves = 2 vs 3` discrepancy (round 1's F5):** see the IR rows
above. If the isolating sweep names neither `control_predmux_accept_selectchain_loopphi_residue.ll`
nor a third file, then F5's third stream move is **not attributable to 5a on this oracle**,
which is the direction F5's own disposition already argued — but the count it corrected was
measured against a different oracle, so the two numbers were never comparable and neither is
wrong. I did not re-derive F5's measurement.

---

## ⚠ MY OWN BOUNDARY — what I did NOT do

* **No simulation, no statevector** (Rule 2). Every correctness claim above is analytic or
  trace-level: I read the emitted gate stream and the source's basis-state semantics and
  compared them.
* **I did not run a full `ctest`.** The coordinator supplied one against a binary I verified
  bit-identical to my SUBJECT (479/479, `e2e-slice-grover-oracle-uncompute` PASSED) and I
  have quoted it as theirs, not mine. I ran the owner's slice myself, by hand, end to end.
* **I did not run `lit` over the fixture corpus**, `e2e-loop-twin-matrix`, the quarantine
  selftest, `free_pairing_check_test.py` or `cq-opt-equivalence-full` on any binary,
  including M4. ⚠ **My A/B compares exit code, the decline string and the emitted IR — it
  does NOT evaluate any fixture's `RUN`/`CHECK` directives.** "M4: 0 movers of 2154" therefore
  means "no module's verdict, message or emitted module changed", not "lit is green". **M4 is a proposal validated on 17 probes, 3 C programs, the 3 increment
  fixtures and a whole-corpus A/B that reads 0 movers (§6) — it is NOT suite-cleared, and narrowing an accept predicate owes its own Rule-13 round
  (L3).**
* **I did not write a single fixture.** Rule 12 red-green for the P1 (an interior-φ decline
  fixture whose `DBG:` line pins `gate=E6-condtree`, so it cannot pass on the defective
  binary for someone else's reason) is owed by whoever fixes it.
* **I did not audit the `[false, %rail]` and `[%rail1, %rail2]` wrong predicates for a
  silent route of their own.** I measured that both are caught downstream today; I did not
  prove they always are. `R5aR2-3` is filed because of that, not in spite of it.
* **I did not construct a module reaching erasers (3)/(4) with a rail φ** (see `R5aR2-8`) —
  an absence of a probe, not a proof.
* **I did not re-examine increments 3, 4 or bd `cfmv` on their merits.** My oracle contains
  them, which is what made the 5a delta clean, and that is all I used them for.
* **I did not adjudicate 5b** (the classical-prep rail φ) — the coordinator measured it
  identical on both binaries and it is their track.
* **I did not settle the `stream-moves = 2 vs 3` discrepancy the coordinator raised** beyond
  what my own isolating A/B says in §6; if §6 is still incomplete there, the discrepancy is
  still open.
* **Timings and load.** The box ran at load **38–165** throughout; nothing here is
  comparable to a quiet-box figure. No row above is a timing. Contention starves, it does
  not corrupt — but I re-ran every implausible row serially before recording it, and the one
  place I nearly recorded a false row was my own `rc=$?` after a pipe, caught by the same
  discipline the brief warned about.
* **Everything I built is on disk, so this is reproducible.** Probes and C exhibits:
  `$S/r2/exhibit/` (`c13.c` — the volatile-free P1 exhibit; `c12.c`; `p4_jlast.ll`;
  `p9_twofunc.ll`; `a3_loopcarried.ll`; `p7_and_tree.ll`), the full probe set in
  `$S/r2/probes/`, the harnesses in `$S/r2/{ab.sh,ab1.sh,asserts_sweep.sh}`, the mutant
  sources reachable by re-applying the one-line edits recorded in §1 and the finding table,
  and the five binaries at the hashes in the header table.
* **My own instrument, and how I know it works.** The A/B harness was run against a **null**
  (SUBJECT vs SUBJECT → 0) *and* a **positive control** (two known movers → 2 of 2) before
  any of its output was used. The +Asserts sweep carries an appended module known to abort.
  I have not tried to fool them beyond that.
