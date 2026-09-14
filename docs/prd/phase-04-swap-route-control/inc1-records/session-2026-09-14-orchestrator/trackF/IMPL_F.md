# IMPL — Track F: the φ-DESCENDANT exclusion in F2 (bd `om35`, owner-ruled 2026-09-14)

Worktree `/Users/sorenwilkening/Desktop/CQ_f2phi`, branch `f2-phi-descendant`, off `main` 607b6fe4.
Every gate line is in `GATES.md`, hash-keyed. Rule 19: only what was run is reported, with the
command. The ORACLE (`/Users/sorenwilkening/Desktop/CQ_lang/build`) was re-hashed before every use
and never rebuilt.

```
SUBJECT  build/ir-pass/cq-opt        96fdd3a9d2c1cd36deb607f0440db0157280a7784a7766bdce04044cd3234cd1  <- POST-FIX (round 1)
SUBJECT  build/ir-pass/libCQPass.so  9537a0ce0c56548e3cc27f273a15a84995ce21dd7754d608d160e064fd9ad68e
PRE-FIX  build/ir-pass/cq-opt        147cb3d69afd816d15eaea84e3d802f3a5b4105431508886583b442bfa7736e4  <- the REVIEWED binary
PRE-FIX  build/ir-pass/libCQPass.so  70d474d2971fd0192412c213f037e85ed14a57854518084a94e1b05ea46bff16
ORACLE   build/ir-pass/cq-opt        f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc
ORACLE   build/ir-pass/libCQPass.so  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d
```

⚠ **THIS FILE HAS BEEN THROUGH ROUND-1 ADVERSARIAL REVIEW (`REVIEW_F_R1.md`, CLEAR-WITH-ITEMS) AND A
FIX ROUND (`FIX_F_R1.md`).** Read `FIX_F_R1.md` for the six dispositions; the sections below are
corrected in place, and every gate line moved to `GATES.md`'s fix-round table. **Every gate result
recorded against `147cb3d6…` is VOID for `96fdd3a9…`** and is labelled `cited:` there.

---

## §0 HEADLINE

The owner's `example/grover/grover_oracle_uncompute.c` with the third region live **compiles**:
`opt` exit 0, stderr 0 bytes, **35 trace lines**, STRICT stage 2b
`9 rail mint(s) of which 7 left allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven`,
committed as `tests/e2e/slice_control_cascade_three_bools.c` + golden and green as
`e2e-slice-control-cascade-three-bools`. **All 29 fixtures that decline with F2's string still
decline — MOVED 0**, which was the predicted cost and is now the measured one. The increment is one
conjunct, one local helper, one set built once per call; no pre-existing signature changed, no shared
helper was refactored, and nothing outside `ArmClassify.cpp`'s F2 block was touched.

⚠ **ROUND 1 OF ADVERSARIAL REVIEW RETURNED CLEAR-WITH-ITEMS WITH ONE MUST-FIX, AND IT HAS LANDED.** The
availability ground was falsified by construction on a **back-edge φ** (F-F1-1) and the helper now
narrows the exclusion set to φ users that `M`'s block dominates; the ground is restated as an OPERAND
argument (F-F1-2); the `Truncated` claim is restated precisely (F-F1-4); the duplicate-body count is
reconciled (F-F1-6); **F-F1-5 is OPEN and is round 2's assignment**, and F-F1-3 is the merge gate's.
All of it is in `FIX_F_R1.md`. The shipped binary is `96fdd3a9…`, not the reviewed `147cb3d6…`.

⚠ **It also contains an ERRATUM against my own scoping (§7). Six of `SCOPE_F.md`'s measurements
were VACUOUS** — `sed X.s1.ll > X.S1.ll` on a case-insensitive filesystem is a read-and-write of
*one* file, which truncated it to 0 bytes, and an empty module accepts. The conclusions survive;
two sentences of §3b/§3c do not, and one of them is now known to be false.

---

## §1 THE CONJUNCT, AS SPELLED

`ir-pass/src/ArmClassify.cpp`, at F2's **TEST** (the single site where `CondWire` and
`Taint.isPeelClone` are consulted), one more conjunct:

```cpp
      if (V->getType() == Seed->getType() && !CondWire.count(V) &&
          !Taint.isPeelClone(V) && !PhiDesc.count(V) && f2Exact(V, S) == Seed)
        return true;
```

`PhiDesc` is built ONCE per call, before the edge loop and before `Cand`, by a new file-local
helper in the same anonymous namespace:

```cpp
void collectStatePrepPhiDescendants(const Value *Merge, const Function *F,
                                    const DominatorTree &DT,
                                    SmallPtrSetImpl<const Value *> &Out);
```

— the transitive SSA **user** closure of `dyn_cast_or_null<PHINode>(Region.Merge)`, seeded with the
φ itself, filtered to this function **and to φ users that `M`'s block dominates**. Called as
`collectStatePrepPhiDescendants(Region.Merge, F, *DT, PhiDesc);`.

**⚠ THE `DT` PARAMETER IS THE ROUND-1 FIX (F-F1-1), NOT PART OF THE ORIGINAL SPELLING.** Inside the
users loop:

```cpp
      if (isa<PHINode>(I) && !DT.dominates(MergeBB, I->getParent()))
        continue;
```

A φ is the one opcode whose operand need only dominate its incoming EDGE, so a **loop-header φ taking
an `M`-descendant on its BACK EDGE** was landing in the set while DOMINATING both of F2's slots — i.e.
it was exactly the available collider §2's bullets say cannot exist. It is a **NARROWING of the
EXCLUSION set** (only ever adds declines), which is the opposite object and the opposite direction from
the refused dominance conjunct (which tests a *collider* against the *arm* and turns declines into
accepts). It is a no-op on every non-φ user — for those, SSA already puts the user in a block dominated
by `MergeBB` — and it makes "every member is in a block dominated by `MergeBB`" an **invariant of the
set** rather than an unstated premise about the input. `DT` is non-null at the call site by the guard
immediately above it, which declines rather than narrowing the question silently. Full disposition and
the three-binary measurements: `FIX_F_R1.md` F-F1-1.

**Three deliberate spelling choices, each with its reason:**

* **No signature change and no call-site change.** `CondWire` is built at the call site because it
  must call R4's own `railWireClosure` on R4's own seeds (Rule 14 sharing). This set has no such
  obligation — it is a pure function of `Region.Merge` — so it is computed where it is used. That
  also makes the edit as small as it can be, which matters for the Track P merge (§9).
* **A local walk, not a reused one.** Rule 14 asked and answered in the source:
  `RotationLowering.cpp`'s `collectDescendantRecords` is **not** this walk — it follows only
  `CallInst` record producers and copy-gate SRC→DST edges, a *rail* relation. Sharing one helper
  would mean widening a Rule-13 rail fence to answer a question about plain SSA.
* **No record in `TaintSet`.** R-1 needed one because only `MergePhiPeel` knows what it
  manufactured. Here there is nothing to record and nothing to go stale (§3).

## §2 THE ARGUMENT — availability, and it is an **OPERAND** argument, not a position one

**⚠ CORRECTED IN ROUND 1 (F-F1-2). The earlier compression of this section — *"the φ is defined at the
join, so a value using it is available at neither slot"* — WAS THE REFUSED DOMINANCE ARGUMENT wearing
the availability label, and it is FALSE, because `-O1` SINKS.** The load-bearing step is the OPERAND
one. The corrected paragraph, which is the one that travels into `CLAUDE.md`, is verbatim in
`FIX_F_R1.md` §CG; this section is its long form.

F2's question is *"the source the author wrote could have been `cq_theta(<that register>, θ)`"*, and
the register it asks about can occupy exactly **two** slots of the module in front of it: the ARM
theta's arg-0, or the merge φ's PRED-edge incoming. The φ `M` is defined **at the join**, so **`M` is
not available at either slot** — and therefore any `V` whose OPERAND CHAIN reaches `M` **cannot be
SPELLED at either slot, in any module**:

* not at the **ARM** slot — `M` does not dominate the arm block (the arm is a *predecessor* of `M`'s
  block), so an operand chain through `M` cannot be written there;
* not at the **PRED** slot — a φ incoming must dominate its incoming edge, and `M`'s block does not
  dominate `Pred`; spelling `V` there is use-before-def, i.e. not a module at all.

A value whose operands did not exist yet at either slot is not a register the author could have named
**in the definition of `M` itself**. It is outside the question's domain, exactly as R-1's manufactured
clone is — and for a *stronger* reason, because R-1's ground is about provenance (a value the pass
invented) while this one is about the CFG (a value that cannot be written there at all).

**⚠ NEVER COMPRESS THIS TO "`V` SITS AFTER THE JOIN".** That is a POSITION claim, it is the conjunct
REFUSED IN WRITING, and it is false: the ≥11 shipped merge-block colliders also sit after the join and
are genuine rivals precisely because their position is a consequence of the fold, not evidence about the
source. The operand form survives sinking because **sinking moves a definition and never rewrites its
operands**. The review's §2a adds the structural half, which is stronger than what this file originally
claimed: **no pass at any `-O` level can rewrite an existing value's definition to take an operand that
does not dominate it** (that is invalid SSA), so a pre-region value cannot *acquire* a use of `M` in
place; transforms that create `M`-users create NEW values. The residual is ABSORPTION (the author's
register folded into a new `M`-user and deleted) — and absorption removes the pinned value from the
module, so the ORACLE has no witness either and this conjunct is not what turns such a program into an
accept. Measured instance: `review_r1_probes/c/p3_armlocal_rival.c`, identical 4510-byte output on both
binaries; a pre-existing F2 blind spot the increment neither creates nor widens.

**⚠ AND IT IS A THEOREM ONLY FOR AN ACYCLIC USER CHAIN — a precondition that is now ENFORCED in the
helper rather than assumed** (§1, F-F1-1). A φ can take an `M`-descendant on a BACK EDGE and still
dominate both slots.

**The "same wire" reading is FALSE here and must never be substituted.** The owner's excluded value
is `icmp sgt (select %phi, …), 2` — off the condition's backward cone entirely, which is precisely
why `CondWire` did not already cover it. A later reader who re-grounds the conjunct on the wire
licenses a different and unargued set.

**It removes a WITNESS, not a decline.** Excluding `V` does not assert the module is unambiguous; it
asserts `V` is not evidence. Any other pinned value that *could* occupy a slot is still found, on
either edge, and still declines. Measured on the customer: with the φ-descendant collider
neutralised by hand, the owner's file already accepted **on the ORACLE**
(`probes/cust/owner_file_solecoll.ll` → exit 0), i.e. that witness was the only one — which is why
removing it compiles the file and changes nothing anywhere else.

**⚠ It is NOT the refused dominance conjunct, and the pair of fixtures is the proof.** "Defined
after the branch" is not "uses the region's φ": *both* new fixtures put the collider in the merge
block, after the branch, and only the one that reads the φ moves. Measured over the whole F2 corpus,
`collider-uses-phi` is **false for 32 of 32** fixtures and **true for all three customers**.

## §3 THE L1 ANSWER (control detection runs TWICE)

**Q: does the plan's committed region record exist at round 1, round 2, or both — and is the re-ask
owed in both entry points?**

**There is no record.** `PhiDesc` is derived inside `f2SeedPinnedByLiveRegister` from
`Region.Merge` on every call, so it is recomputed in round 1 and again in round 2, in **both**
entry points, from whatever module that round is looking at. There is no premise for
`repropagateControlMerges` to falsify, nothing to clear between rounds, no `WeakTrackingVH` hazard
(the set is built and consumed inside one call and never outlives it), and no seventh-emitter
"forgot to record it" window — the L1 failure mode this increment structurally cannot have.

**⚠ ROUND-1 CORRECTION (F-F1-5): THAT ANSWER PROVES RECOMPUTATION, NOT STABILITY, AND THE DRIFT
DIRECTION IS THE ACCEPT DIRECTION.** "Recomputed in both rounds, therefore correct by construction" is
**withdrawn as a closing argument**. Recomputation is what makes drift possible, not what prevents it:
round 1's emission RAUWs (M-β rewrites a merge φ to the arm's theta CALL), and a RAUW can substitute a
*deeper* value for a former user, so a round-2 region's `PhiDesc` can **GROW** — and growth of an
EXCLUSION set is the ACCEPT direction. **F-F1-5 IS OPEN**; the specific drift, the polarity of the two
RAUW sites (`SelectMergeEmit`'s shrinks the set, M-β's can grow it), the construction to attempt and the
R-1-shaped cure are written out as the round-2 assignment in `FIX_F_R1.md` §R2. Do not close it by
re-asserting the availability ground either: that ground is true of the ROUND-2 module and says nothing
about the SOURCE, which is what F2 asks about.

Two residuals stated rather than waved at:

* the set is a property of the module **as that round sees it**. Round 1's emission mutates the
  module (flatten, RAUW), so a round-2 region is classified against a round-2 graph. That is
  self-consistent — the predicate is always about the region being classified and its own φ — but it
  is an assumption, **and round 1 of review escalated it from an assumption to an OPEN FINDING
  (F-F1-5, §R2)**;
* `Region.Merge` is polymorphic (a `PHINode` for a branch region, a `SelectInst` for a select
  region). The helper `dyn_cast_or_null<PHINode>`s it and returns an empty set otherwise, so a
  non-φ merge silently contributes no exclusions — the conservative direction.

## §4 DISCLOSURE — what stops being refused, in the words the obligation requires

*(CORRECTNESS RISK §4's obligation, transferred to this increment. No warning diagnostic was added:
it would fire on every cascade the ruling exists to enable.)*

**A program that was LOUDLY REFUSED now receives a circuit, with no diagnostic.** The class is: a
state-prep region whose seed is also the value of some expression **computed downstream of that
region's own output** — canonically a cascade `if (a>=K){ b_i = cq_theta(b_i,θ); } if (b_i) a -= d;`
repeated, where region *i*'s seed `false` collides with region *i+1*'s guard `a >= K` evaluated on
the *post-region* `a`. Until 2026-09-14 that declined `state prep seed is proven equal to the
condition register`; it now compiles as the controlled state prep.

**The rival reading F2 was protecting against, stated plainly**, is `_Bool g = (a >= K); … b_i =
cq_theta(g, θ);` — an in-place Ry on `g`'s rail rather than a fresh prep, a different unitary.
**Why it has no lowering to be robbed of, and this is a different and stronger claim than the
2026-09-11 one:** the rival is not merely *declined*, it **cannot be written as this module at
all**. The value the compiler pinned reads the region's own merge φ, so putting it in the arm or in
the pred slot is use-before-def. The rival that *is* writable — `g` computed from the **pre**-region
`a` — is a **different SSA value**, is **not** a φ descendant, and is **still found and still
declines**: that is exactly what
`control_inplace_ry_reject_stateprep_nonphidesc_collider.ll` pins, on both binaries.

So, unlike the 2026-09-11 `CondWire` narrowing, this one absorbs **no** rival program: there is no
source the user could have written whose circuit they are now silently denied. What it absorbs is a
*witness* the fence should never have counted.

**⚠ SCOPE THAT CLAIM (round-1 review §4, last bullet). The UNIVERSAL form is overstated.** It is
correct **for the programs that now compile**, and it holds **for acyclic regions**, where every
excluded value is use-before-def at both slots so the rival has no module and no lowering to be robbed
of. It is NOT licensed as a statement about every program: the back-edge-φ shape (F-F1-1) was a
counter-example until the helper was narrowed, and F-F1-5's RAUW drift (`FIX_F_R1.md` §R2) is an open
question about whether a *manufactured* descendancy can exclude a source-writable witness. Say
"acyclic", and say the residual.

The honest residuals are therefore two: §6's round-2 question — whether `-O1` can manufacture such a
witness out of a source value that was not one, **answered NO structurally for the acyclic case and YES
for the cyclic one, which is why the helper now narrows** — and F-F1-5's round-2 question, whether the
PASS ITSELF can manufacture one across the `repropagateControlMerges` fixpoint.

## §5 CUSTOMERS — measured

| # | program | ORACLE | SUBJECT | trace | stage 2b (STRICT) |
|---|---|---|---|---|---|
| **C1** | `example/grover/grover_oracle_uncompute.c`, N=3, as the owner has it (mtime 2026-09-14 09:43, `_Bool b0;` uninitialised) | F2 | **exit 0**, stderr 0 B | 35 | `9 rail mint(s) of which 7 left allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven` |
| **C1′** | the same with `_Bool b0 = 0;` — **the committed slice** `tests/e2e/slice_control_cascade_three_bools.c` | F2 | **exit 0**, stderr 0 B | **35** | identical to C1 |
| **C2** | `vd.c` (the `if (b0 == 1)` spelling), N=3 | F2 | **exit 0** | — | — |
| **C3′** | `w3_runtime_a.c` — the cascade with a **runtime** `a` (`argc+4`) and a quantum-conditioned region 1, so the pin is **range**-derived, not IPSCCP-constant-derived | F2 | **exit 0** | — | — |
| **C4** | `n4_cascade.c` — **N=4**, the generality claim | F2 | **exit 0** | — | — |
| **C3** | `w2.c` as the brief names it | F2 | **`control flow`** — see below | — | — |

**⚠ THIS TABLE'S SUBJECT COLUMN WAS MEASURED ON `147cb3d6…` AND RE-MEASURED ON `96fdd3a9…`.** All
four customers (C1, C2, C3′, C4) plus `w2_base` were re-run on the post-fix binary against both the
ORACLE and the snapshotted pre-fix binary: **every verdict is unchanged and the lowered IR is
BYTE-IDENTICAL pre- to post-fix** (md5 `9a61bf46…` owner · `e452f94b…` vd · `6833ef12…` w3_runtime_a ·
`bcfc14de…` n4_cascade; `w2_base` DECLINE `control flow` on both). The back-edge narrowing costs the
customers **zero, measured** — every φ-descendant in all four lives in a block dominated by `M`'s.

**C1 and C1′ differ in exactly one trace literal** — `cqrt_alloc_i1(1)` against `cqrt_alloc_i1(0)`
on line 1, because stage 3 materialises the `undef` seed — and in nothing else; stage 2b is
identical. The committed slice uses the initialised spelling **deliberately**: the `undef` seed is
bd `z9t1`/Track U's subject in this same session ("normalize EARLY"), and a golden that depends on
how stage 3 materialises an `undef` would go red in the merge group for a reason that has nothing to
do with Track F. The slice header carries that as a RETIREMENT TRIGGER naming `z9t1`.

**⚠ C3 (`w2.c`) does NOT compile, and the reason is PRE-EXISTING — measured on the ORACLE, not
argued.** With my change F2 is gone from `w2.c` and it then declines `control flow` at
`%8 = select i1 %7, i32 1, i32 4` (`w2.c:8:9`). The control that settles authorship: on the
**ORACLE**, `probes/cust/w2_solecoll.ll` — `w2` with its F2 collider neutralised by one constant and
nothing else changed — declines `control flow` at the **identical site**. So the wall was always
behind F2; removing F2 exposed it. Its cause is that `w2.c` is not the same shape as the owner's
file: `a = argc + 4` makes the FIRST guard fold to `icmp sgt i32 %argc, -2`, a **classical** branch,
so region 1 is not a quantum control region at all and `%7` is a φ over a theta result produced under
*classical* control — off every leaf grammar, Track M's included. `w3_runtime_a.c` is the probe that
actually tests what the brief wanted C3 to test (runtime `a`, range-derived pin, region 1 still
quantum-conditioned) and it compiles. **Filed as an observation for the orchestrator, not fixed
here** — it is neither F2 nor this predicate.

## §6 ROUND-2 ASSIGNMENT, written out for the adversarial reviewer

**The single question, and it is the L5 trap in its exact shape:**

> **Can `clang -O1` rewrite a source value that did NOT depend on the region's merge φ into a module
> value that DOES — such that the module value is the surviving image of a register the author
> really could have put in one of F2's two slots?**

If yes, the predicate excludes a legitimate witness and the increment is an over-accept. A syntactic
answer to this loses; F2 has lost four consecutive rounds to precisely this shape (`CLAUDE.md` L5).

What I checked, against Rule 9's own list of what `-O1` does, and what I could not close:

| `-O1` rewrite (Rule 9) | reached a verdict? |
|---|---|
| sinks ops into arms / hoists into preheaders | position only; cannot introduce a *use* of the φ |
| fuses regions with equivalent conditions into one diamond with several merge phis | **the reviewer should push here**: after `MergePhiPeel` a fused diamond has more φs and more selects, and the peel MANUFACTURES values (the b6ap taint-growth lesson). Does a peel clone or a peeled select ever become a φ descendant of a *different* region's prep φ? |
| folds if/else over one register into one call with a `select` on the ANGLE | angle path, not a data witness |
| const-folds an equality edge on both sides | changes what is pinned, not what is used |
| rewrites a compare **sideways** onto a sibling or **downward** onto an ancestor | **push here too**: this is the family that beat F2 in rounds 2–3. A sideways rewrite moves a compare onto a *different operand*. If `-O1` can move a guard from the pre-region `a` onto the post-region `a` (which IS the φ descendant), the two spellings become one module and the witness I exclude is the image of a writable source. I could not construct it — the two are not provably equal — but I could not prove it impossible either |
| LICM-hoists a loop-invariant compare | in-loop state prep declines before F2 is asked |
| rewrites an affine add-recurrence into closed form | loop only, same |
| jump threading / block duplication | **unexamined**; it is the one transform that can legitimately duplicate a value into a context where its operands differ |
| GVN/PRE inserting a φ of partially-available values | introduces a *new* φ, not the region's prep φ — but the reviewer should confirm the new φ cannot BE the prep φ |

**Also hand the reviewer:** (a) §3's two L1 residuals; (b) *answered here, verify it*: at this call
site `Region.Merge` **is** the state-prep φ — `classifyArms` derives `MergePhi` from it at
`ArmClassify.cpp:3186` and F1 reads the defended seed off that very object at `:3906-3908`
immediately above, so the helper and F1 are looking at one φ; what the reviewer should check is
whether any path can reach F2 with a `Region.Merge` that is a φ of something else; (c) the mirror of the
`control_peel_reject_fp_stateprep.ll` argument — I kept the walk unpruned, so that fixture's
`Truncated` decline is untouched (measured), but the reviewer should check no *other* `Truncated`
decline depended on a φ-descendant being the thing that *answered* rather than the thing that
*seeded*.

**Budget 2 rounds** (Rule 13's measured hit rate). Round 1 is the above; round 2's own assignment
should be set from round 1's findings, not pre-committed.

**⚠ ROUND 1 HAS RUN (`REVIEW_F_R1.md`, CLEAR-WITH-ITEMS) AND ITS FIX HAS LANDED (`FIX_F_R1.md`).** The
questions above were answered as follows and this section is now HISTORY, not an open list: the
sideways-rewrite row went the **opposite** way when attacked in C (`-O1` folded the guard DOWNWARD onto
an ancestor, i.e. out of the φ cone and into `CondWire` — the safe direction); jump threading *removes*
φ uses and cannot add one; the acyclic case is answered NO **structurally** (§2); and the **cyclic** case
was answered **YES and built** — that is F-F1-1, now fixed. **Round 2's assignment is `FIX_F_R1.md` §R2**
(F-F1-5's RAUW drift, the fix itself as an unreviewed Rule-13 core edit, and F-F1-3's unmeasured Track U
composition).

## §7 ERRATUM AGAINST `SCOPE_F.md` — six vacuous measurements, found while implementing

`sed X.s1.ll > X.S1.ll` **truncates `X.s1.ll` to 0 bytes on a case-insensitive filesystem** (macOS
default): the shell opens the redirect target for writing before `sed` reads, and `X.S1.ll` and
`X.s1.ll` are the same file. A 0-byte `.ll` parses as an empty module and the pass accepts it, so
the probe reported `ACCEPT` for the wrong reason. Confirmed by `ls -l`: `owner.s1.ll`, `vd.s1.ll`,
`w2.s1.ll`, `owner.W.ll`, `vd.W.ll`, `w2.W.ll` are all **0 bytes** in the main checkout's
`trackF/probes/c/`.

Re-measured with distinct filenames (`probes/cust/*.ll`, all non-zero, sizes printed in the gate):

| `SCOPE_F.md` claim | status | corrected measurement |
|---|---|---|
| §3a "TEST W … 19/19 → ACCEPT" | **partly vacuous** | the **16 fixture** rows stand (they never collided); the **3 customer** rows were vacuous. Re-run: `owner_file_testW` **ACCEPT**, `vd_testW` **ACCEPT** — both claims hold non-vacuously |
| §3b "`w2` W → ACCEPT ⇒ the one-edge argument holds for a range-derived pin" | **FALSE as measured** | that W edit (the a-mux constant) does **not** move `w2` off F2 — re-run says F2. A *correct* W for `w2` is its own branch constant (`sgt %9,2` → `sgt %9,9`): F2 **is** gone there, on both binaries, so the one-edge conclusion stands — but on a different probe, and `w2` then hits the pre-existing `control flow` wall. The claim's *support* was wrong even though its *conclusion* survives |
| §3c "sole-collider S1 → ACCEPT" for all three customers | **vacuous** | re-run: `owner_file_solecoll` **ACCEPT**, `vd_solecoll` **ACCEPT** (both stand), `w2_solecoll` **`control flow`** (does **not** stand — and this is the measurement that proves w2's wall is pre-existing, §5) |
| §2 table, §1 counts, §5 HOLE-1, the rival audit | **unaffected** | those probes are in `probes/{pin,rival,bothedge,fence}/` and no two of their names differ only by case |

**The lesson, for the orchestrator to carry:** this is PROTOCOL S3's "a named negative can be
VACUOUS" in a new spelling — not a check that names something absent, but a *subject* that a shell
redirect silently emptied. The cheap defence is the one now in the sweep and in the gate line:
**print the byte size of every generated probe**, and treat 0 as a hole. A probe that cannot fail is
not a probe.

## §8 WHAT DID NOT MOVE

| set | count | result |
|---|---|---|
| fixtures declining with F2's string | **29** | **29 still decline, MOVED 0** |
| fixtures naming the string that ACCEPT | 3 | 3 still accept |
| of the 29: the 4 that decline through the `\|\| Truncated` disjunct | 4 | unmoved by construction (the conjunct is at the TEST, not at the disjunct) |
| `control_peel_*` | **42** | ⚠ only **4** of the 42 name F2's string, so the 29/3 run above does NOT cover this row and an earlier draft of this table wrongly implied it did. What covers it is `ctest -R ir-pass-lit` (**Passed**, all 1930 fixtures) and the corpus sweep. Named explicitly because they are the ones a reviewer will ask about: `control_peel_reject_fp_stateprep` (the `Truncated` decline whose fp select is reachable only through a value R-1 excludes — the reason this conjunct is at the TEST and not in the walk), `control_peel_reject_stateprep_two_region_foreign_clone` (SCOPE_R §3b's two-diamond FOREIGN clone), `control_peel_reject_stateprep_handwritten_clone_i1`, `control_peel_stateprep_datamux_peeled_control` (a HAND-WRITTEN `%cq.peel.cond`) — all four unmoved |
| the `rb9x` fixtures (those naming bd `rb9x`) | **11** | unmoved: 5 are inside the 29 F2-decliners, the rest are covered by `ir-pass-lit` and the sweep |
| the named e2e goldens (`…cascade_two_bools`, `…inplace_ry_stateprep_bool`, `…stateprep_bool_under_int_compare_fused`) | 3 | `100% tests passed, 0 tests failed out of 3` |
| duplicate-body fixture scan | 1932 fixtures (post-fix) | **N1** (comment lines stripped, blanks KEPT) **7 groups**; **N2** (comments + blanks stripped) **9 groups** — the axis is BLANK LINES, not whitespace. This row's original `9` was N2, so the label "non-comment lines" was imprecise. All groups **pre-existing**; **all four new fixtures are in groups of size 1** under every normalisation tried. The reviewer's `8` reproduces under none of N1/N2/N3/N5 and is recorded UNRECONCILED by one group (`FIX_F_R1.md` F-F1-6) |

## §8b CORPUS SWEEP — 2086 modules, 7 movers, 0 unattributable  ⚠ `147cb3d6…` ONLY

⚠ **THIS SWEEP IS A FACT ABOUT THE PRE-FIX BINARY AND WAS NOT RE-RUN.** One corpus sweep per session,
and it belongs to the merge gate. The fix-round argument for why no second sweep is owed is in §10.

`probes/corpus_sweep.py` over `ir-pass/test/*.ll` (1930) + every Track F probe (156), ORACLE against
SUBJECT, a row being `(exit code, FULL stderr bytes, md5 of the lowered IR)`. It deliberately does
**not** use the shared `corpus.sh` tag regex: PROTOCOL S3 records that that regex renders the whole
`cq_measure_<sfx>` family as an empty `D:`, so a decline->decline STRING change inside it is
invisible; a full-stderr byte compare closes that hole.

| mover | ORACLE -> SUBJECT | attribution |
|---|---|---|
| `control_inplace_ry_stateprep_phidesc_collider_accept.ll` | F2 -> **ACCEPT** | this increment's own new accept fixture |
| `owner_file_base.ll` | F2 -> **ACCEPT** | C1, the owner's file |
| `vd_base.ll` | F2 -> **ACCEPT** | C2 |
| `w3_runtime_a_base.ll` | F2 -> **ACCEPT** | C3', the runtime-`a` / range-derived cascade |
| `n4_cascade_base.ll` | F2 -> **ACCEPT** | C4, N=4 |
| `w2_base.ll` | F2 -> **`control flow`** | §5: still a DECLINE; the pre-existing wall, proved pre-existing on the ORACLE |
| `w2_testW.ll` | F2 -> **`control flow`** | the same module with one constant moved; same wall |

**Every mover is a cascade shape whose ORACLE string was
`state prep seed is proven equal to the condition register`**, which is exactly the expected-mover
rule the brief states; there is no mover of any other kind. **Of the 1930 shipped fixtures, exactly
ONE moved, and it is the fixture this increment added.** The two `w2` rows are DECLINE->DECLINE, so
no shipped program became an accept.

## §8c THE BACK-EDGE FIXTURE PAIR (added in the fix round)

`ir-pass/test/control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll` — the **TRIPWIRE**: a
loop-header φ carrying an `M`-descendant on its back edge, pinned to the seed, DECLINE with F2's string.
`…_backedge_nonphidesc_collider.ll` — the **ISOLATING CONTROL**: the same module with one operand
changed so the carried φ reads a condition-derived value instead, DECLINE with the same string on every
binary in the family.

Both headers carry, in these words: the pair relationship and the ban on "consolidating" them; the
measured three-binary table; the attribution control `p8b`; the Rule-12(b) note that the IR-text
`CHECK-NOT`s are vacuous because a `DS_Error` decline writes 0 bytes to stdout; and the **L8 RETIREMENT
TRIGGER naming bd `test_C_libtooling-wx8g`** — that the in-loop over-decline is the ONLY reason the
shape is unreachable rather than merely narrowed, that in-loop regions DO reach `classifyArms`, and that
the day `wx8g` lands the narrowing must be re-derived against the shapes it admits without assuming the
φ case is the only cyclic one.

**Validated by mutation of the BINARY**, which is the strongest form available for a decline fixture:
pre-fix the tripwire is **RED** and the control **GREEN**; post-fix both are GREEN.

## §9 TRACK P INTERACTION

I touched **only** `ir-pass/src/ArmClassify.cpp`, and inside it only (a) the comment block above
`f2SeedPinnedByLiveRegister`, (b) a new file-local helper immediately above that function, (c) three
lines inside the function (the `PhiDesc` declaration + call, and the conjunct at the test). The fix
round changed nothing about that footprint: it added a `const DominatorTree &` parameter to **the new
file-local helper** (whose only caller is (c)), two lines in that helper's body, and comments. **No
shared helper was refactored, no pre-existing signature changed, no other file's code was edited.** Track P is in
the phase-kickback classifier, a different region of the same file; the only plausible collision is
textual proximity, not semantics. Other files touched are additive-at-a-disjoint-anchor only:
`tests/e2e/CMakeLists.txt` (one `add_test` appended after the `…two_bools_int` block), two new
`ir-pass/test/*.ll`, one new slice + golden, and records.

## §10 GATE LINES

See `GATES.md` — every line carries the binary hash, and the file now has **two tables**. ⚠ **Every
line recorded against `147cb3d6…` is VOID for the shipped binary `96fdd3a9…`** and is labelled
`cited:`; the fix-round table is labelled `ran:`.

**ran: on `96fdd3a9…`** — `p8`/`p8c`/`p8b`/`p9` on three binaries · the new fixture pair validated by
MUTATION OF THE BINARY (tripwire RED pre-fix, GREEN post-fix; control GREEN on both) ·
`lit --filter backedge` (4/4) · all four customers on three binaries (lowered IR **byte-identical**
pre- vs post-fix) · the 4 named e2e slices (4/4) · the injection matrix (12 mutations, MISSED 0, N/A 0)
· the duplicate-body scan in both normalisations · `ctest -R ir-pass-lit` ONCE (**Passed**, 1932
fixtures).

**cited: on `147cb3d6…` only** — the 29-fixture F2 family, the 3 F2-naming accepts, the pre-fix
customer runs, the two `lit --filter` lines, the pre-fix e2e lines, the pre-fix injection matrix, the
pre-fix duplicate scan, and **the corpus sweep (2086 modules, 7 movers)**. The sweep was NOT re-run:
one per session and it belongs to the merge gate.

**Why no second sweep was needed for the fix**: the narrowing removes members from an EXCLUSION set, so
the TEST can only succeed sooner. The only reachable transitions are ACCEPT→DECLINE and
DECLINE(truncated)→DECLINE(test) — a DECLINE can never become an ACCEPT — so a green `ir-pass-lit`, in
which every accept is pinned green and every decline mirrors its string character-for-character, is
exactly the statement "no fixture moved".

**Not run, deliberately** (PROTOCOL matrix, implementer/fix row): the full `ctest -j6`, `^e2e-`,
`cq-opt-equivalence-full`, the twin matrices, and the corpus sweep — all of which belong to this merge
GROUP's merge-and-gate agent.
