# SCOPE — Track F: what R-2′ costs, fixture by fixture (bd `om35`)

> ## ⚠ ERRATUM — added by the orchestrator 2026-09-14, AFTER this document was written
>
> **Six probes cited below were VACUOUS and their rows are not evidence.** On this (case-insensitive)
> filesystem `sed X.s1.ll > X.S1.ll` truncates its **own source** to 0 bytes before `sed` reads it, and a
> **0-byte module ACCEPTS** (`cq-lowering` passes through any module with no `theta`/`phi`/`measure`,
> exit 0). So each scored a **false ACCEPT on nothing**. The six files are deleted;
> `probes/c/README_ERRATUM.md` / `probes/c/README-ERRATUM.md` stand in their place, and the trap is bd memory
> `empty-module-accepts-vacuity-trap`.
>
> **Re-measured with distinct names: two of the three affected claims STAND; ONE DOES NOT.** §3b's
> *"`w2` W → ACCEPT"* was **wrong support** for a conclusion that survives on a different probe — read §3b's
> conclusion as carried by that other probe, never by the `w2` W-test.
>
> **A second correction, also the author's own:** `w2.c` — cited here and in the implementation brief as the
> runtime-`a` customer — **is not the cascade shape at all**. Its first guard folds to
> `icmp sgt %argc, -2`, a **classical** branch, and the ORACLE declines it `control flow` at the identical
> site once its F2 collider is neutralised, so its wall is **pre-existing and unrelated**. The program this
> document meant is `w3_runtime_a.c` (runtime `a`, range-derived pin, region 1 still quantum-conditioned),
> which compiles on the subject.
>
> The implementation record (`IMPL_F.md` §7, in the Track F worktree) carries both in full. Nothing else in
> this document is retracted, and the headline counts — 32 fixtures naming F2's string, 29 declining, 25
> flipped by R-2′, 4 not, 0 row-level HOLEs, 2 predicate-level HOLEs — were re-verified after the erratum.


Written 2026-09-14 by the Track-F scoping agent. **READ-ONLY, measure-first**: nothing was built,
no suite was run, and no file outside `trackF/` was created or edited (`../PROTOCOL.md`, row
"scoping"). Every number carries its command. Line numbers are HEAD `607b6fe4` (docs-only over the
pass at `59ac5b7`) — **they are NOT the line numbers `bd om35` and `SCOPE_R2.md` carry**; see §4.

```
shasum -a 256 build/ir-pass/cq-opt        f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc   == BRIEF
shasum -a 256 build/ir-pass/libCQPass.so  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d   == BRIEF
```

---

## HEADLINE — five sentences, and the third one is the finding

**(1)** `grep -ln "state prep seed is proven equal" ir-pass/test/*.ll` = **32** files, of which
**29 DECLINE** with that string; **25 of the 29 flip under R-2′** and **4 do not**, because they
decline through F2's **`Truncated`** half, which is a separate disjunct at the call site
(`ArmClassify.cpp:4155-4157`) that R-2′ does not touch — so the bead's "≥11 fixtures" is **low by
more than a factor of two**, and one of the fixtures it names (`step_cap_over`) **does not flip at
all**. **(2)** Every one of the 25 is a **ONE-EDGE** pin, measured by TEST W (move the pinning
edge's fact, leave the other materially unchanged: 19/19 → ACCEPT) against two BOTH-EDGE positive
controls on which the same test correctly refuses to flip — so the corpus contains **ZERO both-edge
pins**, and R-2′ does not *narrow* F2's pin half so much as **empty it**. **(3)** All 25 rivals
decline, measured, 20 at R3 (`ArmClassify.cpp:4168-4170`, `control flow`) and 5 at F1
(`:3906-3915`, and the string is **`state prep merged with a quantum register`**, not the one the
bead predicts) — so there is **no row-level HOLE** — but the ground is not the one `om35` states,
and the price is a **direction inversion**: today a weakness in F2's model costs a DECLINE, after
R-2′ the same weakness costs an **ACCEPT**, because "pinned on both edges" is a conjunction.
**(4)** That inversion is not hypothetical: **HOLE-1**, demonstrated on a constructed module,
is an fp cell where F2's fp anchor *can only ever report one edge by construction*
(`ArmClassify.cpp:1596-1614`), R-2′ therefore flips it, and its in-place rival **ACCEPTS** —
`probes/fence/fp_bothedge_attempt.nomeasure.ll` declines F2 today while
`…BOTHSLOT_nomeasure.ll` **lowers at exit 0**. **(5)** And the measurement surfaced a **strictly
narrower predicate that closes all three customers — the owner's file, `vd.c` and `w2.c` — at a
cost of ZERO shipped fixtures** (§6): in all three the pinned value is a **descendant of the
region's own merge φ**, and in **0 of the 25** fixtures is it.

**§7 recommends: DO NOT BUILD R-2′ as spelled. BUILD-NARROWED, and the narrowing is §6, not a
carve-out of R-2′.**

---

## §0 THE INSTRUMENT, and the fact that it was attacked (L10)

R-2′ would add a conjunct at F2's **TEST** — `ArmClassify.cpp:1682-1683`, beside
`!CondWire.count(V)` and `!Taint.isPeelClone(V)` — and, because the test sits **inside** the
per-edge loop at `:1558` and returns on the first hit, R-2′ cannot be a conjunct at all in the
literal sense: it must become a per-edge RECORD plus an **intersection after the loop**. That
shape change is what makes "which edge pinned?" the whole question, and nothing in the pass prints
it. Four surgeries answer it without patching the pass:

| test | edit to the module | reading |
|---|---|---|
| **S** | the SEED → a wild value nothing folds to | F2 gone ⇒ the decline is the **PIN** half · F2 stays ⇒ it is the **`Truncated`** half, and R-2′ is **inert** on it |
| **A** | the SEED → the value the SAME collider takes on the OTHER edge | F2 present ⇒ the collider's two edge values **differ** ⇒ one-edge for any single seed |
| **B** | the collider neutralised | F2 gone ⇒ that value is **THE** collider (no second one hiding) |
| **W** | the **branch's** constant moved, so the PINNED edge's collider value is no longer the seed while the OTHER edge's fact stays materially the same (a co-singleton `full∖{K}` stays a co-singleton; a half-range stays a half-range) | `ConstantRange` is monotone, so any fold the other edge's fact supported before it still supports. **F2 gone ⇒ the other edge never folded to the seed ⇒ the pin is ONE-EDGE.** This is `DIAG_2026-09-14.md`'s S1 surgery, generalised |

**W was attacked before it was used.** `probes/bothedge/c1_and_zero.ll` (`%t = and %q, 0`, seed 0)
and `c2_always_false_i1.ll` (`icmp slt %q, INT_MIN`, seed `false` — SCOPE_R2's `x_C6` shape) are
BOTH-EDGE pins by construction; both decline F2 today, and **both keep declining under W**
(`c1_and_zero.W.ll`, `c2_always_false_i1.W.ll` → F2). So W is not a test that always says
"one edge": it says "one edge" exactly when the other edge does not fold. `c1_and_zero.S.ll` →
ACCEPT confirms C1 is a pin and not a truncation.

**A second property fell out of S/B/W for free, and it closes an implementation worry that would
otherwise be UNDECIDED-WITHOUT-BUILD.** R-2′ forces BOTH edges to be walked to completion (today
the first hit returns), so `Truncated` could newly fire on the second edge and the fixture would
*not* flip. But **every one of the 25 rows has at least one probe in which no pin fires anywhere
and the module ACCEPTS** (S for 22 of them, B for the other 3) — and an ACCEPT is only reachable
when **both** edge walks complete without `Truncated`. So the flip count 25 is not an upper bound
that a build might shrink; it is the count.

Commands, verbatim (`$B` = the frozen oracle):

```
CQ_CTRL_DBG=1 build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so \
    -passes=cq-lowering -S <probe>.ll -o /dev/null ; echo exit=$?
```
Generators: `probes/gen_pin.py` (S/A/B), `probes/gen_pin2.py` (W + two repairs),
`probes/gen_rival.py` (the rival audit). Runner: `probes/run1.sh`. Gate lines: `trackF/GATES.md`.

---

## §1 THE ENUMERATION — measured, not quoted

```
grep -ln "state prep seed is proven equal" ir-pass/test/*.ll | wc -l          32
  … of which DECLINE with it (oracle, one run each)                           29
  … of which ACCEPT (the string appears in a CHECK-NOT / a header)              3
grep -rln "state prep seed is proven equal" tests tools example                4   (all COMMENTS in
                                                                                   ACCEPT slices +
                                                                                   one CMake comment)
```

The 3 accept-fixtures are `control_inplace_ry_stateprep_bool_seed_int_cond.ll`,
`control_inplace_ry_stateprep_rail_i1_seed.ll`, `control_peel_stateprep_bool_seed_int_cond.ll`.
**No e2e slice declines with F2**, so the blast radius is confined to `ir-pass/test`.

**The 29 declines split 25 / 4, and the split is the first correction to the bead.**

| half | how it declines | count | R-2′ |
|---|---|---|---|
| the **PIN** half | `f2SeedPinnedByLiveRegister` returns true at the TEST `:1682-1683` | **25** | **flips all 25** |
| the **`Truncated`** half | the walk could not be completed; folded into `Pinned` at `:4155-4157` | **4** | **inert — 0 flip** |

The four truncation rows, with the probe that proves it (S: seed → a wild value; F2 **persists**):
`control_inplace_ry_reject_stateprep_step_cap_over.ll` (the step cap; its own header says *"the seed
is 7 and nothing in the module folds to 7"*), `…_unfoldable_curated_call.ll`,
`…_unevaluable_pinned_operand.ll`, `control_peel_reject_fp_stateprep.ll` (whose header already
records *"IT IS NOT A SEED COLLISION … changing the seed from 0 to 7 declines IDENTICALLY"*).

> ⚠ **`SCOPE_R2.md` §0.4 and `bd om35` both name `step_cap_over` in the "≥11 fixtures that would
> flip" list. Measured: it does not flip.** Nor do the other three. The correct figure is **25**,
> and it is larger, not smaller — the under-count came from enumerating the *names* the earlier
> scope happened to have read rather than running the corpus.

---

## §2 THE TABLE — one row per flipped fixture

Prefix `control_inplace_ry_reject_stateprep_` elided. **EDGE** = which edge of the region's branch
carries the pin: **ARM** = the edge into the arm block, **ST** = the straight-through edge into the
merge. The polarity decides the rival's shape and therefore which fence refuses it, and the
prediction was made *before* the rival was run: 25/25 landed on the predicted fence.

| # | fixture | what it PINS (the program class) | R-2′ → ACCEPT? | **is that ACCEPT CORRECT?** |
|---|---|---|---|---|
| 1 | `range_forward_add` | a forward USER of the compare's operand (`t+5`, `t∈{0,1}`) is the seed on the arm edge; `-O1` proved it and IPSCCP substituted, then instcombine rewrote the compare DOWN onto the ancestor. Header: *CONFIRMED SILENT MISCOMPILE*, reachable from plain C | **yes** — ARM · W→ACCEPT · A(seed 5)→F2 (the other edge's value is 5, so the two differ) · B→ACCEPT · S→ACCEPT | **ADMISSIBLE (α-form)**, not clean. Rival `r=6; if(t!=5) r=cq_theta(t,.9)` → **R3 `:4168-4170` `control flow`** (measured). The intended in-place unitary also has no lowering: BOTHSLOT → **R4 `:4283`**. Refusal survives R-2′ (different fence). ⚠ The user who writes the rival stops getting a loud decline and starts getting the prep circuit, silently |
| 2 | `range_forward_sub` | same, `or disjoint t,-4`, seed −3. *CONFIRMED-MISCOMPILE* | **yes** — ARM · A(−4)→F2 · B→ACCEPT · S→ACCEPT | as row 1. Rival → **R3** (measured). BOTHSLOT → R6 `:4434/:4486` |
| 3 | `range_forward_or` | same, `or disjoint t,8`, seed 9. *CONFIRMED-MISCOMPILE* | **yes** — ARM · A(8)→F2 · B · S | as row 1. Rival → **R3**. BOTHSLOT → R6 |
| 4 | `range_forward_xor` | same, `xor t,7`, seed 6. *CONFIRMED-MISCOMPILE* | **yes** — ARM · A(7)→F2 · B · S | as row 1. Rival → **R3**. BOTHSLOT → **R4** |
| 5 | `range_forward_ashr` | the SIGN-BIT split: `ashr q,31` is −1 on the negative edge, 0 on the other. *CONFIRMED-MISCOMPILE* | **yes** — ARM · A(0)→F2 · B · S | as row 1. Rival → **R3**. BOTHSLOT → R6. ⚠ this is a row where BOTH edges fold — to **different** values — so it is one-edge *for this seed* and would flip for either seed |
| 6 | `range_forward_lshr` | same, `lshr q,31`, seed 1. *CONFIRMED-MISCOMPILE* | **yes** — ARM · A(0)→F2 · B · S | as row 5. Rival → **R3**. BOTHSLOT → R6 |
| 7 | `sideways_offset` | the SIDEWAYS rewrite: the compare is on `q-15`, the pinned register is `udiv q,3` — a RANGE-derived pin (`q∈[15,18)`), not a constant-derived one | **yes** — ARM · W→ACCEPT · B · S | **ADMISSIBLE (α-form)**. Rival → **R3** (measured). BOTHSLOT → R6 |
| 8 | `sideways_sdiv` | same with `and q,-4` / `sdiv q,4`. *CONFIRMED-MISCOMPILE* | **yes** — ARM · W · B · S | as row 7. Rival → **R3**. BOTHSLOT → R6 |
| 9 | `merge_edge_sideways` | **the drbq Inc-4 flagship** — the same module as row 8 with the branch polarity swapped, so the pin lands on the straight-through edge; its `sdiv` in the merge block is the value F2's header records as SIGSEGV-ing LVI | **yes** — **ST** · W→ACCEPT · B · S | **ADMISSIBLE (α-form)**. Rival (register in the PRED slot) → **F1 `:3906-3915` `state prep merged with a quantum register`** (measured). Refusal survives R-2′ |
| 10 | `offwire_sideways_min` | the same collider defined BEFORE the branch (so it is in F2's backward `Cand`, not the forward half). Header: *confirmed silent miscompile* | **yes** — ARM · W · B · S | as row 7. Rival → **R3**. BOTHSLOT → R6 |
| 11 | `nonwire_still_collides` | a pinned value that is NOT on the condition's wire at all (`lshr q,31` beside `icmp eq q,3`) — the fixture that stops the 2026-09-11 `CondWire` narrowing being widened to "any pinned value" | **yes** — ARM · W→ACCEPT · B2→ACCEPT · S→ACCEPT | **ADMISSIBLE (α-form)**. Rival → **R3**. BOTHSLOT → R6. ⚠ this row is the one that pins `CondWire`'s BOUNDARY; R-2′ removes the boundary marker |
| 12 | `cast_zext_live` | the pinned register reached through a **width cast** (`zext q to i64` vs an i64 seed) | **yes** — ARM · W · B · S | **ADMISSIBLE (α-form)**. Rival → **R3**. BOTHSLOT → R6 |
| 13 | `cast_sext_live` | same, `sext`. *CONFIRMED-MISCOMPILE* | **yes** — ARM · W · B · S | as row 12 |
| 14 | `cast_trunc_live` | same, `trunc` to i16 | **yes** — ARM · W · B · S | as row 12 |
| 15 | `fp_seed_sitofp` | an **integer** pin crossing into an **fp** seed via `sitofp` — the wire F2 must not let cross (L9's angle-vs-data family) | **yes** — ARM · W · B · S | **ADMISSIBLE (α-form)**. Rival → **R3**. BOTHSLOT → R6. The anchor here is an `icmp`, so §5's fp hole does not reach this row |
| 16 | `fcmp_oeq_derived` | the **fp ANCHOR** (round-4 finding F-R4-1): an equality `fcmp` pins its own operand and the collider is `t*3` | **yes** — ARM · W→ACCEPT · A(5.0)→ACCEPT · B · S | **ADMISSIBLE for THIS row** (W closes it: `t≠5.0` on the other edge ⇒ `t*3≠15.0`). Rival → **R3**. BOTHSLOT → R6. ⚠ **but this is the cell HOLE-1 lives in — see §5** |
| 17 | `intrinsic_bswap` | a pinned register through a **curated intrinsic**. *CONFIRMED-MISCOMPILE* | **yes** — ARM · W · B · S | **ADMISSIBLE (α-form)**. Rival → **R3**. BOTHSLOT → R6 |
| 18 | `intrinsic_bitreverse` | same. *CONFIRMED-MISCOMPILE* | **yes** — ARM · W · B · S | as row 17 |
| 19 | `intrinsic_fshl` | same, funnel shift. *CONFIRMED-MISCOMPILE* | **yes** — ARM · W · B · S | as row 17 |
| 20 | `intrinsic_fshr` | same. *CONFIRMED-MISCOMPILE* | **yes** — ARM · W · B · S | as row 17 |
| 21 | `second_flag_i1` | **the row `SCOPE_R.md` §2 says any R-2 must keep declining**: an `i1` seed colliding with a SECOND, independent compare's flag, measured downstream, never branched on | **yes** — ARM · W→ACCEPT · B→ACCEPT · S(seed `false`)→ACCEPT | **ADMISSIBLE (α-form)**. Rival → **R3**. BOTHSLOT → R6. ⚠ R-2 (the retired spelling) deliberately kept this declining; **R-2′ does not**, and the fixture's header will need re-deriving rather than editing |
| 22 | `second_cmp_onwire_merge` | a second tainted compare on the wire that is **NOT** a peel clone, in the merge block — one of the two fixtures R-1 (`rb9x`) shipped **so that R-1 could not be widened into "any second compare"** | **yes** — **ST** · A(seed `true`)→F2 · B→ACCEPT | **ADMISSIBLE (α-form)**. Rival → **F1** `state prep merged with a quantum register` (measured). ⚠ **cost**: R-1's own anti-widening guard is gone |
| 23 | `second_cmp_onwire_pred` | the same before the branch | **yes** — **ST** · A→F2 · B→ACCEPT | as row 22 |
| 24 | `zext_flag_i32seed` | `SCOPE_R.md` §3e's finding: the collider class reaches EVERY width through `zext`, so `rb9x` is not a `_Bool` defect | **yes** — **ST** · A2(seed 1)→F2 · B→ACCEPT · S2→ACCEPT | **ADMISSIBLE (α-form)**. Rival → **F1** (measured) |
| 25 | `control_peel_reject_stateprep_handwritten_clone_i1` | a **hand-written** `%cq.peel.cond`: membership in `taint.PeelClones` is a RECORD, never a name — the fixture that stops R-1 from becoming name- or shape-based | **yes** — **ST** · A→F2 · B→ACCEPT | **ADMISSIBLE (α-form)**. Rival → **F1** (measured). ⚠ **cost**: R-1's second anti-widening guard is gone |

**Column-4 tally: 25 rows, 25 closed, 0 row-level HOLE** — in every row the rival was built and run
and it declined, and the refusing fence is a *different* predicate that R-2′ does not touch.
**20 ARM rows → R3 `ArmClassify.cpp:4168-4170`; 5 ST rows → F1 `ArmClassify.cpp:3906-3915`.**
Two predicate-level HOLEs, which are not rows, are in §5.

**How the fences were identified, since 25 sites in this file print `control flow` on the same
anchor.** Not by the anchor — by bisection on R3's own predicate `RotBase != Routed`:
`probes/fence/r3_isolate_literal_pred.ll` (an OFF-wire tainted base rotated in the arm, a literal
in the pred slot) declines `control flow`; `r3_isolate_other_literal_pred.ll` (a different literal)
declines identically; `r3_isolate_register_pred.ll` (the SAME register in the pred slot) **ACCEPTS**
at exit 0. That is SCOPE_R2's `x_B1`/`x_B5` pair reproduced on this session's oracle, and it also
establishes the thing §5 needs: **the in-place arm does lower when the base is off-wire** — the
20 BOTHSLOT declines in the table are R4/R6 facts about those particular modules, not about the
class.

**The rival's completeness, stated as a case analysis over the two slots** (this is R-2′'s actual
argument, and the measurement matches it row for row). The subject shows the literal `K` in both
the arm theta's arg-0 and the φ's pred incoming. A source program folds into it only if `-O1` could
substitute `K` for a register in the slot(s) where the source had one:

* register in the **arm slot only** ⇒ needs the register ≡ K on the **arm edge** ⇒ the pred slot was
  already the literal ⇒ `Routed` is a literal ≠ `RotBase` ⇒ **R3**;
* register in the **pred slot only** ⇒ needs it ≡ K on the **straight-through edge** ⇒ a TAINTED
  pred incoming ⇒ **F1**;
* **different** registers in the two slots ⇒ `RotBase != Routed` ⇒ **R3**;
* the **same** register in both ⇒ needs it ≡ K on **both** edges ⇒ excluded by the one-edge premise.

There is no fifth case, which is why the audit has no row-level hole — and why everything now
depends on how good the one-edge premise is (§5).

---

## §3 THE THREE THINGS BESIDE THE TABLE

### 3a The one-edge pin is a REAL property, not a spelling — 19 controls, plus 2 counter-controls

TEST W, per §0, on every row where a branch constant exists to move (16 fixtures) **plus the three
customers** — 19/19 **ACCEPT**:

```
cast_{zext,sext,trunc}_live · fp_seed_sitofp · intrinsic_{bswap,bitreverse,fshl,fshr}
nonwire_still_collides · sideways_{sdiv,offset} · merge_edge_sideways · offwire_sideways_min
second_flag_i1 · fcmp_oeq_derived · range_forward_add          →  16 × ACCEPT
owner.W.ll · vd.W.ll · w2.W.ll                                 →   3 × ACCEPT
```

and for the nine rows whose two edges both fold (the six `range_forward_*` and the three `i1` clone
rows), TEST **A** is stronger than W and was used instead: setting the seed to the value the SAME
collider takes on the OTHER edge **re-declines** (10 of 11 valid A-probes → F2), which is a direct
exhibition of two different per-edge values.

The counter-controls are the point: `c1_and_zero` and `c2_always_false_i1` are both-edge pins and
**W leaves both declining**. An instrument that answered "one edge" on those would have been
worthless, and I ran them before trusting the other nineteen.

### 3b The RANGE-derived pin (`w2.c`'s lesson) — **yes, the argument holds**

`SCOPE_R2`/`om35` ask whether R-2′'s one-edge argument needs a *constant*-derived pin. It does not,
and the reason is structural: the case analysis in §2 is about **which edge** the pin sits on, and
says nothing about how the edge fact was derived. Measured on both kinds:

* constant-derived — `icmp eq %q, 5` pinning `%q` to a singleton (rows 12–20): W → ACCEPT;
* **range**-derived — `and %q,-4`/`icmp eq …, 20` pinning `%q` to `[20,24)` and the collider to
  `sdiv %q,4 = 5` (rows 7, 8, 9, 10): W → ACCEPT;
* **range-derived with a runtime scrutinee** — `w2.c` (`a = argc+4`, no IPSCCP constant anywhere):
  declines F2 at `w2.c:9:11`, its collider `%17 = icmp sgt i32 %16, 2` pinned on the
  straight-through edge, **W → ACCEPT** and the sole-collider control `S1` (`sgt %16, 2` → `sgt
  %16, 1`) → ACCEPT.

So the class is not an IPSCCP artefact and R-2′'s polarity analysis covers it unchanged.

### 3c THE CUSTOMERS, measured on this oracle

| program | verdict today | collider | edge | W / sole-collider control |
|---|---|---|---|---|
| `example/grover/grover_oracle_uncompute.c` (the owner's file, mtime 2026-09-14 09:43) | **F2** | `%9 = icmp sgt i32 %8, 2`, `%8 = select i1 %6, i32 %7, i32 %2` | **ST** | `owner.W.ll` (mux constant 2→9) → **ACCEPT**; `owner.S1.ll` (`sgt %8,1`) → **ACCEPT** |
| `probes/vd.c` (N=3 cascade) | **F2** | identical | **ST** | `vd.W.ll` → ACCEPT; `vd.S1.ll` → ACCEPT |
| `probes/w2.c` (runtime `a`) | **F2** | `%17 = icmp sgt i32 %16, 2`, `%16 = select i1 %14, …` | **ST** | `w2.W.ll` → ACCEPT; `w2.S1.ll` → ACCEPT |

The S1 controls matter twice: they re-measure `DIAG_2026-09-14.md`'s surgery on **this** binary and
on the owner's file **as it stands now**, and they prove the identified collider is the **only** one
— so a narrowing that excludes exactly it compiles the file.

The rival for this class is well-formed only once the collider is spelled on the pre-region
register, which is `r_R6a`/`r_R6b` (SCOPE_R's 12-line minimal reproduction). Measured:
`probes/rival/r_R6{a,b}…RIVAL_ST.ll` → **F1 `state prep merged with a quantum register`**, with
`…HOIST_ONLY.ll` (the same hoist, slot unchanged) still → F2, so it is the slot edit and not the
hoist that moves the verdict.

---

## §4 WHAT THE MEASUREMENT SAYS THAT THE BEAD DOES NOT (Rule 11)

`SCOPE_R2.md` warned that R-2's *stated* ground was wrong and told me not to inherit it. Derived
from what I measured, **R-2′'s ground is also not what `om35` records**, in four ways:

1. **The count.** "≥11 shipped decline fixtures" → **25**, and the list must drop `step_cap_over`
   (a `Truncated` row) and add the four cast/`sitofp`/intrinsic families, both `second_cmp_onwire_*`,
   `zext_flag_i32seed`, `nonwire_still_collides`, `second_flag_i1`, `handwritten_clone_i1` and
   `sideways_offset`.
2. **The F1 string.** `om35` and `SCOPE_R2` row 5 say the register-pred-slot rival declines
   `state prep seed does not match the merge incoming`. **Measured, 5/5, it declines
   `state prep merged with a quantum register`** — the *other* arm of F1's message split at
   `ArmClassify.cpp:3906-3915`, taken because the pred incoming is TAINTED. The split exists
   precisely so the message names the physics; a retirement trigger written against the wrong half
   would not fire.
3. **The line numbers are stale by a whole tree.** R3 is `:4168-4170`, not `:4102-4103`; R6 is
   `:4434` and `:4486`, not `:4420`; the condition-data-use fence is `:3323`, not `:3257`; R4 is
   `:4283`. F2's test is `:1682-1683` and its edge loop `:1558`.
4. **"F1 pins the pred slot ⇒ the rival is unfoldable" is the right idea and the wrong sentence.**
   F1 does not make the rival unfoldable — it makes ONE of the two one-slot rivals *undeclinable
   silently*. What makes the rival unfoldable is the **one-edge premise itself**; F1 and R3 are what
   refuse the two spellings that remain. Stated the bead's way, the argument sounds like a theorem
   about F1; stated correctly it is a case analysis whose load-bearing assumption is that **F2's
   own model is at least as strong as `-O1`'s on the edge where it found nothing**. That assumption
   is §5.

---

## §5 THE RESIDUAL F2 AFTER R-2′ — the direction inversion, and the one demonstrated HOLE

### 5a The inversion (a property, not a row, and it is the reason to hesitate)

Today F2 declines if **any** edge pins: a disjunction. A weakness in F2's abstract model can only
make it miss a pin on one edge, and the other edge — or `Truncated` — covers it; the failure
direction is an **over-decline**, which is the safe one and is exactly what the four `Truncated`
fixtures are committed to pin. R-2′ makes the test a **conjunction** over edges. From that day, a
weakness in the model on **either** edge produces an **ACCEPT**. `Truncated` does not backstop it:
`Truncated` fires when the walk *fails*, never when it silently under-approximates, and
`f2Model` under-approximates by design — *"a tainted user it cannot bound is SKIPPED when none of
its operands is pinned"* (`…_unevaluable_pinned_operand.ll`'s header). On the edge that does not
carry a singleton, almost nothing is pinned, so almost everything is skipped — which is why the
corpus has zero both-edge pins among derived colliders and why R-2′ does not so much narrow F2's
pin half as empty it.

Measured, in the two directions that bound the claim:

* **in the corpus**: 25/25 one-edge, 0 both-edge;
* **from C**: `probes/c/be1.c` (`int t = q & 0;`) and `be2.c` (`int t = (q&3)/4;`) both ACCEPT
  because `clang -O1` **deleted the collider outright** — 0 occurrences survive to stage 2. So the
  both-edge class that R-2′ leaves behind is, in the two spellings I could write, not reachable from
  C at all. Two spellings is not a proof and I say it that way (L5).

The mitigating half, said as plainly: **for a value that DOMINATES the branch — which is the only
kind that can occupy the φ's pred slot — F2 asks `LazyValueInfo::getConstantRangeOnEdge` directly
(`:1560-1566`), and that is the same oracle `CorrelatedValuePropagation` uses to do the
substitution in the first place.** So on the ST side the one-edge judgement is as strong as the
substituting pass's. The exposure is the ARM side and the forward half, where F2's
`ConstantRange` model is its own and is known to have lost four adversarial rounds to `-O1`.

### 5b HOLE-1 — **fp anchors make the one-edge test VACUOUS, and it is demonstrated**

F2's only fp seeding rule is the equality-`fcmp` anchor, and its polarity switch
(`ArmClassify.cpp:1596-1614`) sets `EqHolds` **on exactly one edge by construction**, for every
predicate it accepts. Therefore, for any region whose condition is an `FCmpInst`, **every** collider
is reported "pinned on one edge only" — whether or not it is semantically the seed on the other
edge. R-2′ would flip **every** fp-anchored F2 decline unconditionally, with no residual protection.

Demonstrated on `probes/fence/fp_bothedge_attempt*.ll`:

```
fp_bothedge_attempt.ll                    F2   (the subject: %d = fmul %t, 0.0, seed 0.0)
fp_bothedge_attempt.W.ll                  F2   ← TEST W does NOT flip it: the fcmp constant moved
                                               5.0 → 6.0 and the pin SURVIVES.  For every integer
                                               row that signature meant BOTH-EDGE — yet F2's fp
                                               anchor still only ever reports one edge, so R-2'
                                               flips it anyway.
fp_bothedge_attempt.nomeasure.ll          F2   (the same without the downstream measure)
fp_bothedge_attempt.BOTHSLOT_nomeasure.ll ACCEPT, exit 0  ← THE IN-PLACE RIVAL LOWERS
```

So there is a module R-2′ accepts as a state prep whose in-place reading **compiles today**. That is
the shape SCOPE_R2's row 8 recorded as safe *because R-2 did not fire there*; **R-2′ does fire
there**. What I could **not** settle, and therefore label **HOLE**: whether a *reachable-from-C*
instance exists. Without fast-math `-O1` will not fold `fmul x, 0.0` to `0.0` (NaN/inf), so this
exact pair is not a preimage/image pair; with fast-math `-O1` deletes the value and F2 never fires.
I could not construct a reachable instance and I could not prove none exists. **HOLE-1 stands, and
any build of R-2′ must carve fp out** (§7).

### 5c HOLE-2 — the α-form ground is being transplanted onto fences of a different KIND

The 2026-09-11 `CondWire` ruling licensed exactly this trade once, and CLAUDE.md states its price in
the words that must be reused here: *"A program that was LOUDLY REFUSED now receives the circuit for
the other reading, with no diagnostic."* What it does **not** transfer for free is the *kind* of
fence doing the refusing. There the rival died at **R4** — `RotBase ∈ CondRails`, a fence grounded in
the flag strip's premise, i.e. in the **unitary**. Here the rival dies at **R3** (*"a cross-handle
multiplexer, not a rotation arm"*) and at **F1** (*"state prep merged with a quantum register"*) —
both **expressiveness** declines over shapes that are value-muxes, which is what `SelectMergeEmit`
and the 4.4 merge exist to do. An expressiveness fence is a capability gap somebody is eventually
paid to close; a unitary fence is not. **HOLE-2 is not a measurement I failed to take — it is a
judgement an agent must not make**: whether the α ruling extends from a physics fence to two
capability fences is the owner's, and 13 of the 25 rows carry the words *CONFIRMED MISCOMPILE* in
their own headers.

---

## §6 THE NARROWER PREDICATE THE MEASUREMENT SURFACED — 3 customers, 0 fixtures

While assigning polarities I measured something neither `om35` nor `SCOPE_R2` records:

> **In all three customers the pinned value is a DESCENDANT of the region's own merge φ.
> In 0 of the 25 shipped fixtures is it.**

```
owner / vd : %9  = icmp sgt %8, 2   with  %8  = select i1 %6,  …   and %6  IS the region's merge φ
w2         : %17 = icmp sgt %16,2   with  %16 = select i1 %14, …   and %14 IS the region's merge φ
the 25     : collider-uses-phi = no, 25/25  (mechanical check, GATES.md)
```

`f2Model`'s `SelectInst` arm UNIONS the two value operands and never reads the condition
(`:1211-1219`), which is why F2 reaches such a value at all — `DIAG_2026-09-14.md` §Q1(b) shows the
exact fold, `[-1,2] sle 2 ⇒ false`.

**The predicate.** At the same TEST, `ArmClassify.cpp:1682-1683`, one more conjunct:

```
  V is not a collider if the region's own state-prep merge φ M is in V's transitive
  operand closure within this function.
```

**Its ground is structural and needs no edge reasoning at all.** `M` is defined at the join. A value
that uses `M` is available neither inside the arm (which precedes the join) nor on the pred edge
(use-before-def). So it cannot have occupied either of the two source slots F2's question is about
— *"the source the author wrote could have been `cq_theta(<that register>, θ)`"* — and it is not in
the question's domain. That is the same kind of argument R-1 (`rb9x`) uses, and it is stronger than
R-2′'s, which has to reason about what `-O1` could prove.

**Its cost, measured: ZERO shipped fixtures.** It closes the owner's file, `vd.c` and `w2.c` (the S1
controls prove the φ-descendant is the sole collider in each). It leaves every row of §2 declining,
leaves `second_flag_i1` and both `second_cmp_onwire_*` and `handwritten_clone_i1` declining — i.e.
it does not disarm R-1's anti-widening guards — and it is inert on `Truncated`.

**What it does NOT close, said plainly**: `r_R6a` / `r_R6b`, the hand-IR minimal abstraction of
`vd`'s class, whose collider reads the PRE-region register and is therefore not a φ descendant. Those
are scoping probes, not customers; if the owner wants that whole class, the price is §2's table.

**Its own residual risk, which is an audit it owes and has not had**: the argument is about the
MODULE's dependence graph and the question is about the SOURCE, so it must argue that `-O1` cannot
rewrite a value that did not depend on `M` into one that does. That is the sideways-rewrite family
and it is L5's shape — the same trap F2 fell into four rounds running. **I am recording this
predicate, not clearing it.** It needs its own rival audit (the 2026-09-11 "32/32" shape), its own
Rule-13 round, and a bd of its own.

---

## §7 RETIREMENT TRIGGERS, as file:line conditions a future agent can check mechanically

Written for R-2′ if it is built. Each names a probe in this track that must keep its verdict.

| # | condition | if it fires | mechanical check |
|---|---|---|---|
| T1 | `ArmClassify.cpp:4168-4170` — R3, `if (Routed && RotBase != Routed)` — stops declining, i.e. a cross-handle merge of a rotated register against a literal ever LOWERS | all **20** ARM-edge accepts become over-accepts, with no diagnostic anywhere | `probes/fence/r3_isolate_literal_pred.ll` must stay `control flow`; `…register_pred.ll` must stay ACCEPT |
| T2 | `ArmClassify.cpp:3906-3915` — F1's TAINTED-incoming arm — stops declining, or its message split changes so the tainted half no longer exists | all **5** ST-edge accepts become over-accepts | the five `probes/rival/*.RIVAL.ll` ST modules must stay `state prep merged with a quantum register` |
| T3 | `ArmClassify.cpp:1596-1614` — the fp anchor's `EqHolds` switch — gains a second seeding rule, or R-2′ is ever applied to a region whose `BI->getCondition()` is an `FCmpInst` | **HOLE-1**: R-2′ has no residual protection at all for fp anchors | `probes/fence/fp_bothedge_attempt.nomeasure.ll` must stay F2 while `…BOTHSLOT_nomeasure.ll` ACCEPTs — if both are true, the carve-out is load-bearing |
| T4 | `ArmClassify.cpp:1558` — the per-edge loop — regains an early `return` for any reason, so the two edges are no longer both walked | the intersection R-2′ computes is over a partial record; the answer is unsound in the ACCEPT direction | any per-edge record must be read AFTER the loop, never inside it |
| T5 | `ArmClassify.cpp:4155-4157` — `Pinned = … || Truncated` — is refactored so R-2′'s conjunct also gates `Truncated` | the four truncation fixtures silently become accepts | `step_cap_over`, `unfoldable_curated_call`, `unevaluable_pinned_operand`, `control_peel_reject_fp_stateprep` must stay red |
| T6 | `ArmClassify.cpp:4283` (R4) or `:4434`/`:4486` (R6) stop declining | does **not** retire R-2′ (its preimage argument runs through R3/F1) but retires the *comfort* that the intended in-place unitary was unreachable anyway | the 20 `probes/rival/*.BOTHSLOT.ll` must stay red |
| T7 | F2's own standing trigger, inherited: if `railWireClosure` as called by F2 ever diverges from R4's `CondRails` (`ArmClassify.cpp:1283`) | re-derive §2 from scratch | — |

For the §6 predicate, if that is built instead, the trigger set is much smaller and it is one line:
**`f2Model`'s `SelectInst` arm at `:1211-1219`** — the day it stops unioning and starts reading the
select's condition, the φ-descendant class changes shape and §6 must be re-derived; plus the
standing T7.

---

## §8 RECOMMENDATION — three lines

**DO NOT BUILD R-2′ as spelled.** The measured price is **25** shipped decline fixtures re-derived
(not "≥11"), **13** of which carry *CONFIRMED MISCOMPILE* in their own headers, **3** of which exist
solely to stop R-1 and the 2026-09-11 narrowing being widened; it flips F2's pin half from a
disjunction to a conjunction, so from that day a weakness in F2's abstract model costs an **ACCEPT**
instead of a decline; and it carries a demonstrated **HOLE-1** in the fp cell.

**BUILD-NARROWED**, and the narrowing is **not** a carve-out of R-2′ but §6's predicate:

> at `ArmClassify.cpp:1682-1683`, `V` is not a collider **if the region's own state-prep merge φ is
> in `V`'s transitive operand closure within this function** — because a value that uses the φ is
> available neither in the arm nor on the pred edge, so it cannot have been the register the author
> rotated.

**Budget: 2 Rule-13 rounds** (round 2's assignment is §6's residual — that `-O1` cannot rewrite a
non-φ-dependent source value into a φ-dependent module value), **0 shipped fixtures flip**,
**3 customers close** (the owner's file, `vd.c`, `w2.c`), and the count of column-4 rows carried
over is **0 CORRECT / 0 HOLE, because the table is not paid for at all**. If the owner instead wants
the whole one-edge class, R-2′ is the price list above and it needs **3** rounds, an fp carve-out
(`BI->getCondition()` may not be an `FCmpInst`), and re-derived headers on 25 fixtures rather than
edited ones.

---

## §9 THE PARAGRAPH FOR THE OWNER

R-2′ buys exactly one thing and it is the thing you asked for: your file compiles. It buys it by
telling F2 to stop caring about a value that is provably your seed on *one* of the branch's two
edges, and to decline only when the same value is your seed on *both*. I measured what that costs
and it is bigger than the bead says: not eleven fixtures but **twenty-five** — every cast, every
curated intrinsic, every "sideways rewrite", the drbq Inc-4 flagship, and the two fixtures that
exist only to stop last week's `rb9x` narrowing being widened — and **thirteen of those
twenty-five say CONFIRMED MISCOMPILE in their own first ten lines**, each one a program someone
wrote in ordinary C and watched compile to the wrong unitary. I built the rival for all twenty-five
and every single one still declines loudly afterwards (twenty at R3, five at F1), so on the
2026-09-11 precedent none of them is *unsafe* in the sense that ruling used — but two things are
worth your minute. First, that precedent rested on the rival dying at a **physics** fence; here it
dies at two **capability** fences over value-muxes that CQ is otherwise in the business of
compiling, so the safety margin is something a future increment is likely to spend. Second, and
this is the part I would not want you to learn later: today F2 declines if *either* edge pins, so a
gap in its reasoning costs you a spurious decline; after R-2′ it declines only if *both* edges pin,
so the same gap costs you a silent wrong circuit — and F2 has lost four adversarial rounds to
exactly such gaps. I found one already, in floating point, where the narrowing has no protection
left at all and the rival compiles. **The good news is that you do not have to buy any of this to
get your file**: in your file, in `vd.c` and in the runtime-`a` version, the value F2 trips over is
one that *reads the output of the very region it is complaining about* — it physically cannot be
the register you rotated, because it does not exist yet at that point in the program — and none of
the twenty-five fixtures is of that kind. Excluding exactly that costs **zero fixtures**, closes all
three of your programs, and rests on an argument about program structure rather than on a guess
about what `-O1` can prove. That is the one I would build, and it still owes its own adversarial
round before it lands.

---

## §10 PROBE INDEX

```
trackF/probes/run1.sh                     one-module runner on the frozen ORACLE
trackF/probes/gen_pin.py                  TEST S / A / B over the 29 declining fixtures
trackF/probes/gen_pin2.py                 TEST W + the two round-1 repairs
trackF/probes/gen_rival.py                the 25 unfolded rivals (+ BOTHSLOT twins)
trackF/probes/pin/                        S / A / B / W variants                   (80 modules)
trackF/probes/rival/                      25 RIVAL + 20 BOTHSLOT + the r_R6 quartet (49 modules)
trackF/probes/bothedge/                   C1 / C2 both-edge positive controls + W + rivals (7)
trackF/probes/fence/                      R3 isolation triple · the fp HOLE-1 quartet (8)
trackF/probes/c/                          owner / vd / w2 stage-1 IR + W + S1; be1 / be2 (8)
trackF/GATES.md                           every gate, hash-keyed
```
