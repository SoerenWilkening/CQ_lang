# Track D2 — bd `test_C_libtooling-drbq.12` — IMPLEMENTATION + Rule-13 SELF-ADVERSARIAL ROUNDS

Branch `drbq12-hoisted-compare-p4`. ORACLE `cq-opt 9bd01598d574b344…`. SUBJECT
`cq-opt 5ee9d14420c3533a…`, `libCQPass.so 3bcc2cd76f24df65…`. Every number below was
run on those two binaries; the commands are in `GATES.md`, hash-keyed.

---

## 1. What shipped, in one paragraph

`condWireDisposition`'s P4 prong (`Cond->getParent() != R.Pred → DeclineNow`) no
longer refuses a COMPARE outright. It calls `crossBlockCompareMintable`, which admits
a cross-block compare when (1) it is a real `CmpInst`, (2) it dominates the mint
point, (3) the gap between its definition and the mint carries no rail-relabelling
gate **on the condition's own rail**, and — at the CALLER — (4) the region is not
`ShareCondFlag`. The same predicate is called from `classifyPhaseKickback`'s step-5a
compare-LEAF residency check. The gap walk is Track P′'s CFG-bounded walk, EXTRACTED
into `anyInstructionInGap` and shared: ONE walk, two evidence functions.

**The whole increment is ACCEPT-only.** Over 4554 modules (2090 shipped fixtures +
2464 historical session probes) the subject moves **14** and every single one is
`D→A`: **0 `A→D`, 0 `A→A` md5 changes** — not one accepting module's emitted stream
moved by a byte.

---

## 2. File surface as BUILT (`FILE_SURFACE.md` §1 was the prediction; this is the fact)

`ir-pass/src/ArmClassify.cpp` ONLY. No header change, no `WireWalk.*`, no
`RegionTreeDetect.cpp`, no `SelectClassify.cpp`, no `AngleSelectEmit.cpp`.

| # | what | where (HEAD-relative) |
|---|---|---|
| D2-1 | `anyInstructionInGap` — Track P′'s CFG-bounded gap walk, EXTRACTED line-for-line and templated on the evidence predicate | new, at `chainedThetaBetweenDefAndBranch`'s old site |
| D2-2 | `isChainedThetaCall` + `chainedThetaBetweenDefAndBranch` re-expressed as ONE call to it — behaviour-identical for every pre-existing caller | same block |
| D2-3 | `condRailMembers` / `railRelabellingGateOn` / `crossBlockCompareMintable` — new, file-local | same block |
| D2-4 | `condWireDisposition`: the P4 prong, plus `!CrossBlockCompare` on the P5 wire-blind scan | `condWireDisposition` |
| D2-5 | `classifyPhaseKickback` step 5a: the leaf residency check calls the same predicate | step 5a |
| D2-6 | `classifyPhaseKickback` step 6: `scanForward` DELETED, replaced by `chainedThetaBetweenDefAndBranch` under a `getParent() == Pred` guard | step 6 |

**D2-6 is not my idea** — it is the L8 retirement trigger Track P′ wrote into that
block: *"the day step 5a's cross-block compare-leaf decline is widened, delete
`scanForward` and give BOTH loops this helper — a single window must not survive as
the weaker of two spellings of one question (L2)."* The stale paragraph that carried
that trigger is rewritten in place, not left standing (L7-with-a-twist).

**What Track X must know:** I do not read or write `condProvenance`'s body and I do
not touch the §3c clobber prong. I *call* `condProvenance` unchanged. If Track X
narrows or widens it, my `condRailMembers` seed set moves with it in the
decline-safe direction in BOTH cases — narrowing shrinks the set (fewer members,
fewer… no: fewer members means fewer gates count, which is the ACCEPT direction, so
a narrowing of `condProvenance` is an over-ACCEPT risk for me exactly as it is for
R4, and CLAUDE.md already calls narrowing it a Rule-13 change to R4). Stated
precisely rather than comfortably: **`condProvenance` is now load-bearing for a
FOURTH consumer**, and narrowing it is a Rule-13 change to this prong too.

---

## 3. The re-derivation the callee DEMANDED of this caller, and its outcome

`chainedThetaBetweenDefAndBranch`'s header carries the trigger *"the day this helper
gains a caller whose `Def` is NOT a region merge φ — a plain compare leaf, say … re-
derive it."* Both halves of P′'s availability ground fail for a compare (a compare's
tainted operand is an ordinary dominating register, so an in-place op IS spellable in
the gap; and the compare reads it BEFORE the gap, so P′'s "the φ is always read
later ⇒ G6 refuses" does not transfer).

**The first answer written was a FENCE on the `add`/`sub`/`xor`, and it was built,
measured, and REMOVED.** On `probes/dtzb_flat_red.ll` it declined a program whose add
demonstrably lowers OUT of place (`%h_op = cq_template_add_i32_hl(i32 %h, i32 1)` — a
fresh rail, `%h` untouched). Pure over-decline. The shipped answer is the ORDER
INTERLOCK, measured not assumed: control emission runs BEFORE `lowerOps`, so when
M-C decides, the mint/strip/controlled gate already read the condition's handle and
already sit after anything in the gap, and G6 refuses in-place for a parent with a
use it cannot prove earlier. The companion measurement
(`probes/dtzb_green2.ll` → `cqrt_addc_i32`) shows the SAME add DOES convert in place
when nothing of the region follows it, so the discriminator is position relative to
the emitted stream, not the opcode. Both are shipped as fixtures
(`control_inplace_ry_crossblock_cond_{outofplace_add_in_gap,inplace_add_after_loop}.ll`).

⚠ **The asymmetry that survives, stated because it looks like an inconsistency:** the
`add` is refused as EVIDENCE and kept as a MEMBERS hop. Different questions — "does
this instruction relabel?" vs "may this name denote the rail?" — whose conservative
answers point in different directions. Its measured cost is exactly one file (§5 R-3).

---

## 4. Why the wire-aware scan, measured before it was written

The naive reading — "P5 is already a real CFG walk since Track P′, so just drop P4"
— **moves ZERO of the sixteen row-W cells.** P5 is WIRE-BLIND, and a hoisted
loop-invariant compare's gap contains the loop body, hence the arm's own `cq_theta`
on a DISJOINT rail. Measured: with P4 dropped and P5 left wire-blind, the customer
`probes/d2a1_customer_simplest.c` traded a P4 decline for a P5 decline at the same
string. That is why the gap question is asked wire-scoped here, which is PRD §13.10
Q1's remedy in its own words.

---

## 5. Rule-13 SELF-ADVERSARIAL ROUNDS (the independent round comes at the Group-2 gate)

### Round 1 — attack the accept

**R-1 (the alias route).** `probes/r1a_alias.ll`: the compare reads `%1`, a
PRE-compare `%chain = cq_theta(%1, .2)` makes `%chain` one rail with `%1`, and the
in-gap latch gate takes `%chain`. DECLINES on both binaries. ⚠ Under the
gap-scan-deleted mutant it STILL declines — the wire walk catches it — so this probe
does **not** pin the scan. Recorded rather than presented as a win.

**R-2 (the stale-record direction; per-trip vs once).** The flag is minted at
`Pred->getTerminator()`, i.e. PER TRIP, while the hoisted compare is evaluated once.
That is the right circuit, and the reason is the hoist's own precondition: LICM
hoists only a loop-invariant compare. Where the RAIL moves under an invariant NAME,
the wire walk's position-aware prong declines (a body gate reaches the mint around
the back edge, so `provablyBefore(BI, G)`'s second conjunct fails). Pinned as a PAIR
one instruction apart:
`control_inplace_ry_reject_crossblock_cond_wire_gate_in_gap.ll` (DECLINE) and
`control_inplace_ry_crossblock_cond_wire_gate_after_loop.ll` (ACCEPT), which differ
only in whether `%post` sits in the latch or in the exit block. ⚠ On the ORACLE both
decline for the same P4 reason; only on the subject do they split. Without the
control the negative would pin nothing, and its header says so.

**R-3 (the gate BEHIND an in-place-candidate add) — THE ONE THAT PINS THE SCAN.**
`probes/r1c_flat_behind_add.ll`: acyclic, two sequential regions, `%d = add %1, 3`,
`%post = cq_theta(%d, .1)` in the shared merge block. `WireWalk`'s forward walk does
not cross the add so it is invisible there; `%post` runs at most once so bd `3d8q`
has no subject. MEASURED on three binaries — ORACLE DECLINE, SUBJECT DECLINE,
**SUBJECT-with-the-gap-scan-deleted ACCEPT**. Shipped as
`control_inplace_ry_reject_crossblock_cond_theta_behind_add.ll`. ⚠ And the decline is
CONSERVATIVE: under the mutant the add emits out of place, so the accept would have
been sound. A genuine over-decline of the R4 species, filed in §bd, not hidden.

**R-4 (nested loop).** A compare hoisted out of a NESTED loop never reaches this
prong: the loop layer declines nested loops before detection. No new surface.

**R-5 (composition with the FROZEN register).** The historical-probe sweep produced
`session-b6ap/review_b6ap_r1_probes/u04_newbranch.s1.ll` unprompted — a CSE'd pair
whose SECOND region is a controlled STATE PREP. Inspected: `alloc_i32(0)+ry` ×2, then
per region a mint / `ry_i32_controlled` / strip / free, with region 2's rail minted by
its own `cqrt_alloc_i32(1)`. `%h` is read only as arg-0 of the two mints and two
strips. Clean, and it is the state-prep arm class reaching the widened prong for the
first time.

**R-6 (`binv`, the bare-`_Bool` + compare tree).** MEASURED and **NOT moved** — and
the reason is not the prong this bead widened. `-O1` hoists the WHOLE tree, node
included, and the NODE prong carries a second, non-positional reason (`ClaimedSelects`
is a per-block hand-off). Pinned as a DECLINE with its retirement trigger:
`control_phase_kickback_reject_inloop_hoisted_tree_node.ll`. Its ACCEPTING sibling —
same tree shape, loop-VARIANT second leaf so only the LEAF is hoisted — is
`control_phase_kickback_inloop_hoisted_tree_leaf.ll`. One file per side of the line.

### Round 2 — attack the bookkeeping (L1 / L2 / L3)

**R-7 (L1 — round-1 taint).** Both halves of the new predicate decide on ROUND-1
taint. A `cq_theta` tainted only in round 2 reads as a SOURCE theta to
`railRelabellingGateOn` and as CHAINED to `lowerRotations`. **This is the SAME
residual `chainedThetaBetweenDefAndBranch`'s header already documents**, and this
caller widens its POPULATION without changing its species. What IS re-asked, read in
source: `markCmpCondRead` is called from `lowerCompareImpl` at the MINT (not at the
source compare), with `WireRuled` on this path, so `reverifyCmpCondReads` re-asks
rungs (ii)/(iii) at FINAL taint in both entry points regardless of the compare's
block. Only the POSITIONAL question goes un-re-asked. Written into the source with
the shared retirement trigger (`reverifyCmpCondReads` / `reverifyRailCondReads`
gaining a positional rung). **Not constructed** — say "probably empty", never
"closed".

**R-8 (L2 — what OTHER set was computed over the same closure?).** Four candidates
checked: (a) step 6's `scanForward` — the L8 trigger, discharged in D2-6; (b)
`markCmpCondRead`'s `Seeds`/`OperandSeeds` — position-independent, see R-7; (c)
`condCmpMeasuredBeforeReadPoint` — anchored at `Pred->getTerminator()`, independent
of the compare's block; (d) `RegionTreeDetect::staleCond` — untouched, the nest path
never reaches this predicate.

**R-9 (L3 — what other predicate names the same gate?).** `chainedThetaBetweenDefAndBranch`
has three call sites after this change: `condWireDisposition` (now guarded by
`!CrossBlockCompare` — the cross-block compare has already had the SAME gap walked,
wire-scoped, so asking the wire-blind question again would re-decline what step (3)
proved), step 6's compare-leaf loop (guarded on `getParent() == Pred`), and step 6's
φ-leaf loop (UNGUARDED, correct — a φ has no wire-scoped admission of its own and
needs the walk). The in-`Pred` window is untouched at every site.

**R-10 — THE FINDING ABOUT THE INSTRUMENT ITSELF.** The first injection-matrix run
over the nine accept fixtures reported **MISSED 21** of 108 mutations: a stray
`cqrt_ry` before the `ret`, a duplicated mint, a duplicated free and a `cqrt_x`
injected onto the USER REGISTER all slipped through, because no whole-file prefix
counted those symbols. Closed by an exact count per symbol, ONE PREFIX PER SYMBOL,
each `COUNT-n` followed by its own `-NOT`. Re-run: **108 mutations, 88 caught, MISSED
0, n/a-HOLE 20** (every hole is a gate the module legitimately does not contain).
⚠ Both numbers are recorded; the 21 is the interesting one.

**R-11 — a fixture-hygiene defect found while writing, worth carrying.** Consecutive
`COUNT` directives under a SHARED prefix scan FORWARD from where the previous one
stopped, so four interleaved symbols cannot be counted in one prefix — and at
`COUNT-1` the later ones silently match the trailing `declare` lines instead. Caught
here by a red; it would have shipped as a green. Also: a bare `-NOT: cqrt_x` matches
`declare void @cqrt_x(i32)`, which `cq-lowering` leaves in every module. Every
negative in this batch names the CALL.

---

## 6. What moved, by string, on the ORACLE-vs-SUBJECT sweep

`ir-pass/test/*.ll` — 2090 rows, 2081 unchanged, **9 movers, all D→A**:

| module | oracle string | note |
|---|---|---|
| `control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll` | `condition predates a non-diagonal gate` | PRE-EXISTING. PRD §13.2 row W's own pin; its header named this bead |
| `control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll` | `condition predates …` | PRE-EXISTING. The Rz stem; its header said "moving it is its own increment with its own adversarial round" |
| `control_phase_kickback_reject_tree_cross_block_leaf.ll` | `control flow` | PRE-EXISTING. Its header: *"IT IS AN OVER-DECLINE AND A KNOWN ONE … belongs to a round with its own probe family"* |
| `control_swap_reject_seq_shared_cond.ll` | `condition predates …` | PRE-EXISTING. §7 below — its safety sentence was TRUE under the retired register `cq_phi` and is FALSE under the kickback |
| the other 5 | — | trackD2's own NEW fixtures; they did not exist to flip |

**Exactly 4 pre-existing shipped fixtures flip. ZERO of the four say CONFIRMED
MISCOMPILE in their headers; all four describe the decline as positional or
explicitly as an over-decline.**

Historical probe corpus (`inc1-records/**/probes/*.ll`) — 2464 rows, 2459 unchanged,
**5 movers, all D→A**, all on `condition predates …`: `u04_newbranch.s1.ll` (R-5
above) and four `trackW/fix_r2_probes/w2i{2,3}_h1_*.s1.ll`.

---

## 7. The one flip that needed a real argument, not just a measurement

`control_swap_reject_seq_shared_cond.ll` shipped with this safety sentence: *"a flag
minted at region 2's branch from a compare that dominates region 1 has no proven
relationship to the wire region 1 left behind."* **That was true when written and is
false now**, for a reason recorded in the file's own migration note: under the RETIRED
register surface a phase arm was `q = cq_phi(q, θ)`, so region 1 really did gate `q`.
Under the shipped register-free KICKBACK (Rule 7) a phase arm emits NOTHING on `q` —
mint, `cqrt_rz_i1` on the FLAG, strip, free — and leaves it exactly as it was. And the
accept is not granted on that argument alone: `crossBlockCompareMintable` walks
region 1's arm and merge and finds no relabelling gate on `%c1`'s rail. Had the arm
carried `q = cq_theta(q, …)`, the walk would have found it — that program is the
shipped negative.

---

## 8. Residuals and what is NOT built

1. **The NODE prong** (`Tree.Nodes` must live in `Pred`) — untouched. Widening it is
   an ORDERING change (`ClaimedSelects` is a per-block hand-off), not a position one.
   Pinned by `control_phase_kickback_reject_inloop_hoisted_tree_node.ll`; the
   twin-matrix cell `m_none_ablphi_none_none_binv` stays `UNROLLED-ONLY`.
2. **The other three of PRD §13.10 Q1's "four callers"** — `SelectClassify.cpp`'s
   gate 2c, `AngleSelectEmit.cpp`'s S6, `RegionTreeDetect.cpp`'s nest. ⚠ **Correction
   to `FILE_SURFACE.md` §5**: the 4.4 select's blanket cross-block decline was ALREADY
   LIFTED in 2026-07-03 (bd `9ymx`, owner decision) — found in
   `control_phase_kickback_reject_tree_cross_block_leaf.ll`'s own header, not by my
   scoping read. So the "four callers" line is history in at least one of its four.
3. **The R-3 over-decline** (a chained theta behind an in-place-candidate add on the
   condition's rail, in the gap). Needs M-C's answer at detection, which cannot be
   taken there.
4. **The L1 positional residual** (R-7), joined to the existing item rather than newly
   opened.
5. `condRailMembers` is a THIRD caller of `railWireClosure` and deliberately NOT the
   F2/R4 `CondRails`/`CondWire` spelling (`BothWays` vs `BackwardOnly`). Neither of
   those call sites is touched, so CLAUDE.md §4's divergence trigger does not fire;
   the reason for the different `WireDir` is written at the function and is that the
   three questions fail in OPPOSITE directions.

---

## §bd — exact text for the orchestrator to apply (bd writes only from the MAIN checkout)

```
bd update test_C_libtooling-drbq.12 --append-notes "2026-09-17 (Track D2, branch drbq12-hoisted-compare-p4): BUILT. condWireDisposition's P4 prong and classifyPhaseKickback's step-5a compare-LEAF residency check now call crossBlockCompareMintable: a cross-block CmpInst that dominates the mint is admitted when a CFG-bounded walk of the gap (anyInstructionInGap - Track P'-s walk EXTRACTED and shared, ONE walk two evidence functions) finds no chained cq_theta whose arg-0 is in the condition's railWireClosure(BothWays) member set; ShareCondFlag keeps the unconditional decline (its mint lands at Cond->getNextNode(), a different emission contract). Step 6's scanForward is DELETED per the L8 trigger P' wrote there. ACCEPT-ONLY, measured: over 4554 modules (2090 shipped fixtures + 2464 historical probes) 14 movers, ALL D->A, 0 A->D, 0 A->A md5 change. 4 pre-existing shipped fixtures flip, none saying CONFIRMED MISCOMPILE, each named this round in its own header. ir-pass-lit 2090/2090. injection matrix 108 mutations MISSED 0 (first run MISSED 21, closed). negative_vacuity 42 directives 0 VACUOUS. New e2e: e2e-slice-control-inplace-ry-inloop-hoisted-cond + its hand-unrolled twin + e2e-inloop-hoisted-cond-twin-identical (ROLLED == UNROLLED byte-for-byte). NOT moved and filed separately: the tree NODE prong (m_none_ablphi_none_none_binv stays UNROLLED-ONLY - it is an ORDERING question, ClaimedSelects is per-block, not a position one)."
```

```
bd create --title "Over-decline: a chained cq_theta BEHIND an in-place-candidate add on a cross-block condition's rail declines, though the add provably lowers OUT of place" --type task --priority 3 --labels control-in-place,over-decline --description "Found by Track D2's own Rule-13 round 1 (bd drbq.12, 2026-09-17), pinned by ir-pass/test/control_inplace_ry_reject_crossblock_cond_theta_behind_add.ll, which is ALSO the only fixture that individually pins crossBlockCompareMintable's gap scan (measured: the scan-deleted mutant ACCEPTS it; every other constructed probe is caught by the wire walk or by bd 3d8q). condRailMembers crosses the add/sub/xor hop because railWireClosure does - the R4 conservatism - so a theta on %d = add %q,3 counts as a gate on %q's rail. Measured under the mutant the add emits cq_template_add_i32_hl (OUT of place, fresh rail), so the accept would have been sound. Removing the over-decline needs M-C's classifyInPlaceReassignment answer at DETECTION time, which cannot be taken there: its verdict is at FINAL taint over a FINAL CFG, so a false at round 1 could become true later - a decline traded for an OVER-ACCEPT. Cost: exactly 1 module in the 4554-module sweep."
```

```
bd create --title "Filed capability: the phase-kickback tree NODE prong still refuses a cross-block select i1, so a fully hoisted _Bool-and-compare tree declines in a loop while its flat twin accepts" --type task --priority 3 --labels control-in-place,loop,over-decline --description "Twin-matrix cell m_none_ablphi_none_none_binv (bd uq96), the customer bd drbq.12's 2026-09-14 note named. drbq.12 widened the compare-LEAF residency check; -O1 hoists the WHOLE tree for this program (leaf %3 AND node %4 = select i1 %2, i1 %3, i1 false), so the NODE prong fires instead. That prong carries a second, NON-POSITIONAL reason in its own comment: the ClaimedSelects hand-off is what stops the caller's tainted-select scan from ALSO claiming a logical-select node as an i1 data mux, and that scan is PER-BLOCK, so a node in another block can be visited BEFORE the region claims it. Widening it is an ORDERING change with its own Rule-13 obligation, not a position one. Pinned as a DECLINE with its retirement trigger at ir-pass/test/control_phase_kickback_reject_inloop_hoisted_tree_node.ll; its accepting sibling (loop-VARIANT second leaf, so only the leaf is hoisted) is control_phase_kickback_inloop_hoisted_tree_leaf.ll."
```

```
bd remember "drbq12-crossblock-compare-mintable-2026-09-17" "bd drbq.12: P4's unconditional cross-block decline is replaced by crossBlockCompareMintable for a COMPARE. Three facts worth carrying. (1) Dropping P4 and leaving Track P'-s CFG gap scan WIRE-BLIND moves ZERO of PRD 13.2 row W's sixteen cells: a hoisted loop-invariant compare's gap contains the loop body, hence the ARM's OWN theta on a DISJOINT rail. The gap question has to be wire-scoped. (2) Fencing the dtzb in-place add/sub/xor as EVIDENCE is a MEASURED pure over-decline - probes/dtzb_flat_red.ll declines with the fence and, without it, ACCEPTS emitting cq_template_add_i32_hl (OUT of place). The real ground is ORDER: control emission runs BEFORE lowerOps, so by the time M-C decides, the mint/strip/controlled gate already read the handle and sit after anything in the gap, and G6 refuses in-place for a parent with a use it cannot prove earlier. The same add in the EXIT block DOES convert (cqrt_addc_i32) - probes/dtzb_green2.ll. Keep the add as a MEMBERS hop and refuse it as EVIDENCE: two questions, opposite conservative directions. (3) The scan is nearly redundant with the wire walk: of four constructed negatives, three still decline with the scan deleted (caught by wireGainsNonDiagonalGate or by bd 3d8q). The ONE that pins it is a chained theta BEHIND an in-place-candidate add, acyclic so 3d8q has no subject - WireWalk deliberately does not cross an in-place self-update, railWireClosure does."
```

```
bd remember "filecheck-count-prefix-scans-forward-2026-09-17" "Two fixture-hygiene facts measured while writing the bd drbq.12 batch, both of which would otherwise ship green. (1) Consecutive COUNT directives under a SHARED prefix scan FORWARD from where the previous one stopped, so N INTERLEAVED symbols cannot be counted under one prefix - and at COUNT-1 the later ones silently match the trailing `declare` lines instead of the calls. ONE PREFIX PER SYMBOL, each COUNT-n followed by its own -NOT (which is what turns 'at least n' into 'exactly n'). (2) A bare negative on a symbol name matches the DECLARATION: cq-lowering leaves `declare void @cqrt_x(i32)` in every module whether or not anything calls it, so `-NOT: cqrt_x` (or --implicit-check-not=cqrt_x) is a RED on a correct stream. Every negative must name the CALL. Same class as bd qta2. Also: lit scrapes RUN: out of PROSE, so quoting the directive token inside a comment mints a bogus run line and the fixture dies with a shell syntax error."
```
