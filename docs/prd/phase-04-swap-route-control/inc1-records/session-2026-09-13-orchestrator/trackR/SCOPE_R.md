# SCOPE — Track R: F2's collider set, the peel's compare CLONE (bd `rb9x`), and what `vd`'s decline actually is

Written 2026-09-13 by the Track-R scoping agent. **READ-ONLY, measure-first**: nothing was built,
no suite was run, no file outside `trackR/` was touched (PROTOCOL.md row "scoping"). Every number
below carries its command. Line numbers are `01c89b5` (docs-only over the pass at `e96f89c`; the
only `ir-pass/src` delta in `571c7cd` is nine comment lines in `MergePhiPeel.cpp`).

```
shasum -a 256 build/ir-pass/cq-opt       fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661  == session ORACLE
shasum -a 256 build/ir-pass/libCQPass.so 40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93  == session ORACLE
```

**Headline.** (1) The clone enters through the **FORWARD half**, as a tainted USER of the
condition's own pinned operand rail — four steps, `ArmClassify.cpp:1549 → 1619 → 1198 → 1616` —
and the `_Bool`-only character of bd `rb9x` is the **type test at `:1616`**, nothing deeper.
(2) `vd`'s decline is **NOT** `rb9x`'s clone: **no peel happens in the declining region at all**.
It is the THIRD region's guard compare `%9 = icmp sgt i32 %8, 2` (`vd.c:19`, `a >= 3`), pinned to
`i1 false` on the TRUE edge of `br i1 %1`. Same mechanism, different subject — so `vd` needs a
SECOND narrowing with its OWN argument, and Track M alone does not make it compile.
(3) ⚠ **The obvious unifying fix — "a collider must dominate the arm" — is REFUSED by the shipped
fixture corpus**: ≥11 of the 27 F2 decline fixtures, including the drbq Inc-4 flagship's
merge-block `sdiv`, pin exactly post-branch colliders. §3 carries the measurement.

---

## §0 Verdict table — 36 probes (14 baseline + 11 route + 6 `vd` + 5 rival) + 3 IR surgeries on the ORACLE

`probes/README.md` carries the full table with the exact command, the shape, the verdict and the
`CQ_CTRL_DBG=1` anchor per decline; `probes/run.sh` re-runs it (it re-checks the ORACLE hash and
stops if it moved), `probes/surgery_vd.sh` re-runs the three identification surgeries. The rows
this document leans on:

| group | probes | result |
|---|---|---|
| the 2026-09-11 baseline, re-run | `b_HP_f` ACCEPT 9 · `b_HP_{a,c,d,e,g}` DECLINE F2 · `b_HP_b` DECLINE `condition data use` · `b_P1`/`b_P1t` ACCEPT 9 · `b_P2`/`b_P2t` DECLINE F2 · `b_A` DECLINE F2 · `b_B` ACCEPT 19 · `b_C` ACCEPT 22 | reproduced **exactly** as review_integration §4 I-1 recorded them |
| the route | `r_R1` ACCEPT 16 / `r_R1b` DECLINE · `r_R3` DECLINE / `r_R3t` ACCEPT 12 · `r_R4c` ACCEPT 11 / `r_R4b` DECLINE · `r_R5` DECLINE | §1 |
| `vd` | `v_vd` DECLINE F2 @ the b0 theta · `r_R6a`/`r_R6b` DECLINE F2 (minimal, **no peel**) · `r_R6c` ACCEPT 20 · surgeries S1/S2/S3 all kill F2 | §1.2 |
| M's wall, isolated | `v_vd_two_regions` / `v_vd_guard_neg` DECLINE `control flow` at `select i1 %5, i32 %6, i32 %cq.peel.mux` | §6 |
| the rivals | `w_W1` DECLINE **F1** (not `condition data use` — bd `rb9x`'s prediction is wrong) · `w_W2`/`w_W3`/`w_W4`/`w_W5` DECLINE `control flow` | §3 |

Two probes did not measure what they were written for, and both are reported rather than quietly
dropped (Rule 19): `v_vd_no_b1_arm` (removing `if (b1) a -= 3` makes `-O1` **fuse** the b1 and b2
preps into one arm, so it declines `control flow` for an unrelated reason — `r_R6a` is the clean
separation instead), and `r_R4` (its `zext i1 %clone to i32` is ITSELF pinned to `i32 0` and is the
collider; `r_R4c` removes the confound and ACCEPTS — see §3e, this is a finding).

---

## §1 THE ROUTE

### 1.1 The peel's clone (question 1) — the FORWARD half, four steps

The clone is `S.CondCmp->clone()` inserted at `S.MergeBB->getFirstNonPHI()`
(`MergePhiPeel.cpp:470,481-482`), named `cq.peel.cond`, and inserted into the taint set at
`MergePhiPeel.cpp:491`. The integration reviewer's elimination is confirmed: it **cannot** be in
the backward half, because `Cand` admits only values with `DT->dominates(&In, BI)`
(`ArmClassify.cpp:1505-1510`) and the merge block does not dominate the pred's terminator. The
route is the forward half, and every step has a probe:

| step | site | what happens | witness |
|---|---|---|---|
| 1 | `:1549-1553` | `Cand` holds the condition's tainted operand rail `%1` (it dominates `BI`). `LVI.getConstantRangeOnEdge` returns a NON-full range on **both** edges of `icmp eq %1, 1` — `{1}` on the true edge, `full∖{1}` on the false one — so `f2Note` seeds `S.WL` with `%1` | `r_R1` (operand OFF the wire, unpinned on both edges ⇒ **ACCEPT**) vs `r_R1b` (same module, operand ON the wire ⇒ DECLINE) |
| 2 | `:1619-1626` | `%1` is popped and the walk visits **every tainted user of `%1` in the function, with no position filter of any kind**. The clone is such a user (it has the same operands), and it is tainted *because* `MergePhiPeel.cpp:491` put it in `taint.Tainted` — which is exactly what stops `:1623`'s `if (!Taint.Tainted.count(I)) continue;` from skipping it | `r_R5` (the same compare placed BEFORE the branch also declines — both halves reach it) |
| 3 | `:1198-1208`, `f2Model`'s `ICmpInst` arm | `L = f2Range(%1)`, `Rr = {1}`: on the true edge `L.icmp(eq, Rr)` holds ⇒ `Res = ConstantRange(APInt(1,1))`; on the false edge the INVERSE predicate holds (the ranges are disjoint) ⇒ `Res = ConstantRange(APInt(1,0))`. `f2Note` records the singleton and pushes the clone | `r_R3`/`r_R3t`: with cond `sgt %1,0` and clone `eq %1,5` only the FALSE edge folds, and only to `false` — so seed `false` DECLINES and seed `true` ACCEPTS. That asymmetry is a signature of range reasoning on the OPERAND's edge range and of nothing else |
| 4 | `:1616` | the clone is popped and tested. `V->getType() == Seed->getType()` → `i1 == i1` for a `_Bool` prep; `!CondWire.count(V)` → **true**, because `CondWire` (built at `:4077-4082` as `{Region.Condition} ∪ ⋃_{P∈condProvenance} railWireClosure(P, BackwardOnly)`) is the condition's BACKWARD cone and the clone is a FORWARD sibling of it; `f2Exact(V, S) == Seed` → `true` on the true edge, `false` on the false edge. **Both** `i1` seeds therefore collide, one per edge — which is why `b_P2` and `b_P2t` both decline | `r_R4c` (the identical clone against an `i32` seed ⇒ **ACCEPT** 11) |

Two corollaries worth carrying:

* **The `_Bool`-only character of bd `rb9x` is step 4's type test and nothing deeper.** An `i1`
  compare flag can only ever collide with an `i1` seed — so `int b1` (probes `b_B`, `b_C`) accepts
  while `bool b1` (`b_A`, `b_P2`) declines. There is no `i1` special case anywhere in F2; this is
  the same consequence-of-the-candidate-list argument `control_inplace_ry_stateprep_bool_seed_int_cond.ll`
  already writes down for the region's own compare.
* **The clone is not special at step 3.** `b_HP_d` (different predicate) and `b_HP_e` (different
  constant) decline identically: what matters is that the value is *pinned*, not that it is a copy.

### 1.2 `vd`'s collider (question 2) — a DIFFERENT F2 collider, and no peel is involved

```
$LLVM/clang -Iinclude -include CQ.h -O1 -g -emit-llvm -S probes/vd.c -o vd.s1.ll
build/ir-pass/cq-opt … -S vd.s1.ll    ⇒ exit 1, vd.c:10:14 … state prep seed is proven equal …
CQ_CTRL_DBG: decline [state prep seed is proven equal to the condition register] at:
   %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
```

**The region being classified.** `-O1` hands the pass two diamonds. The declining one is the FUSED
diamond `br i1 %1`, whose condition is **b0's bare rail** (`%1` = the `cq_theta_i1` result — which
is why the anchor is that call and the `!dbg` is `vd.c:10`, the b0 theta, *not* the prep). Its arm
`%3` defines `%4` (the b1 theta) and its merge `%5` carries **exactly one φ**,
`%6 = phi i1 [%4,%3],[false,%0]` — the b1 state prep, seed `i1 false`. `-O1` had already hoisted
region 1's `a`-mux into the entry block as `%2 = select i1 %1, i32 2, i32 5`, so **`MergePhiPeel`
has nothing to peel here: there is no second merge φ, no `cq.peel.cond`, no clone.**

**The pinned value.** `%9 = icmp sgt i32 %8, 2` — the *third* region's guard, `vd.c:19`'s
`a >= 3`, defined in the merge block `%5`. On the **TRUE** edge of `br i1 %1` the forward half
walks `%1 = {1} → %2 = {2} → %7 = {-1} → %8 ∈ [-1,3) → sgt 2` **provably false**, so `%9` is
pinned to `i1 false`, which is the seed; `%9` is not in `CondWire` (it is forward of the condition,
and an `icmp` mints a fresh rail anyway); and `i1 == i1`. `:1616` returns true.

**Four independent confirmations** (`probes/surgery_vd.sh`, `r_R6*`):

| change | F2 |
|---|---|
| S1: `icmp sgt %8, 2` → `sgt %8, -5` (provably TRUE on both edges) | **gone** → `control flow` |
| S2: → `sgt %8, 0` (unprovable on the true edge) | **gone** → `control flow` |
| S3: the b1 prep's seed `false` → `true` (the pin is still `false`) | **gone** → `control flow` |
| C-level `v_vd_guard_neg.c` (`a >= -5` for the third guard) | **gone** → `control flow` |
| `r_R6c` (the mux constant `2`→`9`, so the TRUE edge's range is > 2) | **gone**, ACCEPT 20 |

**And the class reproduces with no peel and no third region at all**: `r_R6a` (12 lines of hand IR:
a rail condition, an `i1` prep φ, and one merge-block compare on the condition's wire) declines F2.
`r_R6b` is the same with the flag used as a second region's branch condition — `vd`'s own shape.

**So the answer to question 2 is: a different collider, the same mechanism.** `rb9x`'s fix does not
touch it. The two share step 1–4 of §1.1 and differ in what the pinned `i1` *is*: a
compiler-manufactured clone of the region's own compare (rb9x) versus a **user-written compare that
is another region's guard** (`vd`). Those are different programs and they need different arguments.

---

## §2 THE DESIGN

### R-1 — exclude the peel's CLONES (closes bd `rb9x`)

**Spelling (i), the RECORD — recommended.** `peelIndependentMergePhis` writes the clone into a new
`taint.PeelClones` at the clone site (`MergePhiPeel.cpp:491`, beside the existing
`taint.Tainted.insert(Clone)`), and `f2SeedPinnedByLiveRegister` consults it in the ONE place
`CondWire` is consulted (`ArmClassify.cpp:1616`), as one more conjunct:
`&& !Taint.PeelClones.count(V)`. This is the L1 pattern verbatim — record the question at the site
that *knows* the answer, ask it at the site that *needs* it.

⚠ **And the record must be consulted at the TEST, never used to prune the WALK** — the separate,
measured reason is in §5: `control_peel_reject_fp_stateprep.ll` declines through `f2Model`'s
conservative arm on a fp select that is reachable ONLY through the clone, so pruning would flip a
deliberately-pinned capability cost into an unargued fp-mux accept.

**Spelling (ii), the STRUCTURAL test** ("a tainted `icmp` whose predicate and operands are
byte-identical to `Region.Condition`'s") is **refused**: it is a second spelling of "the same
compare", which is the drbq Inc-3 (b′) defect shape (Rule 14), and it is strictly weaker — it
cannot tell a clone from a compare the *user* wrote twice, and the whole argument for R-1 is that
the clone **has no source preimage**.

**The argument, and it is STRONGER than the 2026-09-11 `CondWire` one.** The 2026-09-11 narrowing
had to reason about rival *programs* (α: the in-place Ry on the condition's own register; β: the
folded live incoming). R-1 needs neither: the clone **did not exist in the module `clang` produced**.
It is manufactured by `MergePhiPeel` ~90 lines before detection, it is `S.CondCmp->clone()` — the
same predicate, the same operands, the same `!dbg` — and its only consumer is the peeled select.
No source program can have passed it to the arm's `cq_theta`, so there is no rival for F2 to be
protecting against. F2's own docstring states its question as *"the source the author wrote could
have been `cq_theta(<that register>, θ)`"*; a value the author could not have named is not in the
question's domain. (And the weaker argument holds too: the clone is the same compare on the same
wire as `Region.Condition`, which is `CondWire`'s first element.)

**Implementation notes the implementer must not skip.**
* ⚠ The record must be **at the test, never at the anchor or at the users walk** — the same
  discipline, and the same reason, as the `CondWire` conjunct (`:1616`, with `ArmClassify.cpp:1611-1615`
  spelling out why): `V` is still popped and its users are still modelled, so the exclusion filters
  an answer and never prunes a seed. A pruned seed would change the walk and the step bound.
* ⚠ A raw `Value *` in a taint-set field is the **H-1 defect of l4x4.b**: the clone is erased by
  `lowerOps` / `SelectMergeEmit`. Use `WeakTrackingVH` (the structural fix l4x4.b landed) or clear
  the record where the clone is erased — and never let a freed pointer answer `count()`.
* ⚠ `peelIndependentMergePhis` is called before **all three** `detectControlRegions` sites
  (`CQLoweringPass.cpp:451/938`, `TaintPropagation.cpp:1430`) and F2 runs inside `classifyArms` in
  **both** rounds (L1). The record is written by the peel itself, so it is populated in both rounds
  by construction — but it must **not** be cleared between them, and a round-2 clone must be added,
  not assumed present.
* Cost: one `SmallPtrSet`/`SmallVector<WeakTrackingVH>` field, one insert, one conjunct.

**Retirement triggers** (R-1 inherits F2's own, at `ArmClassify.cpp:1283`: *if `railWireClosure`
as called by F2 ever diverges from R4's `CondRails`, re-derive from scratch*) **plus two of its
own**: (a) if `MergePhiPeel` ever inserts the clone anywhere other than
`S.MergeBB->getFirstNonPHI()`, clones anything other than `S.CondCmp`, or gains a second consumer
for the clone, the "no source preimage / same compare on the same wire" argument must be
re-derived; (b) if the peel is ever taught to run in-loop or to peel a φ whose incoming is itself a
compare, likewise.

### R-2 — `vd`'s collider: a SEPARATE increment with its own argument (file a new bd)

`vd`'s pinned `%9` **is** user code, so R-1's preimage argument does not reach it and must not be
stretched to cover it. The nearest shipped precedent is
`ir-pass/test/control_inplace_ry_reject_stateprep_second_flag_i1.ll`, which pins *"an `i1` seed
still collides with a tainted `i1` that is NOT on this branch's wire — a second, independent
compare's result"* as a **DECLINE**, with a rival stated in its header. Any R-2 must say precisely
how `vd`'s `%9` differs from that fixture's `%d`, and exactly one difference survives measurement:

* `…second_flag_i1.ll`'s `%d` is defined **before** the branch and is live and measured ⇒ the
  rival `r = cq_theta(%d, θ)` in the arm is a **well-formed program**;
* `vd`'s `%9` is defined **after** the branch, in the merge block, **and is the condition of a
  conditional `br`** ⇒ the rival that rotates it in place puts a non-diagonal gate between the
  compare and its own branch, which `condWireDisposition`'s 2c prong declines unconditionally.

So the R-2 spelling with an argument is **not** a position test (§3a kills that) but:
*a pinned value that is used as the condition of a conditional `br` in this function is not a
collider* — because the rival that would rotate it has no lowering, for a **structural** reason
that is itself a shipped fence, which is the 2026-09-11 α-form argument verbatim (*"where the rival
has a lowering, F2 still declines its folded image; where the narrowing removes the decline, the
rival has no lowering to be robbed of"*). It keeps `…second_flag_i1.ll` declining (`%d` is measured,
never branched on), it keeps the whole `range_forward_*` / `sideways_*` family declining (those
colliders are `add`/`sdiv`/`udiv` data values), and it closes `vd` and `r_R6b` while leaving
`r_R6a` (the same flag consumed as DATA) declining — which is the conservative direction.

⚠ **R-2's retirement trigger is live and near**: the day a tainted `i1` that is a branch condition
may be rotated in place and lowered — i.e. the day `condWireDisposition`'s prongs admit a
non-diagonal gate between a compare and its branch, which is the direction bd `xqgx`'s A.2
widenings point — R-2 becomes an **over-accept** and must be retired. Write that into the source,
not only here.

⚠ **R-2 needs its own measured rival audit before it is built** (the 2026-09-11 "32/32" shape:
every spelling of "rotate a value that is later a branch condition", each with its recorded
string), its own Rule-13 round, and — given that the owner's *current* file does not need it (§6)
— an owner decision on whether it is worth the trade at all. **Do not bundle it into R-1.**

---

## §3 HAZARDS (over-ACCEPT direction only)

### 3a ⚠ THE TRAP: "a collider must dominate the arm" is REFUSED BY MEASUREMENT

The tempting unification — both defective colliders are defined after the branch, so restrict the
forward half's test to values that could have been the arm's `cq_theta` operand — would **gut F2**.
The forward half exists *precisely* to reach post-branch values (its own comment at
`ArmClassify.cpp:1481-1490`: *"everything defined after the branch — which is where `-O1` schedules
the rotated register in the whole F-R3-1 family — is reached by the FORWARD half below instead"*).
Measured over the corpus:

```
grep -ln "state prep seed is proven equal" ir-pass/test/*.ll | wc -l      -> 27
```

and reading them, **at least 11 pin a collider defined in the MERGE block**: `range_forward_{add,
sub,or,xor,ashr,lshr}` (e.g. `%fwd = add nuw nsw i32 %t, 5` in `merge`), `merge_edge_sideways`
(`%t = sdiv i32 %q, 4` in `merge` — the drbq Inc-4 **flagship** value, the one F2's header records
as SIGSEGV-ing LVI), `sideways_offset`, `sideways_sdiv`, `offwire_sideways_min`, `step_cap_over`.
Those fixtures are the recorded findings of F2 rounds 2–3 (the "sideways rewrite" family). A
dominance conjunct flips all of them DECLINE→ACCEPT, i.e. **re-opens measured over-accept holes**.
Refuse it, and refuse it in writing, because it is the first idea anyone reading §1 will have.

### 3b Can R-1 admit a program whose UNPEELED twin declines?

No, for the accepted shape, and the argument is by construction: the peel is a **normaliser**, the
clone is `S.CondCmp->clone()`, and what R-1 excludes is exactly the value the peel added. The
unpeeled twin of a program whose only extra collider was the clone is `b_HP_f` / `b_P1` / `b_P1t` —
**all three ACCEPT on the ORACLE today**, so R-1 moves the peeled form *towards* its twin, not past
it. The direction is also inherently safe in the other sense: F2 only ever ADDS colliders, so
removing one can only turn a decline into an accept that the twin already has.

**The brief's sharper question — a clone of a DIFFERENT region's condition landing in this region's
candidate set — is real and R-1 survives it, but only just.** `MergePhiPeel` clones per peeled
region, so a function with two fused diamonds produces two clones; the second one IS a different
compare on a different wire, and it can be pinned on this region's edge (that is `vd`'s `%9` with
an extra peel in front of it). R-1 would exclude it too, which is **more** than "the same compare
on the same wire" licenses. It is still sound — the preimage argument covers every clone, because
**no** clone exists in the source module — but it means **R-1's argument must be stated as the
preimage one and NOT as the "same wire" one.** If a later reader grounds R-1 on "same wire", the
two-diamond case becomes an unlicensed accept. Stated here so the implementer writes the right
sentence in the source.

### 3c Which rivals are caught ONLY by F2 today?

Measured, the rivals in this family do not reach F2 at all: `w_W1` declines **F1**
(`state prep seed does not match the merge incoming` — note bd `rb9x` predicted
`condition data use neither escaped nor measured`; that is what `b_HP_b_orig.ll` gives, not the
plain-C spelling), and `w_W2`/`w_W3`/`w_W4`/`w_W5` all decline `control flow`. So for the programs
R-1 admits, **no rival loses its only decline**. ⚠ This is a measurement over 5 spellings, not a
theorem — the L5 lesson (a syntactic enumeration of what `-O1` does lost F2 four rounds running)
applies to any claim built on it, which is the second reason R-2 is filed rather than built.

### 3d The SINKING question, measured and left open

A dominance-style reading (and, more weakly, R-2's) depends on whether `-O1` can *both* fold the
arm's operand to a constant *and* sink the flag's compare below the branch. Measured on the one
spelling where the rival is writable in C (`w_W5`, the program `…second_flag_i1.ll` says it is
`-O1`'s image of): `clang -O1` does **neither** — the arm keeps `cq_theta_i1(i1 %2, …)` and `%2`
stays in the entry block. `w_W4` is more interesting: `-O1` deleted the compare altogether
(`%3 = xor i1 %1, true`) and rewrote the downstream guard to read the rail directly. **One
spelling, not a proof** — say it that way.

### 3e A finding the probes produced: the collider class reaches EVERY width through `zext`

`r_R4` was written to show the `i1` type filter and instead DECLINED: its
`%cz = zext i1 %clone to i32` is itself pinned to `i32 0` on the false edge and collides with the
`i32` seed `0` — the single most common seed in the corpus. `r_R4c` (the same module with the
`zext` removed) ACCEPTS, which isolates it. So "rb9x is a `_Bool` defect" is true of the **C
shapes measured** (`b_B`/`b_C` accept) and false as a general statement about F2: any pinned
flag that is zero-extended is an `i32` collider. ⚠ **And R-1 does not fix `r_R4`**, which is the sharpest consequence of putting the
exclusion at the TEST rather than at the seeding: the clone is still popped and its users are still
modelled (`ArmClassify.cpp:1611-1615` says so explicitly — *"it filters an answer, it does not
prune a seed"*), so the clone's `zext` remains pinned to `i32 0` and still collides. `r_R4` DECLINES
after R-1. That is the conservative direction and it is the right one (moving the exclusion to the
seeding would change the walk and the step bound, and would have to argue that every value DERIVED
from a clone is also preimage-free — it is not: `zext(cq.peel.cond)` has the same fold image as
`zext(<the user's own compare>)`). Recorded as a property of the set, and it is why a future
"exclude only `i1` values" spelling must be refused.

### 3f The `MergePhiPeel.cpp` comment — the corrected paragraph (for the implementer to paste)

`MergePhiPeel.cpp:454-469` currently carries a false clause plus a 2026-09-11 ERRATA that says so
and leaves the door unnamed. With R-1 landed it should read:

> MEASURED that the alternative is not equivalent: `h09c` (merge-placed) and `h09d` (pred-placed)
> BOTH accept at 22 lines and 2b-clean, and their TRACES DIFFER — pred placement emits the select's
> whole merge stream BEFORE the region's. Merge placement preserves source order (the region ran,
> then the mux was read).
>
> ⚠ MERGE PLACEMENT DOES **NOT** KEEP THE CLONE OUT OF THE drbq STATE-PREP FENCE, and the claim
> that it does (shipped until 2026-09-13) was false. `f2SeedPinnedByLiveRegister` has TWO halves;
> placement only moves the clone out of the **backward** one (`Cand` filters on
> `DT->dominates(&In, BI)`, `ArmClassify.cpp:1505-1510`). The **forward** half reaches it anyway:
> it walks every tainted USER of the condition's pinned operand rail with no position filter
> (`ArmClassify.cpp:1619-1626`), folds this clone to a singleton `i1` through
> `f2Model`'s `ICmpInst` arm (`:1198-1208`), and `:1616` then matches it against an `i1` (`_Bool`)
> seed — `true` on one edge, `false` on the other, so BOTH `i1` seeds collide. MEASURED:
> `HP_g_sel_only.ll` (this clone alone, merge-placed, no select) turns `HP_f_nopeel.ll`'s ACCEPT
> into F2's `state prep seed is proven equal to the condition register`; it is the PIN and not the
> spelling (`HP_d`: another predicate, `HP_e`: another constant — both decline). The repair is at
> F2's test, not here: the clone is recorded in `taint.PeelClones` below and excluded at
> `ArmClassify.cpp:1616`, on the ground that a value this pass MANUFACTURES has no source preimage
> and therefore no rival program for F2 to protect against (bd `rb9x`). Do not re-ground that
> exclusion on "the same compare on the same wire": a function with two fused diamonds produces a
> clone of the OTHER region's condition too, and the preimage argument — not the wire one — is what
> covers it.

---

## §4 DECLINE PARTITION after R-1 (what still declines, and where)

| program | today | after R-1 | after R-1+R-2 |
|---|---|---|---|
| `b_P2`, `b_P2t`, `b_A` (= bd `rb9x`: a `_Bool` prep under an `int` compare in a FUSED diamond) | F2 | **ACCEPT** | ACCEPT |
| `b_HP_{a,c,d,e,g}` (the hand-IR clone family) | F2 | **ACCEPT** | ACCEPT |
| `r_R1b`, `r_R5` (a second compare on the wire that is NOT a peel clone) | F2 | **F2** (unchanged — not a clone) | `r_R5`: F2 unless it is a branch condition |
| `r_R4` (`zext` of a pinned flag vs an `i32` seed) | F2 | **F2** — ⚠ the exclusion is at the TEST (`:1616`), so the clone is still POPPED and its users are still modelled: its `zext` is still pinned to `i32 0` and still collides | **F2** |
| `r_R4b` (post-branch `i32` pinned to the seed) | F2 | **F2** | **F2** |
| `…_second_flag_i1.ll` (a pre-branch off-wire `i1`, measured, never branched on) | F2 | **F2** | **F2** |
| `range_forward_*`, `sideways_*`, `merge_edge_sideways`, `step_cap_over` (≥11 fixtures) | F2 | **F2** | **F2** |
| `r_R6a` (a merge-block flag on the wire, DATA use only) | F2 | **F2** | **F2** |
| `r_R6b`, `v_vd` | F2 | **F2** | F2 gone → `control flow` (Track M's wall) |
| `w_W1` | F1 | F1 | F1 |
| `w_W2`/`w_W3`/`w_W4`/`w_W5` (the rivals) | `control flow` | `control flow` | `control flow` |

---

## §5 FIXTURES, SLICE, COST, ROUNDS

**Existing fixtures that FLIP under R-1 as specified (the record, consulted at the TEST): none.**
Measured — `grep -ln "state prep seed is proven equal" ir-pass/test/*.ll | wc -l` = **27**, and not
one of them is the `rb9x` shape (bd `rb9x` was filed, never fixtured). Two fixtures mention the
clone by name and both need a sentence:

* ⚠ **`control_peel_reject_fp_stateprep.ll` IS grounded on the clone — and it is the red-green
  witness that the exclusion must sit at the TEST and nowhere else.** Its header (lines 1-21) pins
  an fp data mux beside a state-prep arm as a DELIBERATE capability cost, and states the cause
  precisely: the peeled `select`'s condition `%cq.peel.cond` is exactly pinned, the select's fp
  RESULT is one `f2Model` cannot bound, so the conservative arm fires (`f2Model` returns
  `!AnyPinnedOperand` = false ⇒ `Truncated` ⇒ decline at `ArmClassify.cpp:1625-1627`). It is
  **NOT** a `:1616` seed collision — *measured in that header*: changing the seed `0`→`7` or the
  clone's literal to `99` declines identically. So R-1 at the test leaves it declining (the clone is
  still popped, the select is still modelled). **But R-1 spelled as pruning the clone from the WALK
  would flip it to an ACCEPT**: that fp select is reached ONLY as a user of the clone (`Cand` is
  integer-only and the branch is an `icmp`, so there is no fp anchor), and accepting an fp merge mux
  with no argument is the L9 angle-vs-data wire-crossing family. The fixture says in terms *"Do NOT
  'fix' F2 from here"*. Honour both: exclusion at the test, and add a RETIREMENT-TRIGGER line to
  that header naming R-1.
* `control_peel_stateprep_datamux_peeled_control.ll` HAND-WRITES `%cq.peel.cond` / `%cq.peel.mux`
  (it is the peel's output shape, pre-peeled, an ACCEPT control). Under spelling (i) it is untouched
  — a hand-written value is not in `taint.PeelClones`. Under any NAME- or structure-based spelling
  it would silently acquire the exclusion. That is a third, measured reason to refuse spelling (ii):
  the clone's *name* is reachable in the fixture corpus, and the record is not.

**New fixtures R-1 owes (Rule 12, red-green, the negative mirroring the string
character-for-character):**
1. ACCEPT — the `rb9x` shape as `-O1` produces it (`probes/b_P2_intcmp_i1seed_peeled.c`'s stage-1
   IR): an `int` compare condition, a `_Bool` prep φ, one peelable `int` φ. Full positive `CHECK`s
   for the stream (`cqrt_alloc_i1` + `cqrt_ry_i1_controlled` + the peeled mux's copies) plus the
   whole-file pure negative prefixes and the `ACNT/FCNT/XCNT/RYCNT/CCNT` counts, modelled on
   `control_inplace_ry_stateprep_bool_seed_int_cond.ll`.
2. ACCEPT — seed `true` (`b_P2t`), which is the other edge of the same collision.
3. DECLINE, kept — `r_R1b` / `r_R5`: a second tainted compare on the wire that is **not** a clone
   still collides. This is the fixture that stops R-1 from being silently widened into "any second
   compare".
4. DECLINE, kept — `…_second_flag_i1.ll` is already that fixture for the off-wire `i1`; add a
   RETIREMENT-TRIGGER header line pointing at R-1 (L8: those headers have been measured
   character-for-character correct once already).
5. The injection (mutation) matrix over the two new accepts (Rule 12 (c) and the `f8eu` debt
   pattern: an injected uncontrolled `cqrt_ry` on the CONDITION register after the flag's free).

**e2e slice.** `tests/e2e/slice_control_cascade_three_bools.c` = `probes/vd.c` is **NOT** R-1's
slice: `vd` still declines after R-1 (§4). R-1's slice is the `rb9x` program
(`b_A_intb0_boolb1.c`, `int b0` / `bool b1` / `int a`), and its golden can be composed from what is
already measured rather than guessed: `b_B_boolb0_intb1.c` (ACCEPT, 19 lines) and
`b_C_intb0_intb1.c` (ACCEPT, 22 lines) bracket it — the `bool b1` prep replaces `b_C`'s `int b1`
prep, so the expected stream is `b_C`'s 22 lines with the prep rail's `cqrt_alloc_i32(0)` /
`cqrt_ry_i32_controlled` becoming `cqrt_alloc_i1(false)` / `cqrt_ry_i1_controlled` and the `i32`
measure of `b1` becoming `cqrt_measure_i1` — i.e. **22 lines, same shape, `i1` widths on the b1
rail**. ⚠ Compose it, then MEASURE it on the subject; do not commit a composed golden unread.

**Cost.** R-1: one taint-set field + one insert + one conjunct + the comment rewrite of §3f; 2 new
accept fixtures, 2 kept-decline fixtures (one header-only), 1 e2e slice + golden, 1 injection
matrix. **1 Rule-13 round** is defensible *for R-1 alone* because its safety argument is the
preimage one (no rival enumeration), but budget **2** per Rule 13's measured hit rate — and the
second round's assignment should be exactly §3b (the two-diamond clone) and §3e (the `zext`
reach), which are the two places this scope is thinnest. R-2 is a separate increment with its own
bd, its own rival audit and its own rounds; do not fold it in.

---

## §6 THE M DEPENDENCY — measured, and it cuts the other way for the owner's current file

| program | ORACLE verdict | needs |
|---|---|---|
| the owner's file 2026-09-13 (`v_vd_two_regions.c`) | `control flow` at `select i1 %5, i32 %6, i32 %cq.peel.mux` | **Track M only** — F2 never fires on it |
| `vd.c` (three bools) | **F2** at the b0 theta | **Track M AND R-2** (R-1 does not touch it) |
| `vd` with the collider neutralised (`v_vd_guard_neg.c`, surgeries S1/S2/S3) | `control flow` at the same select | Track M only |
| the `rb9x` program (`b_A_intb0_boolb1.c`) | **F2** | **R-1 only** |

So: R-1 is independent of M and closes `rb9x`; `vd` is behind M *and* a second narrowing that is
not yet argued. Per the brief §6, when the orchestrator hands over Track M's branch binary and
hash, measure `vd.c` on it ONCE (`probes/run.sh` with `BUILD` pointed at M's worktree) and append
the row here — the prediction from the surgeries is `state prep seed is proven equal …` **still**,
with M's wall gone, which would make it the cleanest possible demonstration that `vd` needs R-2.
