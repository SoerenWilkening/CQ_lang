# REVIEW — Track F, adversarial round 1 (Rule 13), bd `om35`: the φ-DESCENDANT conjunct in F2

**Reviewer:** independent; did not write the code. **Date:** 2026-09-14.
**Subject:** `/Users/sorenwilkening/Desktop/CQ_f2phi`, branch `f2-phi-descendant`, tip
`baad186d45a4cc843c8717da70be3f8e1f7f6bab` (verified, `git rev-parse`), working tree CLEAN.

## 0. FIRST ACT — binary hashes

```
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_f2phi/build/ir-pass/cq-opt
  147cb3d69afd816d15eaea84e3d802f3a5b4105431508886583b442bfa7736e4   MATCHES brief
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
  f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc   MATCHES brief (ORACLE)
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so
  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d   MATCHES brief (ORACLE)
```

All three match. No build, no suite, no corpus sweep was run. Every `.ll` generated below had its byte
size printed before it was measured (`review_r1_probes/run.sh` refuses a 0-byte module) — the SCOPE_F
erratum's trap was defended against mechanically, and one of my own probes (`p9` first attempt) was
caught malformed by it and rebuilt.

---

## VERDICT: **CLEAR-WITH-ITEMS**

The increment does what it says on every shipped and reachable input I measured, and I independently
reproduced its headline numbers. One finding (**F-F1-1**) falsifies the stated ground by construction
on a shape that is declined *today only by an unrelated fence the roadmap is actively removing*. It is
not an over-accept on any input I could reach, so the verdict is not NOT CLEAR — but the fix is two
lines with measured-zero cost and should land before the merge.

---

## 1. What I verified independently (Rule 11 — not restated from `IMPL_F.md`)

| claim | my measurement | verdict |
|---|---|---|
| the F2-declining family does not move | **33** fixtures whose text names F2's string, run through BOTH binaries: exit code + diagnostic compared. **0 MOVED** (`review_r1_probes/f2family.txt`) | **confirmed** |
| no shipped fixture moves | **169** fixtures (`control_peel_*` ∪ `*stateprep*` ∪ `*state_prep*`, de-duplicated) through both binaries, comparing exit code, diagnostic **and the lowered IR byte-for-byte** on accepts. **1 mover: `control_inplace_ry_stateprep_phidesc_collider_accept.ll`, the fixture this increment added** (`review_r1_probes/peel_stateprep_family.txt`) | **confirmed, and stronger than the implementer's own run** (they compared exit+string; I compared lowered IR) |
| the four `Truncated` decliners are unmoved | `step_cap_over`, `unfoldable_curated_call`, `unevaluable_pinned_operand`, `control_peel_reject_fp_stateprep` all SAME in the 33-run | **confirmed** |
| the committed slice | full pipeline by hand on the SUBJECT build: `opt` exit 0; STRICT stage 2b `9 rail mint(s) of which 7 left allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven`; **35** trace lines; `diff` against `slice_control_cascade_three_bools.expected.log` → **BYTE-IDENTICAL** | **confirmed** |
| the fixture pair | `nonphidesc_collider` DECLINES on both binaries with F2's string; `phidesc_collider_accept` DECLINES on the ORACLE with F2's string and ACCEPTS on the SUBJECT | **confirmed** |
| the accept fixture's checks | all 8 prefixes (`CHECK`, `NOF2`, `ACNT`, `FCNT`, `XCNT`, `RYCNT`, `CCNT`, `CNCNT`) FileChecked by hand against the SUBJECT's real output: all green. Counts verified against the stream I read (10 alloc / 3 free / 4 x / 4 ry / 2 ry_controlled / 4 cnot). One `opt` spawn reused across 7 prefixes | **confirmed; hygiene good** (pure negatives, counts each in their own whole-file prefix — Rule 12(a) respected) |
| both new fixtures are unique bodies | sha-256 over non-comment, non-blank lines of all 1930 fixtures: both new files are in groups of size **1** | **confirmed** |

**Rule 2 — I read the emitted stream, not the exit code.** The slice's 35 lines decompose exactly as
the source does: unconditional `alloc_i1(0); ry(h0,.5)` for `b0`; the `a`-mux as the rail-root CNOT-copy
select merge on ancilla `h1` (`x`-bracketed, `cnot`-returned, freed at a proven `|0⟩`); the `b1` arm as
the **negated-control additivity** pair `ry_i1(h5,.5); ry_i1_controlled(h0,h5,-.5)` (correct for a
false-successor arm); the second `a`-mux with the chain hoisted **unconditionally on the original
register** (`cq_template_add_i32_hl(h2,-3)`, Rule 7 value arm) and a second ancilla `h7`; then
`icmp_sgt_i32_hl(h8,2) → h9`, the controlled state prep `ry_i1_controlled(h9,h10,.5)`, the compare
`_unc` and `free(h9)`. `h0`/`h5` are read only as controls and are never `cqrt_x`-bracketed. No new
emitter runs — the conjunct only decides *whether* the already-cleared emitters run.

---

## 2. THE PRIMARY ASSIGNMENT — can `-O1` rewrite a non-φ-dependent source value into a φ-dependent module value?

### 2a. Answer for the ACYCLIC case: **NO**, and it is a structural argument, not "I could not build one"

The question decomposes into two facts about what `-O1` can do at all:

1. **No pass rewrites an existing SSA value's definition to take an operand that does not dominate that
   definition.** Doing so produces invalid SSA. So a value that exists before the region **cannot
   acquire a use of `M` in place**, at any optimisation level, by any transform.
2. **The transforms that *create* `M`-users create NEW values whose operands are the pre-existing
   ones.** The pre-existing operands survive as separate SSA values unless they become dead or are
   absorbed. In particular **sinking — Rule 9's own named mechanism — moves a definition but never
   changes its operands**, so a sunk value is *not* an `M`-user. That is precisely why the ≥11 shipped
   merge-block-collider fixtures (`range_forward_*`, `sideways_*`, `merge_edge_sideways`,
   `offwire_sideways_min`, `step_cap_over`) stay declines under this conjunct while a raw dominance
   conjunct would flip them — and it is the reason the shipped predicate is **not** the refused one.

Therefore the only residual is **ABSORPTION**: the author's register `W` is folded into a newly created
`M`-user and deleted (e.g. `(x+C1)+Mdesc` reassociated to `(x+Mdesc)+C1`, killing `W`). But absorption
**removes `W`'s pinned value from the module**, so the ORACLE has no witness either — the conjunct is
not what turns such a program into an accept.

I measured an instance of the absorption family, and it is **pre-existing and identical on both
binaries**:

* `review_r1_probes/c/p3_armlocal_rival.c` — `int q = cq_theta(0,0.3); int r = 0; if (q == -7) { int w
  = q + 7; r = cq_theta(w, 0.5); }`. The author wrote an in-place Ry on `w`'s rail. GVN's
  `propagateEquality` folds `w` to `0` inside the arm and deletes it, and the module is exactly the
  state-prep module. **ORACLE exit 0, SUBJECT exit 0, lowered IR identical (4510 bytes each).** F2's
  witness-based design already misses this rival; the increment neither creates nor widens it.

### 2b. The two named thinnest places, attacked in plain C

**Sideways / downward compare rewrite** — `review_r1_probes/c/p4_sideways_guard.c`. The third guard is
written in the source against the **pre-region-2** register (`int pre = a;` … `if (pre >= 3)`), the
shape that would have to be moved onto the post-region value to become a φ descendant. Measured: `-O1`
did the **opposite** — it folded the guard *downward onto an ancestor*, all the way to the region's own
condition register `%1`, and materialised `pre` as a φ over the *later* region's blocks
(`%9 = phi i32 [ 5, %6 ], [ 2, %4 ]`). Both binaries **exit 0**, identical 7860-byte output. The
sideways/downward family canonicalises toward **ancestors**, i.e. out of the φ cone and into
`CondWire` — the safe direction. This is one measured instance, not a proof over the family.

**Jump threading** — `review_r1_probes/c/p5_jumpthread.c` / `p5b_jumpthread.c`. JT resolves a branch by
*specialising a φ away*; when it fires it **removes** `M`-uses and, in the region shape here, would
delete the region's φ outright (the merge would lose a predecessor and fold). I could not construct a
threading that adds an `M`-use, and fact (1) above says why none can exist. I did not get JT to fire on
these probes (they declined at `control flow` / `rotation arm shares the condition flag` before
reaching F2), so this half is a **structural argument with a failed empirical attempt**, not a measured
negative — label it as such.

### 2c. Answer for the CYCLIC case: **YES — and I built it.** See F-F1-1.

---

## 3. Findings

### F-F1-1 — the AVAILABILITY ground is FALSE for a back-edge φ; the conjunct drops a collider that IS available at both slots. **Severity: latent over-ACCEPT / falsified ground. MUST-FIX (or MUST-TRIGGER) before merge.**

**Claim.** `collectStatePrepPhiDescendants` (`ArmClassify.cpp:1522-1548`) walks `V->users()` with **no
dominance filter**. A **loop-header φ that takes `M` on the BACK EDGE** is therefore in `PhiDesc` — and
such a φ **dominates the arm block and the pred edge**, i.e. it is available at *both* of F2's two
slots. The header comment's two bullets ("`M` does not dominate the arm block"; "spelling `V` there is
use-before-def") are theorems only for an **acyclic** user chain. They are false the moment the chain
crosses a back edge, because a φ's use of `M` is on the *edge*, not at the φ's definition point.

**Probe — a measured MOVER.** `review_r1_probes/p8_backedge_phidesc.ll` (hand IR, 1466 bytes). `%v` is a
loop-header φ, `[ false, %entry ], [ %carry, %join ]`, where `%carry = icmp sgt i32 %s, 2` and
`%s = select i1 %m, i32 1, i32 %k` reads the region's own merge φ `%m`. `%v` is tainted, is in `Cand`
(it dominates the branch), is pinned to `false` = the seed, **and is in `PhiDesc`**.

```
$ ORACLE  cq-opt … -S p8_backedge_phidesc.ll
  exit=1  cq controlled lowering: state prep seed is proven equal to the condition register
$ SUBJECT cq-opt … -S p8_backedge_phidesc.ll
  exit=1  cq controlled lowering: control flow inside a loop body
(CQ_CTRL_DBG=1 confirms the same anchor `%c = icmp eq i32 %q, 7` on both.)
```

F2 **fired on the ORACLE and did not fire on the SUBJECT**. The module still declines, but on an
*unrelated* fence.

**Mutation control that isolates the cause.** `review_r1_probes/p8c_backedge_nonphidesc.ll` is the same
module with one operand changed so the carried φ's back-edge incoming reads `%k` (condition-derived)
instead of `%m`: **BOTH binaries decline with F2's string.** So the value is still a collider when it is
not a φ descendant; the conjunct is exactly what moved `p8`.
`review_r1_probes/p8b_nocollider.ll` (the carried φ deleted) shows the same move one level down, on
`%carry` itself.

**Why it is not an over-accept today, and why that is fragile.** For a φ to use `M` *and* dominate the
arm requires a cycle (I checked: in an acyclic CFG, "V's block dominates Pred" plus "M's block is a
predecessor of V's block" plus "Pred dominates M's block" is contradictory). Every in-loop state prep is
declined today: I measured `control flow inside a loop body` (p1c, p8) and
`condition predates a non-diagonal gate` (p1b) on both binaries, and `CLAUDE.md` records bd **`wx8g`**
— *"Grover as a rolled loop with a bool-controlled rotation or prep compiles in NO spelling on ANY
binary"* — as an **open over-decline the owner's 2026-09-11 ruling says is a defect to remove**.
Critically, `ControlDetect.cpp:632-666` shows in-loop regions **do reach `classifyArms`**; the loop is
not a blanket fence, only the prep shape is currently stopped. **The day `wx8g` lands, this becomes a
live over-accept, and nothing in the source says so** — the two retirement triggers written
(`f2Model`'s `SelectInst` union; `railWireClosure`-vs-`CondRails`) do not name it.

**Minimal fix (2 lines, measured zero cost).** Narrow the *exclusion set* — which can only ever ADD
declines relative to the subject, so it is not the refused dominance conjunct (that one tests colliders
against the ARM; this tests members against `M` itself):

```cpp
// in collectStatePrepPhiDescendants, add `const DominatorTree *DT` (non-null by the
// guard at :1571) and, inside the users loop:
if (isa<PHINode>(I) && !DT->dominates(MergePhi->getParent(), I->getParent()))
  continue;   // a phi that takes M only on a BACK EDGE is available at the slots
```
Measured cost on the customers: **zero** — every φ-descendant in the owner's file, `vd.c`,
`w3_runtime_a.c`, `n4_cascade.c` and both new fixtures lives in a block dominated by `M`'s block.
Commit `p8` and `p8c` as a fixture pair (`…_reject_stateprep_backedge_phidesc_collider.ll` +
its non-φ twin) with an L8 retirement-trigger header naming `wx8g`.
**If the owner prefers not to change code:** the acceptable alternative is the trigger + the fixture
pair, so the day `wx8g` lands the pair goes red instead of going silent. What is *not* acceptable is
shipping the availability paragraph as a theorem with no tripwire — that is the L5 shape exactly.

---

### F-F1-2 — the ground as SUMMARISED is the refused dominance argument. **Severity: documentation (L7 shape).**

`REVIEW_BRIEF_F_R1.md` and `IMPL_F.md` §2 compress the ground to *"the φ is defined at the join, so a
value using it is available at neither slot"*. That sentence is **position**-based, and position-based
is exactly the conjunct that was REFUSED IN WRITING — and it is false, because `-O1` **sinks**: the ≥11
shipped merge-block colliders are also "defined after the join" and are genuine rivals precisely because
their *position* is a consequence of the fold, not evidence about the source.

The load-bearing step is the **operand** one, and only the source header states it correctly (for the
pred slot): *"a φ incoming must dominate its incoming EDGE … spelling `V` there is use-before-def, i.e.
not a module at all."* The distinction is what makes the conjunct immune to sinking. Since the
orchestrator will carry this paragraph into `CLAUDE.md`, the compressed form must not be the one that
travels.

**Minimal fix:** in `IMPL_F.md` §2 and in whatever lands in `CLAUDE.md`, state the ground as
*"`V`'s OPERAND `M` is not available at either slot, so `V` cannot be SPELLED there in any module —
this is not 'V sits after the join', which is the refused conjunct and which sinking defeats"*, and
carry the acyclicity precondition from F-F1-1.

---

### F-F1-3 — MERGE-GATE COMPOSITION with Track U: an `undef` seed is refused at **F1** today, so Track U hands F2 a population it has never been asked about. **Severity: merge-gate item; unmeasured composition.**

**Measured.** `review_r1_probes/p9_undef_seed.ll` is `control_inplace_ry_stateprep_phidesc_collider_accept.ll`
with the seed spelled `undef` in the theta arg-0 and in the φ's pred incoming:

```
ORACLE  exit=1  cq controlled lowering: state prep seed does not match the merge incoming
SUBJECT exit=1  cq controlled lowering: state prep seed does not match the merge incoming
```

F1 (`!isa<ConstantInt>(RotBase) && !isa<ConstantFP>(RotBase)`, `ArmClassify.cpp:~4006`) refuses it
**before F2 is reached**, on both binaries. Track U (bd `z9t1`) normalizes an `undef` seed to a concrete
zero *before classification* — which turns `p9` into the accept fixture byte-for-byte. So on the merged
binary **`p9` goes DECLINE(F1) → ACCEPT**, a transition **neither track's own corpus sweep can observe**,
because each measured against the 59ac5b7 ORACLE with the other track absent.

**What the merge gate must run:** `p9_undef_seed.ll` on the COMBINED binary, plus the undef spelling of
each Track-F customer (`owner_undef_spelling` already exists as a trace in the implementer's probes).
The question to answer in writing is *"does a normalized zero seed make a φ-descendant collision
reachable that was not before?"* — the answer is **yes, by construction**, and what remains is whether
any such program is a genuine rival. Note also that the implementer deliberately committed the
**initialised** spelling of the slice for exactly this reason (`IMPL_F.md` §5), which is the right call
and means the golden will not catch the composition either.

**Track P (bd `3qps`/`4aiu`):** I see no semantic collision. Track P widens the φ **leaf grammar** for
the kickback classifier / `SelectClassify`; Track F narrows the **collider** set inside the state-prep
F2 block. The sets are keyed differently (`Region.Condition`'s backward cone vs `Region.Merge`'s forward
cone) and are disjoint by construction. The composed effect is nevertheless *more exclusions ⇒ more
accepts*, so the merge gate should name a probe where a state prep's condition is another region's
merge φ (Track P's new leaf) and the collider is this region's own φ (Track F's exclusion), and check
the combined verdict. I did not build one — I measured the Track F binary only, as instructed.

---

### F-F1-4 — *"It does not touch `Truncated`"* is imprecise. **Severity: documentation.**

The conjunct suppresses an early `return true`, so the walk **runs strictly more steps** and can now
reach `kF2MaxSteps` or an `f2Model` failure where it previously returned first. A TEST decline can
therefore become a `Truncated` decline. The direction is safe (decline → decline, same string), and the
claim is *true of the four named `Truncated` fixtures* (verified unmoved), but as written it invites a
future reader to assume the walk is unchanged — and `p8`'s SUBJECT run is a live example of the walk
continuing past a value the ORACLE stopped on. **Fix:** one clause — *"it can only convert a TEST
decline into a `Truncated` decline, never the reverse, because excluding a value removes an early
return and never removes work."*

---

### F-F1-5 — the L1 answer proves RECOMPUTATION, not STABILITY; the drift direction is the ACCEPT direction. **Severity: unproven residual → round 2.**

`IMPL_F.md` §3 says *"There is no record … so both rounds are correct by construction."* That
establishes the set is rebuilt in round 2; it does **not** establish that the round-2 set is the same as
or smaller than the round-1 set, and the implementer names this residual themselves without naming its
direction. The direction is the unsafe one: round 1's emission **RAUWs** (`emitInPlaceRotationRegion`'s
M-β rewrites the merge φ to the theta CALL; `SelectMergeEmit` rewrites the merge to the `%out` handle),
and a RAUW substitutes a possibly **deeper** value for a former user, so a round-2 region's `PhiDesc`
can only **GROW** — and growth of an *exclusion* set is the accept direction.

I could not construct a reachable instance: it needs a region **B** classified only in round 2 whose
merge φ dominates a round-1-emitted region **A**'s arm theta, with B undetected in round 1. I did not
build the pass, so this is analysis only. It is the exact L1 "PREDICATE species" shape (a predicate
asked over a graph a later round falsifies) and belongs on round 2's assignment.

---

### F-F1-6 — duplicate-body count disagreement. **Severity: record hygiene (minor).**

My scan (sha-256 over each fixture's non-comment, non-blank lines, all 1930 files) reports **8**
duplicate-body groups; `IMPL_F.md` §8 reports **9**. Both new fixtures are unique (group size 1) in my
scan, which is the load-bearing part and agrees. The delta is almost certainly a normalisation
difference (I strip blank lines). Flagged only so the two numbers are not later quoted as if two
independent measurements agreed.

---

## 4. Things I checked that are NOT findings

* **`Region.Merge` cannot reach F2 as a φ of something else.** `classifyArms` `dyn_cast_or_null<PHINode>`s
  `Region.Merge` at its first statement (`:3316`) and declines `control flow` otherwise; F1 reads the
  defended seed off that same object; the arm theta is
  `inPlaceRotationArmTheta(MergePhi->getIncomingValueForBlock(ArmBB), …)`. One φ, one region. The
  helper's `dyn_cast_or_null` fallback (empty set ⇒ no exclusions) is the conservative direction.
* **Over-approximation direction of the transitive USER closure** (brief item 1). `PhiDesc` is a strict
  superset of "semantically depends on `M`" (e.g. `and(Mdesc, 0)`, or a `select` merging a φ-dependent
  and a φ-independent operand). Every such member is still **defined after `M` by SSA dominance** in the
  acyclic case, so each individual exclusion is licensed by the ground even though the set
  over-approximates. The safety does **not** rest on semantic dependence — worth saying, because it is
  what makes the unpruned walk harmless. `p7b_select_mix.c` was written for this and `-O1` folded it
  away (`mixed` became the constant 2) — a vacuous probe, reported as vacuous.
* **`Out.insert(MergePhi)` (the φ itself).** `M` is never in `Cand` (it does not dominate `BI`) and
  `f2Model` unions a φ's incomings, one of which is the unpinnable theta result, so `M` is never pinned
  to the seed. The insertion is inert, not wrong.
* **`MergePhiPeel` cannot add or remove `PhiDesc` members.** The peel only fires on φs whose incomings
  are all pred-available, and `M` is not pred-available, so a peeled φ is never an `M`-user; the select
  it manufactures has pred-available operands, so it is not one either. The `rb9x` clone exclusion and
  this one are disjoint.
* **Non-vacuity of the boundary marker** (brief item 2). `review_r1_probes/mA_nonphidesc_depinned.ll` —
  `control_inplace_ry_reject_stateprep_nonphidesc_collider.ll` with `icmp sgt %2, 2` → `sgt %2, 1`, so
  the collider is pinned to `true` instead of the seed: **both binaries ACCEPT (exit 0, identical
  2186-byte output)**. So the fixture's decline is F2's **TEST** on the pinned collider, not
  `Truncated`. The negative is real.
* **The disclosure paragraph** (brief item 5). For the programs that now compile, the claim is correct:
  each excluded collider is use-before-def at both slots, so the rival has no module and no lowering to
  be robbed of. The **universal** form — *"there is no source the user could have written whose circuit
  they are now silently denied"* — is overstated and must be scoped to acyclic regions (see F-F1-1).

---

## 5. What I did NOT examine

* **I ran no build, no `ctest`, no `lit`, and no corpus sweep** (PROTOCOL reviewer row; the box is
  loaded). My 33- and 169-fixture runs are per-probe pipeline invocations of the two existing binaries,
  not a sweep of the 2086-module corpus — **1761 of the 1930 shipped fixtures were not run by me**, and
  for those I rely on the implementer's `ir-pass-lit` (Passed, 1930) and their sweep.
* **I did not verify the implementer's injection matrix** (12 mutations, MISSED 0). I ran three
  mutations of my own (mA, p8c, p8b) and all behaved correctly.
* **I did not enumerate `-O1`'s pass list.** §2a is a structural argument plus nine measured probes, not
  an exhaustive proof. I did not attempt targeted GVN-PRE, LICM, SROA or SimplifyCFG-sink constructions
  beyond those named.
* **I measured the Track F binary only** — no combined binary, so F-F1-3 is a prediction from a measured
  single-track fact (`p9` declines at F1 today), not a measured composition.
* **I did not run the e2e slice through `ctest`**, only the hand pipeline (which is the same four stages
  plus the golden `diff`).
* **I did not examine** the `angle_select`/`inplace` twin matrices, the loop twin matrix, or
  `cq-opt-equivalence`. The increment changes a decline/analysis site, so `cq-opt-equivalence-full` is
  owed at the merge gate per PROTOCOL.

---

## 6. Round 2 — WARRANTED

Rule 13's measured hit rate (F2 lost four consecutive rounds; 3qlq's C-1 family took eight findings over
six rounds) plus three live reasons:

1. **F-F1-1's fix needs its own review** — a narrowing of the exclusion set is a Rule-13 core change and
   must be re-measured against the 33/169 families and the four customers.
2. **F-F1-5 is unresolved by analysis alone** and is the L1 PREDICATE species, which has hit this
   project three times.
3. **F-F1-3's composition is unmeasured** and cannot be measured until the merged binary exists.

Round 2's assignment should be set from these three, not pre-committed further.

---

## 7. Probe index — `$SES/trackF/review_r1_probes/`

| probe | what it is | ORACLE | SUBJECT |
|---|---|---|---|
| `run.sh` | the runner; prints every generated `.ll`'s byte size and aborts on 0 | — | — |
| `f2family.txt` | 33 F2-string fixtures, both binaries | — | 0 MOVED |
| `peel_stateprep_family.txt` | 169 peel/stateprep fixtures, lowered-IR byte diff | — | 1 mover (own) |
| `c/p1_inloop_prep.c` | in-loop prep, classical guard | accept | accept (region optimised away — vacuous for the question) |
| `c/p1b_inloop_prep_qguard.c` | in-loop prep, loop-invariant quantum guard, carried bool | `condition predates a non-diagonal gate` | same |
| `c/p1c_inloop_prep_invariant_cond.c` | in-loop prep, in-body chained condition | `control flow inside a loop body` | same |
| `c/p2_absorb_reassoc.c` | absorption via reassociation | `operand predates a non-diagonal gate` | same |
| `c/p3_armlocal_rival.c` | **the arm-local rival — F2's PRE-EXISTING blind spot** | exit 0 | exit 0, identical IR |
| `c/p4_sideways_guard.c` | **sideways/downward compare rewrite** | exit 0 | exit 0, identical IR |
| `c/p5_jumpthread.c`, `c/p5b_jumpthread.c` | jump threading | decline | same |
| `c/p7_select_mix.c`, `c/p7b_select_mix.c` | φ-dependent ∪ φ-independent operand | — | vacuous (`-O1` folded it) |
| `p8_backedge_phidesc.ll` | **F-F1-1 — the back-edge φ** | **F2 fires** | **F2 does not fire** |
| `p8b_nocollider.ll` | same, collider φ deleted | F2 fires | loop fence |
| `p8c_backedge_nonphidesc.ll` | **the isolating control** — back-edge φ NOT reading `M` | F2 fires | **F2 fires** |
| `p9_undef_seed.ll` | **F-F1-3 — the Track U composition witness** | F1 decline | F1 decline |
| `mA_nonphidesc_depinned.ll` | **non-vacuity of the boundary marker** | exit 0 | exit 0 |
| `mB_phidesc_depinned.ll` | its twin, de-pinned | exit 0 | exit 0 |
| `slice3.*` | the committed slice, full hand pipeline | — | golden byte-identical, 2b 9/7/3 verified |
