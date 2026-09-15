# ARM group gate — the six Rule-13 items, what changed, and what was measured

Session 2026-09-15, branch `arm-group-gate`, worktree `/Users/sorenwilkening/Desktop/CQ_ARM`.
Group = Track **F′** (`f2-phidesc-precision` `3637fdd2`, bd `hrts`/`l3i1`/`dpau`) + Track **P′**
(`prep-leaf-grammar` `28b9eb01`, bd `hn29`/`leyd`/`52og`). P′ was branched from F′ deliberately, so
**there was no union to perform** — the group's merge was already done by construction, and
`git merge-base` confirms both branches share `main` `74eabd2c`.

Subject of part 1: `review_r13_armclassify/REVIEW.md`, verdict **`CLEAR-WITH-ITEMS`**, six items.
That verdict makes these **fixes**, not a re-litigation. Every measurement below is keyed to a binary
hash in `GATE.md`.

---

## R-1 — the P1 POPULATION item. **Corrected + FILED; no fence added, deliberately.**

**Disposition: (a) fixture header corrected, (b) customer filed on bd `s82e`, cross-filed nowhere
else. NO DECLINE WAS ADDED.**

The brief and the review agree on the direction and it is stated first: for
`review_r13_armclassify/probes/m1_malign_leak_then_rotate_measure.ll` the F′ landing is an
**OVER-ACCEPT, P1 direction**. A module `main` refused loudly at F2 now compiles, and the circuit it
compiles to leaves an entangled which-path TEMPLATE rail alive while a non-diagonal `cqrt_ry_i32`
runs on the register it copies and that register is measured — Rule 8 dephasing, and the exact
reading CLAUDE.md §5's Q-R1-1 correction installed.

**What this gate measured for itself, rather than inheriting** (ORACLE `0e280fc6…`, hashes verified
against `PROTOCOL.md` before use):

| probe | ORACLE verdict, re-measured here |
|---|---|
| `m1_malign_leak_then_rotate_measure.ll` | **exit 1** — `cq controlled lowering: state prep seed is proven equal to the condition register under quantum control` |
| `m1c_control_offdesc.ll` (ONE operand changed: `%mz = zext i32 %q`) | **exit 1** — same string |
| `m2_nodeadphi_reference.ll` (the dead φ DELETED) | **exit 0**, 49-line module |

`m2`'s emitted stream on the ORACLE, read off the lowered IR rather than quoted:

```
%h      = cqrt_alloc_i32(0);  cqrt_ry_i32(%h, 0.5)
%h_cmp  = cq_template_icmp_eq_i32_hl(%h, 7)
%h1     = cqrt_alloc_i32(0);  cqrt_ry_i32_controlled(%h_cmp, %h1, 0.5)
          cq_template_icmp_eq_i32_hl_unc(...); cqrt_free(%h_cmp)
%h_cast = zext_i32_to_i64(%h); addc_i64(%h_cast, -7)
%h_cast2= zext_i32_to_i64(%h1); %h_op = mul_i64(%h_cast, %h_cast2)
%h_cast3= cq_template_trunc_i64_to_i32(%h_op)        <-- NEVER _unc'd, NEVER freed
          ... h_op / h_cast2 / h_cast uncomputed and freed ...
          cqrt_ry_i32(%h1, 0.9)
%m      = cqrt_measure_i32(%h1)
```

**So the hazardous circuit already ships from `main`.** The class is PRE-EXISTING; F′ widens its
POPULATION by one spelling. CLAUDE.md's own formulation, quoted in the filing:
*"'pre-existing' is true of the defect and FALSE of its population."*

⚠ **A fact this gate found that the review did not record**: on `m2` the ORACLE prints, at exit 0,

```
warning: <unknown>:0:0: in function example i32 (i32):
         cq rotation lowering: non-diagonal gate over a live derived record
```

**The hazard already has a WARNING and no DECLINE.** That warning site is the obvious hook for
bd `s82e`'s fence, and it is evidence the analysis needed to detect the class already exists in
`RotationLowering` rather than needing to be built. It is recorded in the bd note, not acted on here.

### (a) the fixture header

`ir-pass/test/control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll` said the leak was
*"the bd `s82e` family and is **ORTHOGONAL to this landing**: it is the ordinary disposition of a dead
tainted chain."* The first clause is right; the second is **the same sentence CLAUDE.md §5 has already
called false once, in the same words, about three other fixtures**. It now:

* says **"a customer this landing adds to bd `s82e`"**, with the Rule-8 quotation that settles it;
* states the **BENIGN / MALIGN split** and puts this fixture in the benign half *with the reason*
  (its `%MB` is measured directly; no non-diagonal gate runs on it after the leak);
* names `m1` / `m1c` / `m2` with their measured verdicts, and says in those words that for `m1` the
  landing is an **over-accept in the P1 direction**;
* records the warning-site hook and, per Rule 14, **explicitly refuses to add a second spelling of
  another track's fence here**;
* carries the **red-green pair to write WITH the `s82e` fence** (RED `m1`; GREEN an `m2`-shaped module
  with the trailing `cq_theta`/`cq_measure` removed; isolating control `m1c`) — so the pair cannot
  later go green because its subject vanished (fixture-hygiene defect (c)).

### (b) the filing

`bd update test_C_libtooling-s82e --append-notes` (applied; see `GATE.md`). The note carries a
**population correction** the bead needed and did not have: bd `s82e`'s own text and root cause are
IN-LOOP (`markIfRailLocal`'s accumulating-invariant clause), and `m1` **has no loop anywhere** and
does not go through `markIfRailLocal` at all. The class is loop-independent as well as
region-independent. The note also carries the three witnesses, the warning-site hook, the reason
stage 2b saw nothing (`0 violation(s)` on `m1`, structurally blind to a template-minted rail), and the
red-green pair.

⚠ **Why no decline here**, stated because the temptation is real and the Prime Directive appears to
license it: the class is bd `s82e`'s, `m2` proves the fence is not this track's to build, and a
second spelling of a predicate another track owns is the drbq Inc-3 (b′) defect (Rule 14). Adding one
here would also decline programs on a claim this group has not measured.

---

## R-2 — the composed ACCEPT surface is NOT empty. **Recorded, in two places, and filed.**

`COMPOSITION.md` §4's *"no composed ACCEPT was found"* was true when written and is falsified by
construction. Landed as an **ERRATUM appended to `COMPOSITION.md` §4** (the sentence is kept, not
edited away — *how* it was wrong is the part worth keeping) plus a paragraph in `CLAUDE.md` §4c, plus
`bd update test_C_libtooling-oej0 --append-notes`.

The mechanism is the part that generalises and it is one line of the pipeline: **every F2 decline is
FATAL to the module** (`DS_Error` → `LLVMContext::diagnose` EXITS, bd `br4a`), so a region F2 refuses
never sits in a plan beside anything. F′ cannot add a leaf to a plan that already existed — it can
only turn a **dead module into a live one** — and therefore **every F′ × P′ composition is
MODULE-level**, not shape-level. Both tracks searched the shape-level surface, which is the confined
one (the pre-existing exit-134 crash, bd `y65i`).

`c1` (two independent preps in one function) and `c2` (the same rolled in a loop — the three-way
F′ × P′ × `wx8g` composition bd `oej0` says nobody built) each decline on ORACLE, on F′-alone **and**
on P′-alone, and accept only on the composed binary. Both are twin-identical (27 = 27, 29 = 29 trace
lines) and `c2` is K-independent at 99 lines for K = 3 and K = 1000, STRICT 2b clean. ⚠ **That is
exactly the evidence Rule 2 calls necessary and not sufficient** — F′'s rounds saw a binary on which
these decline, and so did P′'s. The bd note asks `oej0` to require enumeration of the **module-level**
surface whenever two tracks' widenings share a fatal decline site, and records why the corpus sweep
cannot see it (no shipped fixture contains two tracks' dependent shapes at once — which is why the
four-binary sweep over all 2047 fixtures reports **0** COMPOSED movers while two hand constructions
exist).

⚠ **This gate did NOT re-derive `c1`/`c2`.** It records them and states their clearance status:
**cleared by measurement, by no review.** That obligation is now in CLAUDE.md §5's "Owed as a REVIEW"
line, which this gate rewrote to name it.

---

## R-3 — the source-mutation gate F′ never shipped. **RUN. See `GATE.md` for every line.**

Harness: `probes/source_mutation.sh`, four mutants over `availableAtAnF2Slot`'s two clauses plus a
RESTORE-and-hash step. Results in `probes/source_mutation.out` and summarised in the report.

---

## R-4 — L3-MIRROR disclosure. **The direction is now in the SOURCE, at both ends.**

Two edits, because a record correction that is not applied to the source is not a correction
(L7-with-a-twist, the lesson measured three times on one sentence):

* **`ir-pass/include/ControlPlan.h`, the `PrepRegionIdxs` block** — names `RailCondReads` **case (3)**,
  states that this field's `PhaseKickback` direction is a **GRANTING** use that **ENLARGES case (3)'s
  population** (from the φs the bd `hcrg` alias supplied for free to every cross-block φ leaf under an
  explicit edge), states that the M-β premise is **preserved by construction** and why (same plan,
  same `lowerControlRegions` call, order-within not whether-at-all; M-β still RAUWs; the
  `WeakTrackingVH` follows; the reader still runs after the round-2 fixpoint), and restates the
  callee's retirement trigger in this field's own terms.
* **`ir-pass/include/TaintPropagation.h`, at case (3)'s retirement trigger** — a **caller ledger**:
  each caller, and the direction it uses case (3) in. Two entries today (bd `3qps`/`4aiu` GRANTING;
  bd `hn29`/`leyd`/`52og` GRANTING **and population-enlarging**), plus the two shapes that would make
  the next caller different (a recorded φ whose prep is not in the same plan; a `SelectRegion`-kind
  prep, whose emitter performs no M-β).

⚠ This is a **disclosure**, not a defect: the reviewer checked the premise and so did this gate's
reading of the source. It is filed because CLAUDE.md records this precise omission as having cost a P1
on 2026-09-14 (bd `a3z7`).

---

## R-5 — the L1 round-2 item nobody's record carried. **Written into the source.**

`ir-pass/src/ArmClassify.cpp`, `chainedThetaBetweenDefAndBranch`'s header now carries the L1 item in
full: the predicate decides on **round-1 taint** (`Taint.Tainted.count(CI->getArgOperand(0))`, asked
inside `detectControlRegions`/`classifyPhaseKickback`, i.e. before `repropagateControlMerges`
re-seeds); the record-and-re-ask machinery that exists for this family **does not cover this prong**
(`reverifyRailCondReads` re-asks rungs (ii)/(iii) only, and `railCondWireDisposition` has no
positional prong); and the residual is argued **probably empty** — the same-wire half by rung (iii)'s
re-ask at FINAL taint, the other-wire half by R-6's availability argument — with the words
**"say 'probably empty', never 'closed'"** and the note that **nobody built the input**. Retirement
trigger names `reverifyRailCondReads` by name, in both directions (the day it gains a positional rung;
and the day a caller passes a FINAL `TaintSet`, delete the paragraph rather than leave a stale warning
in front of a closed hole).

---

## R-6 — V12's ground HOLDS, on the stronger reason. **Restated at the site, with the measurement.**

V12's argument was in `IMPL_P.md` and **in no source comment at all** — checked by reading the P′ diff
(`git diff 3637fdd2 28b9eb01 -- ir-pass/src/ArmClassify.cpp | grep '^+.*\(xor\|G6\|dtzb\)'` returns one
line, and it is a different argument). So it was **added**, on the ground the review derived rather
than the one-twin ground:

> **The only names of the condition rail that are AVAILABLE in the gap are the φ itself and values
> derived from it.** The arm theta's result is not — spelling the `xor` on it there is **invalid SSA**.

**Re-measured by this gate on the ORACLE, not inherited**: `r1_crossblock_xor_on_theta_name.ll` and its
in-`Pred` twin `r2_inpred_xor_on_theta_name.ll` are both rejected by the verifier —
*"Instruction does not dominate all uses!"* — so the shape is not expressible. And a state prep's
straight-through incoming is the SEED, which F1 requires untainted, so it is classical and its `xor` is
not a rail op. The φ is then always read later (by the branch, or by a tree node in `Pred`), so M-C's
G6 refuses the in-place conversion on it, and G6 bails unconditionally inside a loop besides.

The retirement trigger is the one `railCondWireDisposition`'s header already carries, now with its
**fourth pin** (`d5_bare_xor_in_gap.ll` / `c5_bare_xor_in_pred.ll`) — plus a **second trigger of its
own**: the availability half is an argument about what can be SPELLED in the gap, so the day this
helper gains a caller whose `Def` is not a region merge φ, re-derive it.

---

## Also landed: Track F′'s `CLAUDE_MD_EDITS.md`

All five, **verified against the landed source first** (Rule 11) rather than applied on trust. Three
deviations from the proposal, each because the measurement said so:

1. **EDIT 2 is SUBSUMED by EDIT 1, not separately applied.** Its FIND string (*"the narrowing has two
   further open filings of its own…"*) is the tail of the *"THAT RETIREMENT TRIGGER HAS ALREADY
   FIRED"* paragraph, which EDIT 1 deletes. Applying EDIT 2 afterwards would have failed to match;
   its content (*"cyclicity was never the axis"*) is carried inside EDIT 1's replacement.
2. **EDIT 1's count is qualified.** The proposal says *"exactly ONE shipped fixture flips"*. Measured
   from the diff: the ACCEPT fixture `…_acyclic_nondominated_phi_accept.ll` is a **NEW file** (179
   added lines, none removed), so it did not exist to flip; the independent round's four-binary sweep
   over all 2047 shipped fixtures reports **2** F′-only rows and the second is that new file. The
   landed text now reads *"exactly ONE **PRE-EXISTING** shipped fixture flips"* and carries the
   denominator.
3. **An intro paragraph the proposal did not mention was rewritten too.** The five lines immediately
   above the block said *"Read it with the paragraph that follows it: its closing retirement trigger
   says 'the day `wx8g` lands'…"* — a pointer to text EDIT 1 deletes. Left alone it would have become
   a dangling reference, which is the L7-with-a-twist failure mode one level up.

**Two edits of the group gate's own, beyond the five proposed**, because P′'s closures would otherwise
have been left stale in the same list F′'s were corrected in:

4. **§5 records bd `hn29` / `leyd` / `52og` as CLOSED**, with the scoping argument (the new prong is
   reached only for a claimed prep merge φ; every compare condition, value arm, in-place Ry arm and
   state prep keeps the unconditional decline, INCLUDING the LICM-hoisted loop-invariant compare §2
   names) and the measured `52og` witness (rolled-vs-unrolled byte-identical, 44 lowered lines at
   K = 3 and at K = 1000). **bd `52og` is removed from the over-decline list**, where it no longer
   belongs.
5. **The `Where Things Live` control-chain row names `chainedThetaBetweenDefAndBranch` as the ONE
   spelling** of its question (two callers, both CALLING it — Rule 14), **and carries the R-5 L1
   caveat**, so the operating manual does not present it as a settled prong.

`CLAUDE.md` after the edits: **144 362 characters** (`wc -c`), still inside the < 150 k budget.
