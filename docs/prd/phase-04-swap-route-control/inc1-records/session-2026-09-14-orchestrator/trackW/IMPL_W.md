# Track W — IMPLEMENTATION record: bd `test_C_libtooling-wx8g` (l4x4.c)

**The in-loop bare-`_Bool` controlled-Ry arm / state prep, and the ITERATION-LOCAL rolled rail.**

Session 2026-09-14. Worktree `/Users/sorenwilkening/Desktop/CQ_wx8g`, branch `inloop-bool-prep`, off `main`
`607b6fe4`. ORACLE (frozen, read-only): `cq-opt`
`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` / `libCQPass.so`
`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`, built from `59ac5b7`; hash verified
before the first probe. ⚠ **My clean pre-edit build of this worktree produced a `cq-opt` BIT-IDENTICAL to
the ORACLE** (`f7b65d8c…`) — `main` `607b6fe4` is docs-only over `59ac5b7` — so every "before" number below
is an ORACLE number by construction, not by a second measurement.

Gate lines: `GATES.md`. Probes: `probes/` (C) and `probes/ir/` (hand IR).

---

## 0. What was refused, measured on the ORACLE before any code was written

| probe | shape | ORACLE verdict |
|---|---|---|
| `w_a_carried_bool` | `for (k<2) if (b) r = cq_theta(r,.2);` — `b` a loop-INVARIANT `_Bool`, `r` loop-CARRIED | DECLINE `control flow inside a loop body`, anchored at the `cq_theta_i1` |
| `w_a_neg` | the same with `if (!b)` | same |
| `w_grover_bool` | one bool-controlled Ry + the S†/S pair per trip | same |
| `w_b2_prep_bool` | `for (k<2) { int r = 7; if (b) r = cq_theta(7,.2); … }` — an in-loop STATE PREP | same |
| `w_d_iterlocal_base_bool` | `for (k<2) { int r = cq_theta(7,.25); if (b) r = cq_theta(r,.2); … }` | same |
| `w_g_derived_cond_iterlocal` | the same with a DERIVED condition `(q>>k)&1` | same |
| `w_c_compare_invariant` | the COMPARE spelling of `w_a` (`if (x == 3)`) | DECLINE **`condition predates a non-diagonal gate`** |

`w_c` is CLAUDE.md's row W re-measured: `-O1` LICM-hoists a loop-invariant compare out of the body and
`condWireDisposition`'s P4 prong refuses a cross-block condition, so **the COMPARE spelling cannot express
this shape at all**. Together with the first six rows that is the sentence CLAUDE.md records — *"Grover as a
rolled loop with a bool-controlled rotation or prep compiles in NO spelling on ANY binary"* — confirmed on
the frozen binary of this session.

**Which of the two I am fixing, and whether it reaches the other.** I am fixing the **rail (`_Bool`)**
spelling, plus the iteration-local rolled rail for **every** condition kind. **It does not reach `w_c`.**
Row W is a `condWireDisposition` P4 defect, not a loop-layer one: this increment touches neither
`condWireDisposition` nor P4, and `w_c` declines with its unchanged string on the subject binary. It stays
filed (bd `drbq.12` / CLAUDE.md row W).

---

## 1. What lowers now — measured on the SUBJECT `95a33b2ea04155d1`

⚠ **TWO SUBJECT BINARIES, and every number says which.** `95a33b2ea04155d1` is the tree as
measured in §1/§8; `daeb93a36bdc57b3` is the same tree plus ONE comment-and-anchor change (the
`Esc->getDebugLoc() ? Esc : I` fallback of §7.4) and is the committed tip. The §9 matrix table and
the closing `ir-pass-lit` are on `daeb93a3`; §1's traces and §8.4's matrix are on `95a33b2e`. An
earlier comment-only rebuild produced a BIT-IDENTICAL binary, which is how I know a comment edit
does not move the compiler here — the anchor edit does, so it was re-gated.

Every row is `probes/sweep.sh` (the PROTOCOL.md per-probe pipeline, STRICT stage 2b) and, for the accepts,
a `diff` of the rolled trace against the hand-unrolled twin's.

| probe | shape | subject | rolled vs hand-unrolled twin |
|---|---|---|---|
| `w_a_carried_bool` | `for (k<2) if (b) r = cq_theta(r,.2)` | ACCEPT, 8 trace lines, 2b `4 mint / 4 left allocated / 0 free` | **BYTE-IDENTICAL** |
| `w_a_neg` | the same, `if (!b)` (Ry additivity) | ACCEPT, 10 lines, `4/4/0` | **BYTE-IDENTICAL** |
| `w_grover_bool` | bool-controlled Ry + S†/S per trip | ACCEPT, 12 lines, `2/2/0` | **BYTE-IDENTICAL** |
| `w_b2_prep_bool` | in-loop iteration-local STATE PREP | ACCEPT, 9 lines, `4/4/0` | **BYTE-IDENTICAL** (vs the per-block twin `w_b_iterlocal_prep_bool_unrolled`) |
| `w_d_iterlocal_base_bool` | iteration-local rotated base, rail cond | ACCEPT, 11 lines, `4/4/0` | **BYTE-IDENTICAL** |
| `w_g_derived_cond_iterlocal` | iteration-local base, DERIVED cond | ACCEPT, 27 lines, `4/4/4 free verified` | **BYTE-IDENTICAL** |
| `w_k_two_iterlocal_rails` | TWO iteration-local rails in one body | ACCEPT, 17 lines, `3/3/0` | **BYTE-IDENTICAL** |
| `w_i_no_invariant_root` | every register iteration-local, rail cond | ACCEPT, 14 lines, `4/4/0` | **BYTE-IDENTICAL** |
| `w_j_no_invariant_root_derived` | the same with a DERIVED cond | **DECLINE** `control flow inside a loop body` | — (the round-2 re-ask; see §3) |
| `w_c_compare_invariant` | the COMPARE spelling of `w_a` | DECLINE `condition predates a non-diagonal gate` | unchanged from the ORACLE (row W) |
| `w_e` / `w_f` / `w_h` | iteration-local under a plain compare | DECLINE `condition predates a non-diagonal gate` | their HAND-UNROLLED forms decline too, on the ORACLE — no twin exists for these |

**8 of 8 accepting pairs byte-identical.** The `w_b2` row is the one that needed care: its FIRST twin pulled
both measurements to the end of the function and diverged by the POSITION of one `cqrt_measure_i32` — a
DIFFERENT PROGRAM, not a lowering divergence. A twin must be the loop body written out statement for
statement, and the slice header now says so.

### 1.1 The §3 constant-seed fold trap, addressed explicitly

The brief warns (SCOPE_L1a H2) that with a compile-time-constant seed `-O1` folds trip 0's condition away in
the UNROLLED spelling and cannot in the rolled one, so "one folded region + one genuine prep" gets compared
against "one genuine prep, K times". **None of these pairs can hit it, and the reason is structural rather
than lucky: no condition here is a compare against a foldable classical value.** Every condition is either
the bare `_Bool` register `b` (a `cq_theta_i1` RESULT — opaque to every `-O1` fold, which is why
`railCondWireDisposition` exists at all) or a compare on a quantum register (`(q>>k)&1`). `-O1` cannot prove
either edge, so no trip folds and both spellings emit K genuine regions. The direct evidence is the table
above: if a trip had folded, the twin would have one gate fewer, and eight pairs are byte-identical at four
different gate counts.

### 1.2 K-independence of the lowered IR — measured WITHOUT `-g`

A `-g` line count is not comparable (debug metadata inflates it — `SCOPE_loop.md` §3), so these are
`clang -O1 -DCQ_K=<K> -emit-llvm -S` with no `-g`, through `cq-opt`, `wc -l`:

| slice | K=3 | K=1000 |
|---|---|---|
| `slice_control_inplace_ry_bool_loop` | **81** | **81** |
| `slice_control_inplace_ry_bool_loop_grover` | **66** | **66** |
| `slice_control_inplace_ry_bool_loop_iterlocal` | **85** | **85** |
| `slice_control_stateprep_bool_loop_iterlocal` | **83** | **83** |
| `slice_control_inplace_ry_loop_iterlocal_derived` | **105** | **105** |

A count that grew with K would mean the loop was unrolled and the increment's central claim is false.
K-INDEPENDENCE IS A MEASUREMENT, NOT A ctest GATE, following the 8h7d.5 and drbq Inc-3 precedents exactly.

---

## 2. The change, file by file (7 edits, ~230 pass-source lines including comments)

| file | edit |
|---|---|
| `ir-pass/src/ArmClassify.cpp` | **(1)** the l4x4.b `if (RailCond && Region.InLoop)` carve-out is DELETED (the rationale replaced by a recorded retirement, with both of its stated reasons measured false). **(2)** new file-local `iterationLocalRollable` — R7-loop **clause (c)**. **(3)** the `Rollable` disjunct + the `Taint.RolledIterLocalGates` record at the grant. |
| `ir-pass/src/LoopLowering.cpp` | **(4)** `railPhiRootMint`'s clean-rail-mint tail factored out as `railChainRootMint` and CALLED from it (Rule 14). **(5)** new `iterationLocalTaintEscape` — clause (c3)'s body, one spelling, two callers. **(6)** new `declineUnmarkedRolledIterLocal` — the post-fixpoint LOUD re-ask. |
| `ir-pass/include/LoopPlan.h` | declarations + contracts for (4)/(5)/(6); `class Instruction;` forward-declared. |
| `ir-pass/include/TaintPropagation.h` | new `TaintSet::RolledIterLocalGates` (a `WeakTrackingVH` vector) + the full L1 argument. |
| `ir-pass/src/CQLoweringPass.cpp` | **(7)** `declineUnmarkedRolledIterLocal(M, taint)` in BOTH entry points, immediately after `reverifyCmpCondReads` — i.e. AFTER the round-2 fixpoint and BEFORE `lowerRotations`. |

### 2.1 Half 1 — the l4x4.b in-loop rail carve-out is RETIRED

It was `if (RailCond && Region.InLoop) decline("control flow inside a loop body")`, and l4x4.b recorded in
its own comment that it was an increment boundary, not a fence: *"IT IS NOT REFUSED FOR ANY REASON
INTRINSIC TO THE SHAPE … R7's (b)/(b′) clauses would carry unchanged."* Its two stated reasons are
measured false:

* **"there is no oracle twin."** TRUE of the COMPARE twin and irrelevant: the in-loop witness discipline in
  this tree is ROLLED versus HAND-UNROLLED (34 `*-twin-identical` ctest gates), never rolled-versus-compare,
  and the hand-unrolled `_Bool` twin is l4x4.b's own flat capability. Measured on the ORACLE, byte-compared:
  `w_a` / `w_a_neg` / `w_grover_bool` are BYTE-IDENTICAL to their `_unrolled` twins at 8 / 10 / 12 trace lines.
* **"it is the C-1 mixture"** — a loop-INVARIANT condition beside a loop-CARRIED register, whose leak
  signature is a per-trip CONDITION CHAIN the rolled form never discharges. TRUE of a compare or derived
  condition and **VACUOUS for a rail**: a bare `_Bool` condition MINTS NOTHING AND DERIVES NOTHING.
  `emitInPlaceRotationRegion` step 1 hands the register itself to `cqrt_ry_<W>_controlled` as arg-0 and
  step 3's strip+free are SKIPPED WHOLE (§2.7), so there is no ancilla, no `cq_template_*` rail and no
  `_unc` for the whole-DAG spine to place. The three `_Bool` goldens contain **zero** `cq_template_*`,
  **zero** `cqrt_x` and **zero** `cqrt_free` lines — that absence is the argument, and it is checkable.
  ⚠ **THAT CLAIM IS TRUE OF THE CONDITION AND FALSE OF THE REGION'S LOOP** — see §2.1a, which is the
  correction review round 1 forced and the reason half 2 now records at every grant.

No new predicate replaces it: the region simply reaches R7, which asks its questions about the ROTATED
register and does not care what kind of value the condition is.

### 2.1a ⚠ THE CORRECTION — §2.1's second bullet was LOAD-BEARING AND WRONG (review round 1, F-W1-2)

The sentence this section shipped read:

> *"… and `markIfRailLocal` exempts it at its 'accumulating loop-invariant tainted input' clause because
> `invariantRegisterRoots` admits exactly a classical-arg-0 `cq_theta` dominating the header — which a
> `_Bool` mint is — on BOTH halves of `collapseFlattenedLoopRails`' dispatch."*

**`d3_invariant_read.c` measures it FALSE.** `b` IS a classical-arg-0 `cq_theta_i1` dominating the
header, and the marking is refused anyway: the body's non-control read of `b` (`cq_measure(u + (int)b)`)
trips exactly that clause, the body never enters `taint.IterationLocalBlocks`, and the per-trip
`cq_template_and_i32_hl` rail leaks. Pre-fix: **ACCEPT 30 trace lines against a hand-unrolled twin at
34**, `opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s)`. The ORACLE `f7b65d8c…` **refused**
the module, so this was a NEW CUSTOMER on a known-defective path, not a quarantinable divergence —
CLAUDE.md's `1m5p`/`a3z7` formulation verbatim: *"'pre-existing' is true of the defect and FALSE of its
population."*

**What is true, and what replaces the wrong sentence.** The retired carve-out was not guarding the
CONDITION; it was guarding the LOOP. A bare `_Bool` condition really does mint nothing — that half of
§2.1 survives every attack the reviewer and I made of it — but the **body** can mint per-trip template
rails for reasons the condition kind says nothing about. Half 2 built the right instrument
(`RolledLoopRegionGates` + the postcondition re-ask) and then wired it to **one of the grant clauses**.
It is now wired to all of them: the `push_back` sits on the far side of `if (!Rollable) { decline;
return; }` with a per-entry clause bit, conjunct 1 (the (c3) escape re-ask) is asked of clause-(c)
entries only, and conjunct 2 (the marking postcondition) is asked of every **R7-loop** entry. Full
record: `FIX_W_R1.md`, corrected by `FIX_W_R2.md` §3 (conjunct 1's stated reason) and §4 (the scope
of "every").

### 2.1b THE RETIREMENT'S GROUND, RE-FRAMED ON THE HONEST ONE (review round 2, §2.1a's support retracted)

Round 2 would land the retirement and says so — its narrow claim survived ten byte-identical twin pairs,
a chained per-trip condition rail, a negated arm, an in-loop state prep, a strictly-deeper classical
loop and K-independence at K=1000 — **but the ground written above is not the right one.** Two
measurements, neither of which changes a verdict:

* **The carve-out was never the first wall it was taken for.** For `w2e3_xor_on_rotated.c` (an in-loop
  rail Ry arm followed by `cq_measure(r ^ 5)`) the frozen ORACLE declines **EARLIER** than the carve-out
  ever ran — at `declineStaleRecordOps`, `cq opcode lowering: operand predates a non-diagonal gate`,
  **the same string and the same anchor (`:9:14`) as this binary** (re-measured on `d47297cf`, sweep row
  `w2e3_xor_on_rotated|sub`). It was a SCOPE BOUNDARY standing in front of fences that were already
  doing the work.
* **"The condition mints nothing" cannot bound a leak the BODY mints.** That is exactly how F-W1-2 got
  through: a loop-CARRIED rail under a bare `_Bool`, granted by (b′), leaking one
  `cq_template_and_i32_hl_unc` + `cqrt_free` per activation — with "the condition mints nothing" still
  true of it.

**THE GROUND TO QUOTE, and the one now written in `ArmClassify.cpp`'s retirement block:**

> **The fence is the marking postcondition, and the condition kind is irrelevant to it.**

Every in-loop leak the body can mint is refused by `declineUnmarkedRolledIterLocal`'s conjunct 2, which
is asked of **every R7-loop grant** and asks nothing whatever about the condition. "A bare `_Bool`
condition mints nothing and derives nothing" is then a **remark** about why the `_Bool` shape has little
left to refuse — true, attacked, unbroken — and **not a fence**. Stated this way the retirement
**PREDICTS** F-W1-2 (a grant clause with no record is a grant with no fence) instead of being falsified
by it, which is the test a safety ground has to pass. ⚠ And the scope is exact: conjunct 2 covers every
**R7-loop** grant, a STRICT SUBSET of a region-independent leak class (`FIX_W_R2.md` §4).

⚠ The field is now spelled **`TaintSet::RolledLoopRegionGates`** (it was `RolledIterLocalGates`): a
container that holds (b′) entries must not be named after clause (c).
`declineUnmarkedRolledIterLocal` keeps its name — "IterLocal" there names the MARKING it checks
(`taint.IterationLocalBlocks`), not the granting clause.

### 2.2 Half 2 — R7-loop clause (c), the ITERATION-LOCAL rail

```cpp
        if (!Rollable && L && LHdr && DT &&
            iterationLocalRollable(L, LHdr, BaseWireOrder, MergePhi, T,
                                   StatePrep, RotBase, GateCalls, Taint)) {
          Rollable = true;
          Taint.RolledIterLocalGates.emplace_back(T);   // the record half
        }
```

and the predicate, in full:

```cpp
  if (!L || !LHdr || !T)            return false;   // no proof (Prime Directive)
  if (!L->getLoopLatch())           return false;   // single latch

  // (c1) the rail does NOT cross the back edge — asked POSITIVELY, because
  //      `Rollable == false` is also true of a header phi (b') REFUSED.
  for (Value *B : BaseWireOrder)
    if (auto *P = dyn_cast<PHINode>(B))
      if (P->getParent() == LHdr)   return false;
  if (MergePhi && MergePhi->getParent() == LHdr) return false;

  // (c2) the register is minted FRESH ON EVERY ACTIVATION, by an Ry, INSIDE `L`.
  Value *MintSeed = StatePrep ? static_cast<Value *>(T) : RotBase;
  CallInst *Mint = railChainRootMint(MintSeed, GateCalls, Taint);
  if (!Mint || !L->contains(Mint->getParent()))  return false;
  const Function *MF = Mint->getCalledFunction();
  if (!MF || !MF->getName().starts_with("cq_theta_")) return false;

  // (c3) nothing tainted DEFINED in `L` is READ outside `L`.
  return iterationLocalTaintEscape(L, Taint) == nullptr;
```

**(c2) is `railPhiRootMint`'s own mint test with the POSITION half inverted.** (b′) requires
`DT.dominates(Mint, LHdr)` — minted ONCE, before the loop, so it crosses the back edge; (c2) requires
`L->contains(Mint->getParent())` — minted FRESH every trip, so the rolled body allocates K rails exactly as
K copies would. Both call the one shared body `railChainRootMint`, which is `railPhiRootMint`'s tail lifted
verbatim (Rule 14; the drbq Inc-3 (b′) precedent is the reason this is not a second spelling).

**For a STATE PREP the mint is `T` itself.** `BaseWireOrder` is EMPTY for that class (R4/R6 are SKIPPED,
§14.5) and `RotBase` is the seed `Constant`, so there is no pre-region SSA name for the rail at all — the
HOISTED theta mints it. That also answers the deferred item in
`control_inplace_ry_reject_stateprep_inloop_iterlocal.ll`'s header, which read the obstruction as positional
and concluded that a rolled in-loop prep *"would need the alloc hoisted OUT of the loop … trip 2's `f=0`
component would read a rail trip 1 may have rotated."* That reset question is a property of HOISTING, which
clause (c) does not do and must not: leaving the `cqrt_alloc` IN the body is what makes every trip's `f=0`
component read a fresh `|SEED⟩`.

### 2.3 (c3) is a UNITARY fence, and it has a measured discriminating pair

Measured on the scaffolded subject with clause (c3) ABSENT and nothing else changed, on two hand-IR modules
differing in exactly one edge — where the per-trip register is read
(`probes/ir/il_{escape,noescape}_{rolled,flat}.ll`, a DERIVED condition so the per-trip chain is the SPINE's
to discharge and not the emitter's):

| | rolled | hand-unrolled twin | verdict |
|---|---|---|---|
| register read AFTER the loop (**escapes**) | **19** trace lines | **27** | ROLLED ≠ UNROLLED — two entangled which-path rails of `q`'s bits LEAKED per activation (`and_unc`, `free`, `lshr_unc`, `free` all missing) |
| register read INSIDE the body | 27 | 27 | **BYTE-IDENTICAL** |

`opt` exit 0, `opt -verify` clean and STRICT stage 2b `0 violation(s)` on **all four** — `free_pairing_check.py`
counts `cqrt_alloc` sites and a TEMPLATE-minted rail has none, exactly as its own header says. The byte-diff
is the only instrument in the tree that can see this.

---

## 2.4 ⚠ WHAT REVIEW ROUND 1 CHANGED — read this before §3 onward

Round 1 returned **NOT CLEAR** with two over-ACCEPTs. Both are fixed on the branch; the full record is
`FIX_W_R1.md` and every gate line is re-recorded in `GATES.md` against the NEW binary
`40edde36678c7dd4` (every line against `daeb93a3` is void). In brief, so no later section is read on the
old premises:

1. **F-W1-1** — `declineUnmarkedRolledIterLocal`'s per-loop dedup set was a module-scoped
   `SmallPtrSet<const Loop *>` outliving the per-function `LoopInfo` that owns those `Loop` objects. Two
   ordinary kernels in one TU (`b6_noattr.c`, no attributes) ACCEPTED at 40 trace lines with
   `cq_template_and_i32_hl` ×2 and `_unc` ×0. Fixed: per-function scope **and** a header key, in **two**
   sets. See §3(c2).
2. **F-W1-2** — the record was written at the clause-(c) grant alone, so a clause-(b′) rail region got
   no record and no re-ask (`d3_invariant_read.c`: ACCEPT 30 vs twin 34, ORACLE DECLINE). Fixed: record
   at EVERY grant, with a per-entry clause bit. See §2.1a — **§2.1's second bullet was wrong** and is
   corrected there.
3. **F-W1-3** — `bodyHasSpineDischargeCandidate` now excludes `taint.InPlaceRailOps` by CALLING the M-C
   record. It is load-bearing: without it, (2)'s widening turns the shipped
   `control_inplace_ry_inloop_offset.ll` red. ⚠ Of the three shapes round 1 called over-declines, **only
   `od4` is one** (byte-identical twin, 16 = 16, FILED); `od2`/`od3` DIVERGE from their twins and their
   declines are CORRECT — the review inferred the rolled lowering from the twin's stream, and the twin is
   straight-line where M-C fires.
4. **Three new fixtures pin the two-function axis** (two DECLINE, one ACCEPT) — §8.1a.

---

## 3. L1 — the ROUND-2 window, answered in full

Detection + lowering run TWICE (`repropagateControlMerges`). Three questions, per CLAUDE.md's three species.

**(a) Where does each piece run?**

| piece | slot | why it is safe there |
|---|---|---|
| the carve RETIREMENT + clause (c) | inside `classifyArms`, i.e. inside `detectControlRegions` | it is a PURE PREDICATE, and the whole of detection runs again at the fixpoint in BOTH entry points. Its only output is a local `bool` consumed 20 lines later in the same function. |
| the RECORD (`RolledIterLocalGates`) | the grant site, one call | the `RailCondReads` / bd `eqpx` tripwire pattern. ⚠ It is the ONLY writer; a second clause-(c) grant added without it re-opens the window with NO DIAGNOSTIC ANYWHERE. |
| `declineUnmarkedRolledIterLocal` | `CQLoweringPass.cpp` in BOTH entry points, immediately after `reverifyCmpCondReads` | AFTER the round-2 fixpoint (nothing else makes the marking or the taint final) and BEFORE `lowerRotations` (which erases the `@cq_theta` the record names). |

**(b) Does it compute something a later stage consumes over a premise round 2 can falsify? — YES, and
that is why the record exists.** Clause (c)'s proof has a consumer in ANOTHER STAGE: the per-trip TEMPLATE
rails a derived condition mints are discharged by the whole-DAG spine ONLY inside
`taint.IterationLocalBlocks`, which `LoopLowering::markIfRailLocal` populates AFTER the flatten at FINAL
taint. It can refuse — or never be asked — for reasons the classifier neither owns nor can see:

1. **it is never CALLED** when the loop has no root mint to hand it (`collapseRailPhisIn` NotClaimed ∧
   `invariantRegisterRoots` false) — an iteration-local CONDITION as well as an iteration-local register is
   exactly that loop (probes `w_i`, `w_j`);
2. it is called and returns early — a second still-standing tainted branch (L2), a tainted-index memop (L3),
   a quantum subloop, an unclaimed tainted header φ, an "accumulating loop-invariant tainted input";
3. its ESCAPE clause is asked at ROUND-2 taint while clause (c3) asked it at ROUND-1 taint — **CLAUDE.md's
   L1 PREDICATE species verbatim**, and it is not closed by the fact that detection runs twice, because
   `markIfRailLocal`'s marking is ADDITIVE AND NEVER WITHDRAWN (`LoopPlan.h` says so), so a round-1 GRANT
   would stand over a round-2 escape.

So the accept is **not predicted, it is RE-ASKED**, with two conjuncts:

* **conjunct 1** — clause (c3) again, at FINAL taint, by CALLING the same `iterationLocalTaintEscape` body
  (this closes species 3);
* **conjunct 2** — the MARKING POSTCONDITION: every one of the loop's OWN blocks must be in
  `taint.IterationLocalBlocks` (this closes 1 and 2).

Both decline LOUDLY with the string the shape has always had. ⚠ The postcondition is EXACT, not heuristic:
`markIfRailLocal`'s `!AnyLocal` early-out cannot be the reason a clause-(c) loop is unmarked, because (c2)
proves the rotated register is minted INSIDE `L` by a classical-arg-0 `cq_theta`, such a mint peels to
itself, and every member of `Roots` dominates the header — so `onRail` is false for it and `AnyLocal` is
true for every clause-(c) loop.

**(c1) THE `runOnFunction` MIRROR CLAIMS NO PARITY (review round 1, F-W1-4).** The call is mirrored into
`CQLoweringPass.cpp`'s `runOnFunction` shim for WI-1.12 twin-pipeline parity, and the mirror is
**syntactically faithful and semantically not**: that shim NEVER calls the round-1
`collapseFlattenedLoopRails` (a pre-existing gap documented at `TaintPropagation.cpp:1810-1816`) and the
round-2 call is handed `Round1FlattenedPreds` as `AlreadyProcessed`, so it SKIPS exactly the loops the
shim flattened at round 1. Consequence, stated plainly rather than implied away: **in the shim a
clause-(c) loop can never be marked, so conjunct 2 would fire on every one of them that has a
candidate.** The shim has **zero callers today**; the item is filed against the shim, not against this
increment.

**(c2) THE PER-LOOP DEDUP IS TWO SETS AND IS PER FUNCTION (review round 1, F-W1-1).** `Diagnosed` was a
module-scoped `SmallPtrSet<const Loop *>` while the `LoopInfo` that OWNS those `Loop` objects was
per-function — a dangling pointer whose next-function allocation re-use made `insert(L).second` return
false for a DIFFERENT loop in a DIFFERENT function, skipping BOTH conjuncts. It is now declared inside
the per-function body and keyed on `L->getHeader()`, and it is **two** sets (`AskedEscape`,
`AskedMarking`) because the conjuncts cover different entries and one shared set would let the cheaper
entry suppress the stricter one's check. `FIX_W_R1.md` has the four controls.

**(d) Does it GROW the taint set?** No. Nothing here creates a value, RAUWs anything, or inserts an
instruction; `adjudicateTaintDelta` is not owed. (`emitInPlaceRotationRegion` does, exactly as it already
did for the flat and loop-carried classes — unchanged by this increment.)

---

## 4. L2 — when you widen a set, ask what OTHER set was computed over the same closure

The brief names nine sites. Per site:

| site | widened? | why |
|---|---|---|
| `collectRailGates`' `Gates` (`LoopLowering.cpp:905-914`) | **no** | it is built from a claimed CHAIN's `Members`, and a clause-(c) loop has no claimed chain (no header φ ⇒ `Collapse` is empty ⇒ `NotClaimed`). It is never asked about these loops. |
| `collectRailGates`' `OnRailOut` (`:975-976`) | **no** | same closure, same reason. |
| the `MemberSet` skip (`:1045`) | **no** | same. |
| step-5 `Skip` (`:2806-2807`) | **no** | inside `collapseRailPhisIn`, which returns `NotClaimed` before reaching it. |
| R6 (`ArmClassify` `:4415`) | **no** | it enumerates `BaseWireOrder`, which clause (c) READS and does not extend. Its per-activation certificate (`recordLivePerActivation`) already fires for `Region.InLoop`, and clause (c) does not change `Region.InLoop`. |
| `railWireNamesBackward` (`:2256-2258`) | **no** | rung (ii)'s closure; unchanged. More REGIONS now reach it (in-loop rail ones), which is the correct direction — its per-activation barrier was written for exactly the iteration-local register (F-B1-1). |
| `railWireClosure` (`:563-598`) | **no** | unchanged; clause (c) consumes `BaseWireOrder` as built. |
| `reverifyRailCondReads` (`:2571`) | **no** predicate change; MORE entries | the in-loop rail regions now record their `markRailCondRead`, so the re-verification asks its two rungs about them. Monotone toward decline. |
| **NEW** `taint.IterationLocalBlocks` | **read, never written, by this increment** | and the reading is the whole point of §3's conjunct 2. |

**The one set this increment DOES widen is the set of regions R7 makes `Rollable`**, and the L2 question
about it is: what else is computed over "the region is in a loop"? Answer: R6's predicate choice
(`Region.InLoop ? recordLivePerActivation : provablyBefore/cannotFollowGate`), which is keyed on
`Region.InLoop` and NOT on `Rollable` — so it already applied to every one of these regions before this
increment, at the point they declined. Nothing else reads `Rollable`; it is a local.

---

## 5. L4 — a wire question must be a gate SET, not a BOOLEAN over a return-first walker

Clause (c3)'s body (`iterationLocalTaintEscape`) **returns the first offending instruction**, which is the
shape L4 warns about. It is sound HERE and the difference is the question: L4's subject is *"is any
non-diagonal gate VISIBLE?"*, where an already-ACCEPTED gate placed in front of an unaccepted one defeats a
first-hit walker because some gates are EXEMPT. **(c3) has no exemption at all** — every tainted value
defined in `L` owes the same obligation, there is no per-entry `WireRuled` bit to carry, and the predicate
is a pure ∀. A first hit is therefore a complete answer to "∃ a violator", and enumerating would change
nothing but the diagnostic text. Recorded rather than assumed: **if an exemption is ever added to (c3) — the
obvious candidate is the on-rail exemption `markIfRailLocal` has — it must become a SET and a difference,
and this paragraph is its retirement trigger.**

⚠ **WIDENED AFTER REVIEW ROUND 1: the trigger named the EXEMPTION SET and not the CLOSURE, which is L2's
half of the same question.** (c3)'s ∀ ranges over `L->blocks() × taint.Tainted`; either moving is the
same hazard — the subloop inclusion (`L->blocks()` deliberately includes strictly deeper blocks today)
or the TAINT ROUND the caller asks it at. "Widen a set, ask what OTHER set was computed over the same
closure" is 8h7d.5's F-1/F-3 shape verbatim. The contract on `iterationLocalTaintEscape` (`LoopPlan.h`)
now carries both limbs.

---

## 6. `staleRailRecordRead`'s grouping key, with its probe

**The brief's question:** its ROOT-MINT grouping (`ChainsByRoot` `LoopLowering.cpp:2525`, `ByRoot` `:2296`)
has no key for an iteration-local rail — two chains from one mint are one register and must interfere; two
mints must not. **What does the grouping key become?**

**Measured answer: it does not become anything, because `staleRailRecordRead` is NEVER ASKED about a
clause-(c) rail, and that is structural rather than lucky.** Both call sites reach it only through a
CLAIMED chain: round 1 via `tryCaseA`'s `railRoot` fixpoint and round 2 via `collapseRailPhisIn`'s
`ChainsByRoot`, and both enumerate chains built from a TAINTED HEADER φ. Clause (c1) proves there is none
for this rail. So the fence has no subject, and inventing a key `(mint, activation)` for it would be a
predicate with no reader — the bd `3d8q`-style hazard of a second spelling nobody calls.

**The obligation the fence would have carried is discharged by a different structure, and this is the part
to check:** the fence exists because one physical register can wear several SSA names ACROSS ACTIVATIONS, so
a record defined on trip *k* may be read after a gate on trip *k+1*. An iteration-local rail is a DIFFERENT
PHYSICAL REGISTER each trip (a fresh `cqrt_alloc` per activation, clause (c2)), so no name can span two
activations — **unless it escapes the loop, which is exactly what clause (c3) refuses.** (c3) is therefore
the iteration-local analogue of the grouping key: instead of asking *"do these two names denote one
register?"* it makes the question unaskable by confining every name to one activation.

**The probe the brief asks for — two iteration-local rails that must NOT interfere:**
`probes/w_k_two_iterlocal_rails.c`, two independent per-trip registers under one `_Bool`, each measured in
the body. Its per-trip stream must show TWO independent `alloc → ry → cry` triples with no gate of one
appearing between the other's mint and its measure, and it must be byte-identical to its hand-unrolled twin.

---

## 8. The fixture table (Rule 12), and the mutation MISSED count

### 8.1 lit fixtures — 3 FLIPPED, 3 new accepts, 8 new declines

| file | was | is | pins |
|---|---|---|---|
| `control_inplace_ry_rail_inloop.ll` *(renamed from `…_reject_rail_inloop.ll`)* | DECLINE | **ACCEPT** | the headline customer; one `cqrt_ry_i32_controlled` per activation in the surviving loop block, and a PURE negative prefix proving a rail condition mints NOTHING (no `cq_template_`, no `cqrt_x`, no `cqrt_free`, no `cqrt_cnot`, no route) |
| `control_inplace_ry_inloop_iterlocal_base.ll` *(renamed)* | DECLINE | **ACCEPT** | clause (c) with a compare condition; the ALLOC IS INSIDE THE LOOP |
| `control_inplace_ry_stateprep_inloop_iterlocal.ll` *(renamed)* | DECLINE | **ACCEPT** | clause (c)'s `MintSeed = T` branch; `cqrt_alloc_i32(0)` inside the body |
| `control_inplace_ry_rail_inloop_negated.ll` | — | ACCEPT | the Ry ADDITIVITY pair per activation, unconditional gate first; never a `cqrt_x` on a user register |
| `control_inplace_ry_inloop_iterlocal_no_root.ll` | — | ACCEPT | a loop with NO loop-invariant tainted register: `markIfRailLocal` is never called and it does not matter, because the body has no spine-discharge candidate |
| `control_inplace_ry_reject_inloop_iterlocal_no_root_derived.ll` | — | DECLINE | its DISCRIMINATING SIBLING — one `&` away, a `cq_template_and_*` rail per trip, no marking, so the round-2 re-ask refuses |
| `control_inplace_ry_reject_inloop_iterlocal_escape.ll` | — | DECLINE | **clause (c3)**, with the measured 19-vs-27 divergence in its header |
| `control_inplace_ry_reject_inloop_iterlocal_outside_mint.ll` | — | DECLINE | **clause (c2)**: no header φ AND the mint is outside `L` — neither (b′) nor (c) claims it, which is the right answer (K in-place mutators on one rail = Rule-8 fan-out) |
| `control_inplace_ry_reject_inloop_iterlocal_derived_mint.ll` | — | DECLINE | **clause (c2)**: the iteration-local base is a DERIVED out-of-place value — PRD §13.2 row DB's iteration-local twin |
| `control_inplace_ry_reject_rail_inloop_multilatch.ll` | — | DECLINE | CFG gate (C) still refuses a rail region |
| `control_inplace_ry_reject_rail_inloop_nested.ll` | — | DECLINE | CFG gate (B) still refuses a rail region |
| `control_inplace_ry_reject_rail_inloop_tainted_exit.ll` | — | DECLINE `loop under quantum control` | **Q1 stays unconditional**, and the STRING pins the ORDER (`lowerLoops` runs before detection; the message is the loop layer's, not the control layer's) |
| `control_inplace_ry_reject_rail_inloop_tainted_angle.ll` | — | DECLINE `rotation angle …` | R2 sits ABOVE R7, so the angle axis is unmoved — a discriminator, not a second copy of the loop reject |
| `control_inplace_ry_reject_inloop_derived_base.ll` | DECLINE | DECLINE (unchanged) | clause (c1): a header φ that (b′) REFUSED is still a CARRIED rail, and `Rollable == false` is not the same statement as "iteration-local" |
| `control_inplace_ry_reject_stateprep_inloop_carried.ll` | DECLINE | DECLINE (unchanged) | F1 still kills the loop-CARRIED prep as a no-cloning mux, before R7 |

⚠ **Three files were `git mv`'d.** CLAUDE.md L8 records that a MERGE CAN RESURRECT a renamed fixture, leaving
one module under two names with contradictory verdicts and invisible to every review that ran before the
merge. **The merge-and-gate agent owes a duplicate-body scan** (sha-256 over each fixture's non-comment
lines) after merging this branch.

### 8.1a Review round 1 — THREE MORE FIXTURES, and the axis they open

⚠ **The reason two silent miscompiles survived 1937 fixtures, 15 e2e entries, a complete corpus sweep, a
0-MISSED injection matrix and 328 twin cells is sharper than "one function per module".** Several
fixtures here DO carry two `define`s — `-O1` inlines `slice` into `@main`, and
`control_inplace_ry_inloop_iterlocal_no_root.ll` is one of them. But both copies get the **SAME
disposition**, so a per-loop dedup that silently suppressed the second function's check had nothing to
bite on. **The axis that was missing is a module whose two loops want DIFFERENT verdicts.**

| file | verdict | pins |
|---|---|---|
| `control_inplace_ry_reject_inloop_iterlocal_twofn.ll` | DECLINE | F-W1-1. `b6_noattr`'s module — TWO ORDINARY KERNELS, no `noinline`, no attribute of any kind. ACCEPTED at 40 lines on `daeb93a3` with `and_hl` ×2 / `and_hl_unc` ×0. Its two halves already ship as single-function fixtures and are green either way; what this adds is the MIXED pair |
| `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll` | DECLINE | F-W1-2. The clause-(b′) rail region with no record: ACCEPT 30 vs twin 34 on `daeb93a3`, ORACLE refused. Header carries the ROUTE (the loop-invariant tainted read trips `markIfRailLocal`'s "accumulating" clause) so nobody re-bisects it |
| `control_inplace_ry_inloop_twofn_mixed_clauses.ll` | **ACCEPT** | the POSITIVE control for both fixes — clause (c) and clause (b′) in ONE module, both still lowering. ORACLE DECLINE → 22 trace lines, BYTE-IDENTICAL to `probes/w_l_twofn_mixed_clauses_unrolled.c`. Injection matrix `applied 8 / MISSED 0 / N/A 1` |

⚠ **An instrument lesson from validating them:** `vacuity.py`'s (V2) half ("is this construct reachable
at all?") is only as good as the `--universe` it is given. A six-module universe reported **2 false
VACUOUS** for `cqrt_x` and `cqrt_cswap`; widening it by two modules that actually emit them gives
**0 VACUOUS of 5**. A checker that answers from too small a corpus reports a hole where there is none —
and, run the other way, would miss one.

### 8.2 e2e — 10 slices + 5 twin gates

Five ROLLED/HAND-UNROLLED pairs, each with a `compare_files` twin gate, all STRICT stage 2b:
`…inplace_ry_bool_loop`, `…inplace_ry_bool_loop_grover`, `…inplace_ry_bool_loop_iterlocal`,
`…stateprep_bool_loop_iterlocal`, `…inplace_ry_loop_iterlocal_derived`.
`ran: ctest -R '^e2e-…bool-loop…' → 100% tests passed, 0 tests failed out of 15` (146.40 s).

### 8.3 Rule-12 hygiene, all three shipped defects

* **(a) counts in their own whole-file prefix** — every fixture puts its `CHECK-COUNT`s in a `COUNT` prefix
  of its own, never inline among positives and never inside a negative prefix. (A positive `CHECK-COUNT`
  inside a negative prefix WINDOWS every negative after it; that shipped once and was caught by 0 of 20
  blocks.)
* **(b) a decline fixture's IR-text `CHECK-NOT`s are VACUOUS** — every new decline fixture says so in its own
  header and pins its property with the `not` inversion on the RUN line plus a character-for-character string.
* **(c) validate by MUTATION** — §8.4.

### 8.4 The injection matrix: **MISSED 0**

`ran: python3 probes/impl/inject.py <the 5 new accept fixtures>` on `95a33b2ea04155d1`:
**`TOTAL applied 40   MISSED 0   N/A 5`** (`probes/impl/injection_matrix_95a33b2e.txt`).

Nine mutations: `alloc-hoisted-out-of-loop` (the central clause-(c2) hazard — one shared rail instead of K
fresh ones), `controlled-ry-uncontrolled`, `cry-control-target-swapped`, `cry-angle-negated`,
`x-on-condition-rail`, `free-on-condition-rail`, `unc-discharge-dropped`, `controlled-ry-deleted`,
`cqrt_cswap-injected`.

⚠ **PROTOCOL.md S3: "a mutation harness that reports `n/a` is a HOLE, not a pass."** All five N/As, explained:

| N/A | fixtures | why it is a genuine absence |
|---|---|---|
| `alloc-hoisted-out-of-loop` | `rail_inloop`, `rail_inloop_negated` | their rails are LOOP-CARRIED — minted once in the entry block by design (clause (b)/(b′)), so there is no per-trip alloc to hoist. The mutation is meaningful only for a clause-(c) shape, and it is CAUGHT on all three of those. |
| `unc-discharge-dropped` | `rail_inloop`, `rail_inloop_negated`, `iterlocal_no_root` | a rail condition mints no `cq_template_*`, so there is no `_unc` to drop. **That absence IS the increment's central claim**, and it is independently pinned by each file's pure negative prefix (`NOMINT-NOT: cq_template_` / `NOBRACKET-NOT: cq_template_`). |

⚠ **THE HARNESS LIED TWICE BEFORE IT TOLD THE TRUTH, and both lies were in the MISSED direction** — worth
recording because PROTOCOL.md S3 says an instrument is likelier to be wrong than its subject. (1) The first
`alloc-hoisted` spelling took the FIRST `cqrt_alloc` in the module, which on every fixture is the ENTRY
block's, so it re-inserted a line where it already was: **2 MISSED** that were no-ops. (2) The second scoped
"is it in a loop?" to "some `br` precedes it" over the WHOLE MODULE, so in a two-function fixture `@main`'s
entry alloc looked in-loop and the mutation moved it ACROSS a function boundary — invalid IR that FileCheck
accepts: **2 MISSED** that were the harness's. Both bounds are now the enclosing `define … { … }`, and the
`br` test allows the function's first line (a third spelling missed a loop whose entry block is a bare
`br label %loop`).

### 8.5 Vacuity — **0 VACUOUS of 29**

⚠ The inherited `$PREV/trackM/probes/impl/vacuity.py` reported **`checked 0`** on this batch, which S3 calls
a HOLE. It matches only a negative naming an SSA HANDLE (`; NOX-NOT: … (i32 %h)`), and every negative here
names a SYMBOL. The Track W script asks the same question in two halves — (V1) does the pattern match the
module's own `ModuleID`/`source_filename` line (bd `qta2`), and (V2) does it name a construct this compiler
can emit at all, checked against a universe of six lowered modules — with ONE documented exclusion: a
`-NOT` naming a FRONT-END intrinsic (`@cq_theta_`, `@cq_phi_`, `@cq_measure_`) pins the pass's own
postcondition (`declineSurvivingIntrinsicCalls`), so it appears in no lowered module BY CONSTRUCTION and its
absence is what it asserts. `ran: 29 named negatives across 5 accept fixtures, 0 VACUOUS`.

---

## 7. THE ATTACK SURFACE — for the Rule-13 reviewer

**Rule-13 round budget: THREE, stated up front**, and I expect the next round to find something (CLAUDE.md's
measured hit rate: 7.4 `break` 13 holes over 3 rounds, three of them AFTER the epic was closed as cleared;
3qlq Inc 1's C-1 family 8 over 6 rounds on one function, two introduced by a fix). Round 1 should be scoped
to §7.2 alone.

### 7.1 Every predicate touched

1. `ArmClassify.cpp` — the `RailCond && Region.InLoop` carve REMOVED. Pure widening: the set it refused was
   previously 100% declining.
2. `ArmClassify.cpp` — new `iterationLocalRollable` (c1/c2/c3) and the `Rollable` disjunct. Pure widening for
   the same reason.
3. `ArmClassify.cpp` — a new WRITE into `TaintSet` (`RolledIterLocalGates`) from a classifier.
4. `LoopLowering.cpp` — `railPhiRootMint`'s tail factored into `railChainRootMint`. ⚠ **The one edit that can
   move a PRE-EXISTING disposition.** Two defensive conjuncts are new (`!V` and `arg_size() < 1`); both are
   monotone toward decline and both are unreachable for a validated `cq_theta_*`/`cq_phi_*` prototype. The
   corpus sweep is what proves no shipped module moved.
5. `LoopLowering.cpp` — new `iterationLocalTaintEscape` (pure, no caller before this increment).
6. `LoopLowering.cpp` — new `declineUnmarkedRolledIterLocal` (a no-op unless `RolledIterLocalGates` is
   non-empty, which only (2) writes).
7. `CQLoweringPass.cpp` — two call sites for (6).

### 7.2 The three programs I think are most likely to be the next hole

* **H-1 — A CLAUSE-(c) LOOP WITH A SECOND, STILL-STANDING TAINTED BRANCH.** `markIfRailLocal`'s (L2) clause
  refuses the whole marking when any body block still has a tainted conditional branch. Two sequential
  in-loop regions are ordered by `hcrg`'s precedence graph, so both should be flattened — but a region the
  plan DECLINED to order, or an onward round-2 region flattened after the marking, leaves one standing.
  My conjunct 2 should turn that into a loud decline; the hole is if the marking was GRANTED at round 1 and
  the second branch appears only at round 2 (marking is additive and never withdrawn). I did not build this
  probe; it is the sharpest residual.
* **H-2 — THE MIXED LOOP: a clause-(c) rail beside a loop-CARRIED one whose exit value is read.** (c3) with
  the empty exemption set refuses it, so it is an OVER-decline today (safe) — but the moment anyone widens
  (c3) to a real root set to fix that, the monotonicity argument in §3 inverts and a wrong `Roots` prediction
  becomes an UNDER-decline. Filed, not built.
* **H-3 — `railChainRootMint` AND A `cq_phi` MINT. ADJUDICATED UNREACHABLE IN ROUND 1, ON A STRONGER
  GROUND THAN I GAVE, and the better ground is now the one recorded in the source.** I argued "a `void`
  call cannot be the base of an `i32` rail". The mechanism is more specific: `peelInPlaceStep` steps
  THROUGH a `GateCalls` member only when `CI->getArgOperand(0)` is TAINTED, and for the register-free
  `void cq_phi(double)` arg-0 is the untainted ANGLE — so the peel **stops at** a `cq_phi` instead of
  walking past it, and `railChainRootMint` can only RETURN one if it was the input `V` itself. Both
  callers pass a REGISTER-TYPED value (`railPhiRootMint` a φ incoming; clause (c2) `RotBase` or `T`), and
  a `void` call is never an operand of anything. Still no fixture — an unreachable negative is VACUOUS
  (PROTOCOL S3). Two consequences recorded at the code: the `starts_with("cq_theta_")` test in (c2) is
  **dead today**, and its retirement trigger names what makes it live (a `cq_phi` acquiring a register
  operand — a Key Prohibition, but so was the retired `cq_phi_<sfx>` family), at which point
  `railPhiRootMint`, which does NOT have the test, needs it too.

### 7.4 The DIAGNOSTIC ANCHOR on every path that can emit my string

The Track P lesson: a diagnostic that loses its `!dbg` reports `<unknown>:0:0` and is invisible to every gate
this project runs except a full-stderr hash — one shipped past a green 1946-fixture lit run, a 0-MISSED
injection matrix and a byte-identical 288-cell family. Three paths in this increment can emit
`control flow inside a loop body`, and each one's anchor, MEASURED with `-g`:

| path | anchor | measured |
|---|---|---|
| `ArmClassify` R7 `if (!Rollable)` | `declAnchor(Region)` — UNCHANGED from before this increment | the region's condition (`w_a` on the ORACLE: `…:8:14`) |
| `declineUnmarkedRolledIterLocal`, conjunct 2 (the marking postcondition) | `I`, the HOISTED arm gate — always a SOURCE `@cq_theta` | `w_j_no_invariant_root_derived.c:13:31`, the `(u >> 1) & 1` line |
| `declineUnmarkedRolledIterLocal`, conjunct 1 (the (c3) re-ask) | `Esc` if it has a `DebugLoc`, **else `I`** | the fallback is deliberate: `Esc` is whatever `iterationLocalTaintEscape` found first, and the pass MANUFACTURES tainted values with no `!dbg` (`MergePhiPeel`'s compare clones, `AngleSelectEmit`'s twin rotation) |
| `declineUnmarkedRolledIterLocal`, no enclosing loop | `I` | same anchor |

Without `-g` every one of them reports `<unknown>:0:0` — as does **every** diagnostic in this pass, because
the `!dbg` only exists when the user compiles with `-g`, and the e2e pipeline does. That is not the Track P
defect, which was a path that lost a `!dbg` THAT EXISTED.

⚠ **A PRE-EXISTING instance of the Track P defect, found in passing and NOT mine to fix:** `w_c_compare_invariant`
compiled WITH `-g` declines `condition predates a non-diagonal gate` at `<unknown>:0:0` — the LICM-hoisted
invariant compare (row W). `condWireDisposition`'s decline there anchors on a value with no location while
the module has plenty. Same for `w_e`/`w_f`/`w_h`. Worth a bead against row W's owner.

### 7.3 What I deliberately did NOT do

* **No `condWireDisposition` / P4 change**, so CLAUDE.md row W (the LICM-hoisted invariant COMPARE) is
  untouched and `w_c_compare_invariant` still declines `condition predates a non-diagonal gate`. This
  increment fixes the RAIL spelling and does not reach the compare one.
* **Q1 stays unconditional.** No quantum-dependent trip count is lowered as a loop; the Rule-18 bound
  derivation (bd `m57l`) is not built. Pinned by `control_inplace_ry_reject_rail_inloop_tainted_exit.ll`.
* **Rule 6/7 unchanged.** Every rotated register under control is FROZEN — never reverse-played, never
  freed; the condition register is left allocated (`Ry(θ)|0⟩ ≠ |0⟩`). No new `cqrt_*` symbol, no ABI change,
  no `tools/opcode_table.yaml` edit.
* **`tools/loop_twin_matrix*` NOT TOUCHED** — Track T owns it for the duration. See §9 for the cells I need.

---

## 9. THE TWIN MATRIX — a PREDICTION that is a MEASUREMENT, on all 40 `i1` cells

Track T landed the `i1` axis (`twin-matrix-bool`, tip `c12a2afe`, 288 → 328 cells, its binary
bit-identical to the session ORACLE). I did **not** run the matrix and did **not** touch
`tools/loop_twin_matrix*`. Instead I **reconstructed all 40 `i1` cell sources by hand from Track T's own
generator** (`_wrap`, `B_COND_TEXT`, `B_ARM_TEXT`, `BCARRY`, `RECORD_B`, `PREFIX`/`SUFFIX`/`PRELOOP`,
`TRIPS = 2`, `HDR`) into `probes/cells/`, and ran each rolled/unrolled pair through BOTH binaries — the
frozen ORACLE `f7b65d8c…` and the subject — comparing the linked **trace md5**. That turns the prediction
the coordinator asked for into a measurement.

⚠ **AUTHORITY: the merge gate's run, not this table.** My sources are a hand reconstruction and could differ
from the generator's in an axis I misread. The VERDICTS are what I claim; a per-cell name mismatch is mine.

| ORACLE verdict | cells | arm | SUBJECT verdict | count |
|---|---|---|---|---|
| **UNROLLED-ONLY** | B1 `{b,nb}ry × {binv,bcar}`, B2 `bry_{pre,post}`, B4 `bry_addpre`, B5 `bry × {binv,bcar}` | `ry` | **ACCEPT-IDENTICAL** | **9** |
| **DECLINE-BOTH-DIFFERENT** | B1 `{b,nb}prep × {binv,bcar}`, B2 `bprep_{pre,post}`, B5 `bprep × {binv,bcar}` | `prep` | **DECLINE-BOTH** — rolled adopts the FLAT message `state prep merged with a quantum register` | **8** |
| **ACCEPT-IDENTICAL** | B1 `{b,nb,ab}phi × {binv,bcar}`, B2 `bphi_{pre,post}`, B4 `bphi_addpre` | `phi` | **UNCHANGED, md5 for md5 on both sides** | **9** |
| unchanged | B1 `ab{ry,prep} × {binv,bcar}` (DECLINE-BOTH `control flow`), B1+B3 `val` ×8, B6 `absphi` (DECLINE-BOTH `nested control flow`) / `ablphi` (UNROLLED-ONLY, the recorded LICM over-decline) | — | **UNCHANGED** | **14** |

**40 of 40. Net after the landing: 18 ACCEPT-IDENTICAL, 6 UNROLLED-ONLY, 3 DECLINE-BOTH-DIFFERENT, 13 DECLINE-BOTH.**

### 9.1 The `prep` TRAP — measured, and it is a PASS

The coordinator's warning is the most important thing in this section: for the 8 `prep` rows **only
`DECLINE-BOTH` is a passing flip and `ROLLED-ONLY` is an OVER-ACCEPT**, because the FLAT twin declines for a
reason STRUCTURAL to a twin with TRIPS > 1 — repetition 2's pred incoming is repetition 1's MERGE φ, i.e.
F1's no-cloning mux.

**All 8 take the passing move, and the mechanism is a fence doing its job rather than luck.** Retiring the
l4x4.b carve-out means the rolled prep region now REACHES F1 instead of dying at the rail gate — and F1
refuses it for exactly the flat side's reason, because the rolled form's own straight-through incoming is
the header φ of `r`, which is quantum after trip 1. That is `control_inplace_ry_reject_stateprep_inloop_carried.ll`
(unchanged, still pinned), and the string moves from `control flow inside a loop body` to
`state prep merged with a quantum register` — a decline that now names the real defect instead of the
scaffolding. It is also why the in-loop prep that DOES lower
(`control_inplace_ry_stateprep_inloop_iterlocal.ll`, `slice_control_stateprep_bool_loop_iterlocal.c`) is the
ITERATION-LOCAL one: `int r = 7;` INSIDE the body, where the Pred incoming is the `Constant` seed on every
trip. **The matrix's `prep` arm declares `r` outside the loop and is therefore the carried spelling, not the
one clause (c) admits.** One `{`-position between the two, two dispositions.

### 9.2 The `&&` correction — checked, and none of my probes hit it

`grep '&&'` over every Track W probe, slice and fixture: **one hit, and it is inside a C comment** quoting
the predicate `RailCond && Region.InLoop`. Every compound condition I wrote is BITWISE (`(q >> k) & 1`),
which is the spelling Track T had to switch the generator to. Measured independently by B6 above:
`abs` (`&&` + a volatile operand) is handed to the pass as a genuine NEST on both binaries, and `abl` (`&&`
+ a literal) is LICM-hoisted out of the rolled loop — neither is the shape I meant anywhere.

### 9.3 Cells I would still like (beyond the 40)

Track T's 40 cover my subject's LOOP-CARRIED half completely. What no cell reaches is **clause (c), the
ITERATION-LOCAL rail** — every `B_ARM` declares its second register OUTSIDE the loop, so `r` is carried in
all 40. The cells that would witness clause (c), for the merge gate to generate with a written reason:

| # | cell | why |
|---|---|---|
| **W-1** | a `B_SECOND` value `"iterlocal"` — `int r` declared and seeded INSIDE the body — crossed with `{b, nb}` × `{binv, bcar}` (4) | clause (c2): K activations must mint K rails |
| **W-2** | the same with `prep` (the arm's `cq_theta` classical, `r` declared in the body) (2) | clause (c2)'s `MintSeed = T` branch — the shape that DOES lower, as opposed to the carried one the 8 `prep` cells hold |
| **W-3** | W-1 with a DERIVED condition (`(a >> i) & 1`) instead of the bare rail (2) | the ONLY family that mints TEMPLATE rails in the body, i.e. the only one that can see a missing SPINE discharge — clause (c3)'s subject |
| **W-4** | W-3 with the per-trip register read AFTER the loop (1) | the measured 19-vs-27 divergence; must report DECLINE-BOTH or ROLLED-ONLY-is-a-red |
| **W-5** | W-1 with TWO iteration-local rails in one body (1) | `staleRailRecordRead` non-interference (§6) |

⚠ **Expect the widened matrix to say things about `i1` that no previous gate could**, including about
already-shipped FLAT rail accepts. A divergence in a cell that does not involve a loop is not this
increment's — check it against the ORACLE before attributing it.

---

## 9b. (superseded by §9.3 — the cell list moved there once the 40 existing cells were measured)

## 10. What I could not do, and what stays filed

* **Row W (bd `drbq.12`) is NOT fixed and this increment does not reach it.** The COMPARE spelling of the
  headline customer declines `condition predates a non-diagonal gate` because `-O1` LICM-hoists a
  loop-invariant compare and `condWireDisposition`'s P4 prong refuses a cross-block condition. Re-measured on
  the ORACLE (`w_c_compare_invariant`) and unchanged on the subject. Fixing it is a `condWireDisposition`
  increment, not a loop one.
* **The iteration-local shapes with a plain COMPARE condition (`w_e`, `w_f`) still decline**, and NOT at any
  clause of mine: both die at the same `condition predates a non-diagonal gate` wire fence, **in their
  HAND-UNROLLED form too** (measured on the ORACLE). So for those two shapes no twin oracle exists at all,
  and I did not widen anything toward them. Track L's W2 customer (`L1_promoted_nostore.c`) is of that family.
* **The MIXED loop over-decline** (a clause-(c) rail beside a loop-carried one whose exit value is read) —
  §7.2 H-2. Deliberate: predicting `Roots` at detection is a second spelling of two functions' claim
  conditions, and a wrong prediction inverts §3's monotonicity.
* **The twin matrix** — Track T owns `tools/loop_twin_matrix*` for the duration; §9 names the cells.
