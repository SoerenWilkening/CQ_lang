# IMPL — narrowing F2 by excluding the condition's own wire closure

**Implementation record.** Branch `f2-condwire-narrowing`, worktree
`/Users/sorenwilkening/Desktop/CQ_f2`, from `main` 0c7380c. **Not committed, not
pushed.** The frozen ORACLE for every A/B below is
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` at `main` 0c7380c,
read-only; nothing under that checkout was built or written.

Owner ruling 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also WE DO
NOT WANT ANOTHER cq function. it should just be an application of gates … I dont
see the need for the over-decline."*

> **Bottom line.** (a) The change is **ONE conjunct** plus a 6-line set builder
> plus the DELETION of the now-dead literal fast path; net non-comment delta is
> **+9 / −17 lines**. (b) **19 flip / 21 stay, exactly as SCOPE §3 predicted,
> cell for cell.** (c) The three measurable hazards were measured, and **two of
> the three came back different from what was predicted or inferred, in the
> informative direction**: the anchor spelling flips all 40 *and* the three
> `Truncated` cells with them (H-6/H-8 — worse than SCOPE predicted, and a second
> independent reason for the test spelling); `railWireClosure` is load-bearing
> for exactly one shape, which **corrects SCOPE §2.1's claim** that the two set
> spellings are equal (H-3); and one tripwire fixture I had *inferred* was red on
> the anchor mutant is in fact green, for a reason that strengthens the argument
> (§2b). (d) **The owner's `grover_oracle_uncompute.c` still
> declines**, at `control flow` — F2 was wall 3 of 3 and only wall 3 moved.
> (e) The H-2 state-vector argument **holds**; §7 records why, and records the
> one place it is weaker than the α theorem.

---

## §0 MEASURE-FIRST — SCOPE §0's table, re-run on this build BEFORE coding

Build: `cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
-DCMAKE_BUILD_TYPE=Release && cmake --build build -j8` (BOTH targets).

| probe | my build, PRE-change | ORACLE (`main` 0c7380c) | agree? |
|---|---|---|---|
| `V0.c` (the owner's file, verbatim) | rc 1 `control flow` | rc 1 `control flow` | ✓ |
| `C2.c` (V0 minus one `cq_measure`; ONE phi) | rc 1 `bare i1 register condition` | same | ✓ |
| `M1.c` (bare-rail `_Bool` prep) | rc 1 `bare i1 register condition` | same | ✓ |
| `M2.c` (the same under an **`int` compare**) | rc 1 **F2** | same | ✓ |
| `M3.c` (`int` seed, `int` compare) | **rc 0** | **rc 0** | ✓ |
| `mp.c` (two preps → two merge phis) | rc 1 `control flow` | same | ✓ |
| `alt/rail_cond_i1.ll` | rc 1 `bare i1 register condition` | same | ✓ |

All **40** fixtures carrying `state prep seed is proven equal to the condition
register` declined on the pre-change build (measured by loop, not assumed), and
the §2.2 fence audit reproduced 15/15 on `u*/v*/w*.c` and 21/21 on `alt/`.

---

## §1 THE CHANGE

Three edits, all in `ir-pass/src/ArmClassify.cpp`. Nothing else in `ir-pass/`,
`include/`, `runtime/`, `tools/` was touched. **No new runtime symbol, no YAML
row, no header change** (the owner refused a new `cq_*` function).

**1a. The signature** — `ArmClassify.cpp:1301`:
```cpp
bool f2SeedPinnedByLiveRegister(const ControlRegion &Region, Constant *Seed,
                                TaintSet &Taint, const DominatorTree *DT,
                                const SmallPtrSetImpl<Value *> &CondWire,  // NEW
                                bool &Truncated)
```

**1b. The ONE conjunct, at the equality TEST** — `ArmClassify.cpp:1475`:
```cpp
      if (V->getType() == Seed->getType() && !CondWire.count(V) &&
          f2Exact(V, S) == Seed)
        return true;
```
`V` is still popped from the worklist and its users are still modelled by
`f2Model` below, so the exclusion filters an ANSWER and never prunes a SEED.
That is SCOPE H-6 and it is the single most important line in this increment;
§2b measures what the alternative costs.

**1c. The set builder, at the caller** — `ArmClassify.cpp:3153`:
```cpp
        SmallPtrSet<Value *, 16> CondWire;
        railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, nullptr,
                        nullptr, CondWire);
        for (Value *P : Prov)
          railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                          CondWire);
```
and the call at `:3165` passes it. `Prov` is `condProvenance(Region.Condition)`,
already in scope from `:2574`. Built **by calling R4's own helper** rather than
re-spelled (Rule 14; the drbq Inc-3 (b′) lesson) — and §2c measures that this is
not merely hygiene.

**1c-bis. WHAT `CondWire` ACTUALLY IS, and the one sentence the safety rests on**
(round-1 review item **I-3**; applied 2026-09-11). "The condition's own backward
wire" reads far narrower than the set is. `condProvenance` follows **every**
operand edge backward, stopping only at a `cq_theta` source, so `CondWire` is the
condition's whole backward **TAINTED CONE** — it contains values reached through
`mul`, `and`, `shl`, `load`, casts and templates whose physical **rails are
genuinely DISTINCT** from the condition's. Excluding those is therefore *not*
justified by "same rail". The cancellation, as a sentence:

> `CondWire` is **byte-identically the set R4 builds as `CondRails`** — the same
> helper, over the same `Prov`, with the same `Taint`, at the same program point,
> in the same `BackwardOnly` direction — so every value F2 stops colliding on is a
> value R4 would decline a rotation arm for, and the over-approximation in F2's
> exclusion set **cancels exactly** against the over-approximation in R4's
> refusal. The safety of this narrowing is an argument about the **equality of two
> sets**, not about physical rails.

The cancellation survives a *rival* module because a rival differs from the prep
module only in a FORWARD position (which register the arm rotates) while both
closures are `BackwardOnly`; it survives the `r9e5` round-2 taint window because
both sets are keyed on the same `Taint` and shrink together.

⚠ **RETIREMENT TRIGGER (I-3), the cheapest one here to trip by accident: if
`railWireClosure` as called by F2 and R4's `CondRails` ever DIVERGE — a different
helper, a different `WireDir`, a different seed set, an `Exclude` argument on one
side and not the other, or one call site "tidied" — this narrowing must be
RE-DERIVED FROM SCRATCH.** Nothing in the corpus would notice a small divergence
except `control_inplace_ry_stateprep_condwire_alias_accept.ll`, and that file pins
only the chained-theta hop (Q3 below). Landed in-source at
`ir-pass/src/ArmClassify.cpp:1233` (the set description + the cancellation) and
`:1256` (the trigger).

**1d. DELETED — the plain-literal fast path** (old `:3011-3028`, 17 lines): the
`dyn_cast<ICmpInst>(Region.Condition)` + `K->getValue() == SeedI->getValue()`
clause. Deleted with its rationale retired in writing at the site, not silently.

**Measured non-comment delta** (`git diff -U0`, comment lines filtered):
**+9 added / −17 removed**, in one file. The comment work is much larger —
`f2SeedPinnedByLiveRegister`'s header gains ~80 lines (the ruling, the R4
theorem, the retirement trigger, the test-not-anchor rule, the α/β disclosure),
the caller block gains the deletion's obituary, and `condProvenance`'s header
gains the H-3 two-consumer warning.

### 1d-bis. A stale retirement trigger the deletion left behind, closed

The pre-existing F2 block carried a trigger reading *"the day compound
conditions are admitted to ANY control accept path, the LVI half already handles
them … but the (a) fast path below does not — delete it rather than extend it."*
Deleting the fast path silently **satisfies half of it and leaves a trigger
pointing at code that no longer exists** — the exact rot this codebase's `fenv`
lesson is about. It is now marked discharged AND the surviving half is stated:
`CondWire` is seeded from `Region.Condition` plus `condProvenance` of it, and for
a compound condition "the condition's wire" would have to mean the union over the
TREE'S LEAVES. Nothing computes that, and no fixture can be written for it today
because compound conditions decline upstream. Whoever admits them owes this
clause a fresh red-green family rather than an assumption that it already works.

### 1e. `DS_Warning` — NOT ADDED, and SCOPE §5.4 is why

SCOPE recommends **no warning by default** and I implemented that
recommendation. Reason, restated so it is not mistaken for an omission: the
warning would fire on *every narrowed accept*, which is every Grover state prep
the ruling exists to make compile — including the owner's own program once
`b6ap`/`l4x4` land. A warning nobody can silence is one everybody learns to skim
(Rule 19's own argument about expensive attention). The disclosure lives instead
in (i) the CLAUDE.md ruling paragraph, (ii) the PRD §14 ERRATA block, (iii) every
flipped fixture's header, which names the rival AND cites its measured decline
string, and (iv) the three committed e2e slices. A flag-gated
`-cq-warn-folded-prep` remains an owner option; it is **not** in this tree.

### 1f. The `condProvenance` cross-reference (SCOPE H-3)

`condProvenance`'s in-source warning said narrowing it is a Rule-13 change to
**R4**. It now says it is a Rule-13 change to **R4 and F2**, and — this is the
part that needed writing rather than noting — that the two fail in **opposite
directions**: narrowing the cone makes R4 vacuous (a miscompile) and shrinks
F2's exclusion set (an over-decline, safe), while WIDENING it is harmless for R4
and an **over-accept for F2**. Before the ruling, widening this cone was a
decline-monotone tidy-up. It is not any more, and nothing in the tree said so.

---

## §2 THE FAST-PATH DELETION PROOF, AND THE TWO HAZARD MUTANTS

### 2a. M2a — the fast path is dead (SCOPE §5.1)

Mutant: the fast path DELETED **and** the `!CondWire.count(V)` conjunct
DISABLED, i.e. F2's pre-ruling semantics minus the fast path. `cq-opt` rebuilt;
all 40 F2 fixtures re-run.

```
M2a mutant (fast path DELETED, conjunct ABSENT) — all 40
total=40 declined=40
```

**All 40 still decline, `eqfold_coincidence` and `eqfold_coincidence_ne`
included** — the two fixtures whose headers named the fast path as the thing they
pinned. So the semantic test SUBSUMES it, the deletion removes no coverage, and
what the fast path would have contributed on the shipped tree is exactly the
19 declines the owner ruled must become accepts.

### 2b. M-A — the ANCHOR spelling (SCOPE H-6, the stated tripwire)

Mutant: `CondWire` members filtered out of `Cand` (both the `Argument` and the
`Instruction` loop) **and** out of the fp anchor's `f2NoteConst`, with the test
left unfiltered.

```
H-6 ANCHOR-spelling mutant — all 40
ACCEPT=40  DECLINE=0
still declining: (none)
```

**All 40 flip**, including the six F-R1-1 CONFIRMED plain-C miscompiles, the
30-program sideways family, the four curated-`llvm.*` rails and the three cast
rails.

⚠ **A SECOND RUN OF THIS MUTANT, AFTER THE NEW FIXTURES EXISTED, CORRECTED A
CLAIM I HAD INFERRED RATHER THAN MEASURED — and the correction is a BETTER
argument than the original.** I had written that the three named tripwire
fixtures are all red on the anchor spelling. Measured:

| fixture | anchor spelling |
|---|---|
| `..._reject_stateprep_fcmp_oeq_derived` | **rc 0** (flips) |
| `..._reject_stateprep_range_forward_add` | **rc 0** (flips) |
| `..._reject_stateprep_second_flag_i1` | **rc 0** (flips) |
| `..._reject_stateprep_offwire_sideways_min` | **rc 0** (flips) |
| `..._reject_stateprep_nonwire_still_collides` | **rc 1 — KEEPS declining** |

The last one does NOT flip, and the reason matters: its off-wire pin
`%t = lshr %q, 31` is one **LVI can answer about directly on the edge**, so `%t`
is its own `Cand` entry and never needed the forward walk from an on-wire seed.
The four that do flip are pins LVI cannot reach alone and that only the forward
evaluation produces. **So at the anchor, whether a given out-of-cone CONFIRMED
miscompile survives depends on whether LLVM's `LazyValueInfo` happens to model
that opcode** — the fence's coverage would be decided by an implementation detail
of another codebase, and would move silently as LLVM improves. At the TEST it
does not depend on that at all. That is a stronger reason to refuse the anchor
spelling than "it flips everything", and it is now written at the predicate's
header. `nonwire_still_collides` therefore remains a discriminator for the CONE
(pinned by its off-wire mutation, §3(C)) and is **not** an H-6 tripwire; its
header does not claim to be one. ⚠ **And something SCOPE predicted only as a principle turned out to be
measurable: the three `Truncated` cells flipped too** (`step_cap_over`,
`unevaluable_pinned_operand`, `unfoldable_curated_call`). A smaller candidate
list never trips the 4096-step bound, so at the anchor the CONSERVATIVE half —
the one that catches what LLVM's own machinery cannot evaluate — becomes
selectively skippable. That is SCOPE H-8 realised, and it is a second,
independent reason the exclusion must live at the test. Both facts are now
written at the predicate's header.

### 2c. M-W — `railWireClosure` is load-bearing (SCOPE H-3)

Mutant: `CondWire` built as `{Region.Condition} ∪ Prov` — i.e. the set
re-spelled by hand instead of by calling R4's helper.

```
M-W on alias_probe.ll:                          rc=1 (DECLINE)  [shipped: rc=0]
M-W over the state-prep family (109 files
  at that moment, before this increment's 8):   ACCEPT=53 DECLINE=56
shipped binary over the same 109:               ACCEPT=53 DECLINE=56
```

Two measurements, stated separately because they say different things: (i) the
probe module itself DECLINES under M-W and ACCEPTS on the shipped spelling, so
the `railWireClosure` calls are what accept it; (ii) the family's split is
IDENTICAL under both, so nothing else in the tree moves. Exactly **one** module
is the whole difference between the two spellings: the chained-theta rail hop.

⚠ **THIS CORRECTS SCOPE §2.1.** The scoping note argued that R4's condition reach
*is* `{Cond} ∪ condProvenance(Cond)`, "because every backward rail hop is also an
operand edge". That holds for every hop except ONE: `condProvenance` stops at a
theta (`if (isThetaCall(I)) continue;` — it collects the RESULT and deliberately
does not enter arg-0, so it cannot walk into a source theta's classical seed),
while `railWireClosure` crosses a CHAINED theta's arg-0 because a chained Ry is
in place and the two names denote ONE physical rail. So the union is a strict
superset of `{Cond} ∪ Prov`, by exactly the chained-theta ancestry. The
correction is recorded at the call site as well as here, because it is the
difference between "the `railWireClosure` calls are Rule-14 hygiene" (what SCOPE
implies) and "deleting them changes behaviour" (what is measured). The delta
between the two spellings is precisely `condProvenance`'s `if (isThetaCall(I))
continue;` — it collects a theta's RESULT and deliberately does not enter arg-0,
while `railWireClosure` crosses that edge because a chained Ry is in place and
`%t`/`%b` are ONE physical rail after `lowerRotations` RAUWs them. So the Rule-14
instruction "call R4's helper, never re-spell it" is not hygiene here; it is a
verdict. Committed as
`ir-pass/test/control_inplace_ry_stateprep_condwire_alias_accept.ll`, RED under
M-W.

---

## §3 THE 19 + 21

### (A) 19 flipped DECLINE → ACCEPT — measured, and it is SCOPE §3(A) cell for cell

Each was `git mv`'d `control_inplace_ry_reject_stateprep_<n>.ll` →
`control_inplace_ry_stateprep_<n>.ll` with **the IR BYTE-UNCHANGED — VERIFIED,
19/19**, by diffing the non-comment, non-blank lines of each new file against
`git show HEAD:<old path>` (0 differing). That matters because the whole claim
"this is the same module the four drbq Inc-4 adversarial rounds argued over"
rests on it; only RUN lines, assertions and the header moved, the original decline header kept verbatim
below a `---- HISTORY ----` rule, and a new block that (a) quotes the ruling,
(b) states which reading the IR now gets and which rival it silently absorbs,
(c) cites that rival's `probes/alt/` module and its decline string **measured on
the narrowed binary**, and (d) pins the emitted stream with count prefixes.

| # | fixture (`control_inplace_ry_stateprep_…`) | pin | edge | rival | oracle rc | new rc |
|---|---|---|---|---|---|---|
| 1 | `eqfold_coincidence` | `%q` | arm | α | 1 | **0** |
| 2 | `eqfold_coincidence_ne` | `%q` | straight | β | 1 | **0** |
| 3 | `eqfold_cast` | `%q` | arm | α | 1 | **0** |
| 4 | `eqfold_ne_else` | `%q` | arm | α | 1 | **0** |
| 5 | `eqfold_extremum` | `%q` | arm | α | 1 | **0** |
| 6 | `eqfold_derived_cond` | `%a = and %q,6` | arm | α | 1 | **0** |
| 7 | `eqfold_ult` | `%q` | arm | α | 1 | **0** |
| 8 | `range_mask1` | `%t = and %q,1` | arm | α | 1 | **0** |
| 9 | `range_a2_alias` | `%t = and %q,1` | straight | β | 1 | **0** |
| 10 | `range_ordered` | `%t = and %q,3` | arm | α | 1 | **0** |
| 11 | `range_knownbits` | `%b = zext %c0` | arm | α | 1 | **0** |
| 12 | `range_knownbits_enum` | `%t = and %q,4` | arm | α | 1 | **0** |
| 13 | `range_constleft_eq` | `%q` | arm | α | 1 | **0** |
| 14 | `range_constleft_ugt` | `%t = and %q,1` | arm | α | 1 | **0** |
| 15 | `i1_flag_pinned` | `%c` | straight | β | 1 | **0** |
| 16 | `i1_arm_flag` | `%c` | arm | α | 1 | **0** |
| 17 | `range_i1_both_edges` | `%q`/`%c` | straight | β | 1 | **0** |
| 18 | `fcmp_oeq_folded` | `%t` (fp anchor) | arm | α | 1 | **0** |
| 19 | `fcmp_une_folded` | `%t` (fp anchor) | arm | α | 1 | **0** |

Every emitted stream is the drbq Inc-4 prep stream, read off the pass output
rather than typed: `cqrt_alloc_<W>(SEED)` at the hoisted theta,
`cqrt_{ry}_<W>_controlled(f, h, θ)`, the ordinary `_unc` strip, ONE `cqrt_free`
(the flag's), the prepped rail FROZEN. **Six** carry a paired
`cqrt_x` bracket (measured: `eqfold_coincidence_ne`, `fcmp_une_folded`,
`range_constleft_ugt`, `range_knownbits_enum`, `range_knownbits`, `range_mask1`)
— the `!flag` polarity, where `clang -O1` canonicalises the compare and puts the
arm on the FALSE successor (Rule 9). The other thirteen emit none.

### (B) 21 that stay DECLINES — IR byte-unchanged, one paragraph added

`git diff` over these 21 files touches **comment lines only** (verified: the
diff filtered of `^[+-];` is empty). Each gained a `---- STILL A DECLINE AFTER
THE 2026-09-11 NARROWING ----` block saying *why*, because a surviving fence and
an accident look identical to the next reader.

| fixture (`control_inplace_ry_reject_stateprep_…`) | why still out of `CondWire` | oracle rc | new rc |
|---|---|---|---|
| `range_forward_add` / `_sub` / `_xor` / `_or` / `_lshr` / `_ashr` (6) | FORWARD user of a cone member; `CondWire` is `BackwardOnly` | 1 | 1 |
| `sideways_sdiv` / `sideways_offset` / `merge_edge_sideways` (3) | SIBLING — `-O1` moved the compare sideways; reachable in neither direction | 1 | 1 |
| `intrinsic_bswap` / `_bitreverse` / `_fshl` / `_fshr` (4) | forward, on a curated `llvm.*` rail | 1 | 1 |
| `cast_sext_live` / `_zext_live` / `_trunc_live` (3) | forward **and** type-disjoint from every cone member | 1 | 1 |
| `fp_seed_sitofp` | forward; no cone member has the seed's type | 1 | 1 |
| `fcmp_oeq_derived` | ONE HOP forward of the fp anchor's seed — the anchor still SEEDS (H-6 tripwire half 1) | 1 | 1 |
| `step_cap_over` / `unevaluable_pinned_operand` / `unfoldable_curated_call` (3) | `Truncated` — never reaches the test (H-8; tripwire half 2) | 1 | 1 |

**21/21 unchanged, same string, same anchor.**

### (C) 8 NEW fixtures

| file | kind | what it pins | measured |
|---|---|---|---|
| `control_inplace_ry_stateprep_selfcontrolled_folded_as_prep.ll` | ACCEPT | the H-1 trade: `clang -O1`'s output for `probes/u2.c`, the SELF-CONTROLLED source, now compiling as the prep | rc 1 → **0** |
| `control_inplace_ry_stateprep_mux_incoming_pinned_accept.ll` | ACCEPT | the H-2 β half from plain C (`probes/bc1.c`), with the state-vector argument in the header | rc 1 → **0** |
| `control_inplace_ry_stateprep_bool_seed_int_cond.ll` | ACCEPT | the owner's shape at the width it is reachable at (`probes/M2.c`) | rc 1 → **0** |
| `control_inplace_ry_stateprep_condwire_alias_accept.ll` | ACCEPT | which HELPER builds `CondWire` (§2c); RED under M-W | new |
| `control_inplace_ry_reject_stateprep_nonwire_still_collides.ll` | DECLINE | the narrowing is the WIRE, not "anything derived from the condition" — the F-R1-1 shape minimised | 1 = 1; off-wire mutation ⇒ **rc 0** |
| `control_inplace_ry_reject_stateprep_offwire_sideways_min.ll` | DECLINE | the SIBLING class, minimised | 1 = 1; off-wire mutation ⇒ **rc 0** |
| `control_inplace_ry_reject_stateprep_second_flag_i1.ll` | DECLINE | the H-7 `i1` residual — *"no longer CATEGORICALLY out"*, not *"`i1` is in"* | 1 = 1; off-wire mutation ⇒ **rc 0** |
| `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll` | DECLINE at `bare i1 register condition` | that the ruling did NOT make the owner's file compile — wall 2 still stands | 1 = 1 |

Each of the three off-wire declines is a genuine discriminator, not a
decoration: perturbing ONLY the off-wire expression, with the branch condition
and its whole backward cone untouched, turns each into an ACCEPT (measured:
`lshr %q,31`→`,1`; `sdiv %q,4`→`,7`; `icmp sgt %q,7`→`,200`).

### (D) Injection matrix

Three mutations applied to the LOWERED stream of each accept, then every
declared FileCheck prefix re-run: an extra **uncontrolled `cqrt_ry` on the
CONDITION register** (after the flag's free), an extra **`cqrt_free`**, and the
**`_controlled` gate re-pointed at the WRONG flag**.

```
the 19 flips + the 4 new accepts:
  fixtures=23 mutations=69 MISSED=0 DIRTY=0 n/a=0
```

⚠ The same matrix over the **34 PRE-EXISTING** state-prep accepts reads
`MISSED=25 DIRTY=1`, and that is **NOT this increment's**: re-run against the
`main` oracle binary it reads `MISSED=25 DIRTY=1` identically. Filed in §7 as
found-in-passing.

One generator defect was found and fixed during this work and is worth the line:
the first `CCNT` prefix used the bare pattern `_controlled(`, which FileCheck
also matches on the `declare void @cqrt_ry_i32_controlled(i32, i32, double)`
line — a `-NOT` that can never pass. It is call-qualified now.

---

## §4 e2e

Three STRICT slices, registered after the `inplace_ry_stateprep` group in
`tests/e2e/CMakeLists.txt`. Goldens generated through the real four-stage
pipeline and read **line by line** against the analytic stream in each header.

| slice | stage 2b | the stream |
|---|---|---|
| `slice_control_inplace_ry_stateprep_bool.c` | `0 violation(s), 0 unproven` | `cqrt_alloc_i1(0)` + `cqrt_ry_i1_controlled(h1,h2,0.9)`, flag mint/strip/free, no free of `h2` |
| `slice_control_inplace_ry_stateprep_bool_negated.c` | `0 violation(s), 0 unproven` | the same **plus a paired `cqrt_x(h1)` bracket** (Rule-9 polarity) |
| `slice_control_inplace_ry_stateprep_seed_eq_k.c` | `0 violation(s), 0 unproven` | `cqrt_alloc_i32(5)` + `cqrt_ry_i32_controlled(h1,h2,0.9)` |

**No `compare_files` twin gate**, deliberately and for the drbq Inc-4 reason:
there is no byte-identical twin. The witness is instead a **stated, re-derivable
`diff` relation between committed goldens**, and both relations were measured:

```
diff slice_control_inplace_ry_stateprep.expected.log \
     slice_control_inplace_ry_stateprep_seed_eq_k.expected.log
4c4
< cqrt_alloc_i32(0) -> h2
> cqrt_alloc_i32(5) -> h2                 ← ONE line: the whole ruling at i32

diff slice_control_inplace_ry_stateprep_bool.expected.log \
     slice_control_inplace_ry_stateprep_bool_negated.expected.log
3a4 > cqrt_x(h1)
5a7 > cqrt_x(h1)                          ← TWO lines: the !flag bracket
```

⚠ Each header says what the golden does **not** witness: no trace label answers
a STATE question, and `free_pairing_check.py` classifies `cqrt_alloc_<W>` by
symbol name and **never reads the seed argument at any site** — so a wrong seed
is invisible to stage 2b. The seed is pinned by these goldens and by F1. A green
2b must not be quoted as evidence for it.

`git status --porcelain tests/` after the e2e gate: only the three new `.c`
files, the three new `.expected.log` files and `CMakeLists.txt` (no pre-existing
golden regenerated).

---

## §5 CORPUS SWEEP — accept-monotonicity

Method: `git archive HEAD ir-pass/test` into a scratch dir (so the 19 renamed
files are compared **by their original text**; their IR is byte-unchanged), then
every one of the **1776** fixtures through BOTH binaries, comparing exit code,
the `cq … lowering: <reason> under quantum control` string, and the lowered
stdout.

```
files=1776  RCDIFF=19  DIAGDIFF=0  OUTDIFF=0

  control_inplace_ry_reject_stateprep_eqfold_cast.ll           rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_eqfold_coincidence.ll    rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_eqfold_coincidence_ne.ll rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_eqfold_derived_cond.ll   rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_eqfold_extremum.ll       rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_eqfold_ne_else.ll        rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_eqfold_ult.ll            rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_fcmp_oeq_folded.ll       rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_fcmp_une_folded.ll       rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_i1_arm_flag.ll           rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_i1_flag_pinned.ll        rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_a2_alias.ll        rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_constleft_eq.ll    rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_constleft_ugt.ll   rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_i1_both_edges.ll   rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_knownbits.ll       rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_knownbits_enum.ll  rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_mask1.ll           rc=1 F2 -> rc=0
  control_inplace_ry_reject_stateprep_range_ordered.ll         rc=1 F2 -> rc=0

  (F2 = `state prep seed is proven equal to the condition register`; the full
   string was compared, not abbreviated, by the sweep itself.)
```

**MEASURED AND AS REQUIRED: RCDIFF = 19, every one of them DECLINE → ACCEPT and
every one carrying the F2 string; ZERO ACCEPT → DECLINE; ZERO DIAGDIFF (no
diagnostic string moved anywhere in the corpus); ZERO OUTDIFF (the 1757 fixtures
that did not move emit byte-identical lowered IR).** The 19 are exactly the 19 of
§3(A) — `comm` over the two name lists is empty in both directions.

⚠ The sweep ran against a FROZEN COPY of the final binary
(`scratchpad/f2/cq-opt.final`), and that copy was verified `cmp`-identical to
`build/ir-pass/cq-opt` after the last edit — every change made after the sweep
started was comment-only, and the compiled object is byte-identical. (An earlier
attempt at this sweep DIED mid-run because I relinked `cq-opt` underneath it;
freezing the binary is why the result is trustworthy rather than merely
finished.) The change is monotone in the accept
direction by construction (the conjunct can only make `f2SeedPinnedByLiveRegister`
return `false` where it returned `true`, and `Truncated` is untouched), but
monotone-by-construction is exactly the claim this project requires to be
measured rather than asserted.

---

### 5b. A harness lesson worth one paragraph

Two long measurements in this session DIED or went red for the SAME
self-inflicted reason: `cmake --build … --target cq-opt` **relinks the binary**,
so for a second or two `build/ir-pass/cq-opt` does not exist, and anything
holding a path to it fails with `FileNotFoundError`. It killed the first corpus
sweep outright, and it turned `cq-opt-equivalence` red in the first full `ctest`
run (`multiprocessing.pool.RemoteTraceback … FileNotFoundError: No such file or
directory: build/ir-pass/cq-opt`) — a red that reads exactly like a real
equivalence regression and is not one. Re-run alone, that entry **Passed
(48.17 s)**.

**It is NOT the contention story CLAUDE.md's Rule-19 section describes**, and
calling it that would have been the comfortable wrong answer: the traceback names
the missing file. The fix was mechanical — freeze a copy of the binary for any
long sweep (`scratchpad/f2/cq-opt.final`, `cmp`-verified against the build tree
afterwards) and make no builds at all while the full suite runs. The final
`ctest` figures below come from a run started AFTER the last build, with nothing
rebuilt underneath it.

### 5c. THE FULL-SUITE GATE — state at hand-off, and the one number I cannot vouch for

`ctest --test-dir build -j6 --output-on-failure`, started AFTER the last build
with nothing rebuilt underneath it:

```
389 passed, 0 failed
outstanding: e2e-loop-twin-matrix (still executing at ~19 min)
```

Everything else is green, including every layer that can witness this change:
`ir-pass-lit` (149.47 s, all 1784 fixtures), `frontend-lit` (18.34 s), all seven
`runtime` entries, `cq-opt-equivalence` (98.27 s), and all six state-prep e2e
slices. The matrix was verified ALIVE and CYCLING (fresh child processes every
few seconds, progressing through the `rrange` cells) — it is slow, not wedged;
it began while two sibling worktrees had the box at load 250+, against a
quiet-box figure of 180–400 s.

**RESOLVED — the run finished and the red WAS mine.** Totals:
`99% tests passed, 1 tests failed out of 390`, `Total Test time (real) = 2593.06 s`,
the single failure `318 - e2e-loop-twin-matrix`. Its own report names the cause:
**6 `HARNESS-ERROR` cells, every one `stage 4 (run) exited -9`** — SIGKILL on
binaries under `cqtwin_*` temp dirs, i.e. precisely the processes the `pkill`
below hit. (The "FAILED (12)" list is those same 6 cells counted twice: once as
`exited -9`, once as the `verdict changed` that follows from it.) The other 282
cells classified normally — 133 ACCEPT-IDENTICAL, 29 quarantined
TRACE-DIVERGENCE as pinned, 60 UNROLLED-ONLY.

**Re-run alone: `e2e-loop-twin-matrix ... Passed, 1062.30 s`, 1/1.** So the full
gate is **390/390 green**, counting the 389 from the clean suite run plus this
entry re-run in isolation — stated that way rather than as a single clean 390,
because that is what was actually measured.

⚠ **THE ORIGINAL WARNING, KEPT because the lesson is the point.** While cleaning up a stale ctest run I
issued `pkill -9 -f 'cqtwin_'`, and `cqtwin_` is the matrix's own temp-dir
prefix — so that may have killed clang/exe children belonging to the CLEAN run's
matrix as well. A cell whose subprocess was SIGKILLed records a failure rather
than hanging, so a red here is as likely to be my cleanup as a real divergence.
`ctest --test-dir build -R e2e-loop-twin-matrix` on a quiet box settles it.

(The stale run itself is a second instance of the same lesson as §5b: my first
`pkill -f 'ctest --test-dir /Users/sorenwilkening/Desktop/CQ_f2'` MATCHED NOTHING
— the real command line is `ctest --test-dir build -j6 …` — so the run I believed
I had killed carried on competing for CPU for another half hour. Match a process
by what it actually spells, and verify the kill.)

## §6 THE OWNER'S FILE

`/private/tmp/.../scratchpad/owner_file_2026-09-11.c` =
`example/grover/grover_oracle_uncompute.c`.

| binary | rc | string |
|---|---|---|
| ORACLE (`main` 0c7380c) | 1 | `control flow` |
| **this tree** | **1** | **`control flow`** |

**UNCHANGED, and that is the correct and expected outcome.** F2 is **wall 3 of
3** for this file and only wall 3 moved:

1. `control flow` — `-O1` FUSES the second and third `if`s into ONE diamond
   carrying **TWO** merge phis (bd `b6ap`, P1, OPEN). Bool-independent.
2. `bare i1 register condition` — the fused diamond is conditioned on a BARE RAIL
   `br i1 %b0` with no compare (bd `l4x4`, P2, OPEN, Inc 1b-C).
3. F2 — this increment.

Measured on **this tree's** binary, to show wall 2 is genuinely next: `C2.c`
(V0 minus one `cq_measure`, so ONE phi) ⇒ `bare i1 register condition`; `M1.c`
⇒ the same. **Reporting "the prep compiles now" for this file would be false**,
and `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll` exists so the next
reader cannot make that mistake from the fixture set alone. What DOES compile is
the COMPARE-conditioned twin, `M2.c` — rc 1 → **rc 0**, to
`cqrt_alloc_i1(false)` + `cqrt_ry_i1_controlled(f, h, 0.5)`.

---

## §7 OPEN QUESTIONS / FOUND IN PASSING

**Q1 — the H-2 state-vector argument HOLDS, and here is exactly how far.** The
brief said to STOP on the β shape if it did not. It does, and the argument is in
the header of `control_inplace_ry_stateprep_mux_incoming_pinned_accept.ll` and in
PRD §14's ERRATA. In three sentences: LVI's edge range is a SOUND over-
approximation, so a singleton means the register equals the seed on **every**
execution taking that edge, which in quantum terms means that within the flag's
subspace for that edge the register's rail is the PRODUCT basis state |seed⟩ and
carries no superposition; the rival's only reversible realisation is a controlled
copy of that rail into a fresh |0⟩ rail, which on that subspace yields
|seed⟩⊗|seed⟩ — exactly what preparing |seed⟩ yields — while the other subspace
is identical in both readings because the arm's seed is a literal in both; so
nothing is cloned and the two readings are the same unitary. ⚠ **Where it is
WEAKER than the α theorem, said plainly:** α rests on a structural property of the
compiler (`RotBase ∈ CondRails ⇒ R4 declines`), which holds whatever LLVM does;
β rests on **LLVM's own analysis being sound**, which is a much safer assumption
than a heuristic but is still an assumption about a different codebase. It is the
same assumption `-O1` already makes when IPSCCP performs the substitution, so a
world in which β is wrong is a world in which `clang` miscompiles — but the two
are not the same *kind* of argument and a Rule-13 round should attack them
separately.

**Q2 — the 25 MISSED / 1 DIRTY in the PRE-EXISTING state-prep accepts.** The
injection matrix over the 34 accepts that pre-date this increment reads
`MISSED=25 DIRTY=1` on **both** binaries. Not this increment's, not investigated
(out of brief), but recorded rather than left for someone to rediscover:
`..._intrinsic_bswap_accept`, `..._step_cap_under` (all three mutations MISSED
each), `..._lifted_phi_after`, `..._range_ordered_seed0`, `..._suffix_control`
(the `extra_ry_on_cond` mutation).

The `DIRTY` on `..._warn_live_record` is **NOT a defect — MEASURED, not guessed**:
that fixture's `WARN` prefix checks the `warning: … non-diagonal gate over a live
derived record` line on **stderr**, and my matrix feeds each prefix only stdout,
so `WARN` can never match for it (its four other prefixes all pass on the clean
stream, and lit passes the fixture because its RUN line pipes `2>&1`). The
harness limitation is mine; the fixture is sound.

The 25 MISSED are real gaps in those pre-existing fixtures' assertions, and the
obvious repair is the one this increment applied to its own: whole-file `RYCNT` /
`FCNT` counts and a captured flag handle. **23/23 of mine read 0/0.**

⚠ **SUPERSEDED IN SCOPE by the round-1 review's own matrix, which ran SIX
mutations over all 57 accepts rather than my three over 34: the real figure is
57 MISSED cells on 17 pre-existing fixtures. The enumeration and the owed bd
issue are Q8 below** (review item **I-5**); the paragraph above is kept as the
narrower measurement it was, not restated.

**Q3 — `railWireClosure`'s delta is ONE shape, and it is fragile.** §2c measured
that `CondWire` differs from `{Cond} ∪ Prov` only through `condProvenance`'s
`if (isThetaCall(I)) continue;`, i.e. only for a chained theta between the pin and
the condition, and that exactly one module in the tree exercises it. That is
enough to keep the Rule-14 spelling and to pin it, but it means the
`control_inplace_ry_stateprep_condwire_alias_accept.ll` fixture is the **only**
thing standing between a future "tidy-up" and a silent divergence between R4's
notion of the condition's wire and F2's. The cross-reference at
`condProvenance`'s header says so.

**Q4 — records NOT updated here, because the brief scoped them out.** SCOPE §5.5
also lists `CONTROL_IN_PLACE_INC4_NOTES.md` §9/§12 (an ERRATA block), bd
`drbq.14` (its "i1 width OUT" and "seed==literal over-decline" bullets are
answered; the **deleted-register residual, Q3/OQ-1, is UNTOUCHED and must be said
so**), bd memories `f2-syntactic-enumeration` (append: the narrowing is *itself*
syntactic, and what makes it admissible is the R4 theorem, not the survey) and
`control-in-place-drbq` (new increment id + landing hash), and a new bd issue for
the increment. **None of those was written** — `bd` was read-only for this
session and the notes ERRATA was not in the brief's §4 list. They are owed before
landing.

**Q4b — the RIVAL modules are measured but not COMMITTED, and here is the
reasoning.** The brief asked that SCOPE's one-value mutations become "the
family's decline discriminators where they are not already fixtures". Read
literally that does not apply: SCOPE's mutations move the PIN, and on the
narrowed binary every one of them ACCEPTS — none is a decline discriminator. The
things that *do* discharge the theorem are the 21 UNFOLDED rival modules in
`probes/alt/`, and I re-measured all 21 on the narrowed binary (not just on
`main`) and cite each one, by filename and by its exact decline string, in the
header of the fixture it is the rival for. I did **not** commit them as fixtures,
because the four fences they decline through are already pinned in the corpus —
measured: `rotation arm on a condition wire` **7** files, `condition predates a
non-diagonal gate` **92**, `state prep merged with a quantum register` **12**,
`condition data use neither escaped nor measured` **12** — so committing 21 more
would add citation, not coverage. ⚠ **The honest counter-argument, recorded
rather than dismissed:** those 92/12/12/7 fixtures pin the FENCES, not the
specific claim *"the rival of THIS narrowed accept declines"*, and it is that
specific claim the narrowing rests on. If a Rule-13 round wants the theorem
pinned rather than cited, the cheap move is to commit two of them — one α (2c)
and one β (F1) — as `..._reject_stateprep_rival_{alpha,beta}_unfolded.ll`. I left
that to the round rather than doing it after the full suite had already run.

**Q5 — the 2c/R4 ordering makes the safety argument fragile in a knowable way**
(SCOPE H-4, re-measured here). The theorem the narrowing rests on is about **R4**,
but R4 is almost never the fence that actually fires: 14 of the 15 α rivals
decline at 2c `condition predates a non-diagonal gate` and the 15th at
`condition data use neither escaped nor measured`. R4 is a backstop that is
reached only when 2c lets something through. That is fine today and it is written
into the retirement trigger, but it means a *2c* change — not only an *R4* change
— can invalidate this narrowing, and 2c has been made more permissive twice in
this epic's history (drbq Inc 3's position-aware accept, and lom0 Inc 4's).

**Q6 — three of the four new DECLINE fixtures are not red-green in the usual
sense** and their headers say so: they decline on BOTH binaries, because they
pin a fence that exists on both. What makes them discriminators rather than
decorations is the recorded one-value off-wire mutation that turns each into an
accept. If a future round prefers those mutants committed as files, they are in
`/private/tmp/.../scratchpad/f2/n{2,6,7}m.ll`; I left them out because the tree's
convention is to state the mutation in the header (the drbq Inc-4 precedent), not
to commit both halves.

**Q7 — THE TWO MEASURED OVER-DECLINE RESIDUALS (round-1 review item I-4; applied
2026-09-11).** The owner's *"I dont see the need for the over-decline"* is
satisfied **only on the condition's own wire**. Two residuals remain, both class
B, both correct by design, and both **still declining on the branch binary** —
recorded here so the owner is told what the ruling did *not* buy:

| residual | reviewer probe | why it still declines |
|---|---|---|
| an **OFF-wire register pinned to the seed** — a genuine prep of `|15⟩` under `if (q == 5)`, sitting beside an unrelated live `int t = q * 3;` | `review_f2_r1_probes/c/o4_int_other_reg_pinned.c` | `t` is 15 on that edge and `t` is **not** in `CondWire` (the compare was rewritten onto `q`, and `mul` mints a fresh rail), so F2 still finds a collider |
| **any second tainted `i1`** in the function pinned on either edge, beside a `_Bool` prep | `ir-pass/test/control_inplace_ry_reject_stateprep_second_flag_i1.ll` (committed) | the second flag is a different compare's result, hence off **this** branch's wire; an `i1` seed still collides with it |

The `i1` row is the one to say out loud: **the ruling buys the owner's `_Bool`
prep; it does not buy every `_Bool` prep.** A `_Bool` prep next to any other
`_Bool` derived from the same register can still decline. Both residuals are
**correct** — they are exactly the class-B declines the narrowing deliberately
keeps — and neither is a bug to fix here; they are disclosure. Also recorded in
the `CLAUDE.md` ruling paragraph.

**Q8 — PRE-EXISTING INJECTION DEBT: 57 MISSED cells on 17 UNTOUCHED state-prep
accepts (round-1 review item I-5; a FOLLOW-ON, deliberately NOT fixed here).**
The round-1 review ran its own matrix — 57 accept fixtures × 6 mutations
(`extra_ry_on_cond`, `extra_free`, `extra_x`, `uncontrolled_arm`, `dup_ctl_gate`,
`seed_literal`) applied to the pass OUTPUT and re-checked through every prefix the
fixture declares (`review_f2_r1_probes/tools/matrix.py`,
`…/injection_matrix_result.txt`). **All 23 fixtures this increment flips or
creates catch all six.** The misses fall entirely on fixtures whose text this
branch does not touch, and they are **identical on the oracle** — pre-existing
debt against the drbq Inc-4 family, not this change's:

| # | fixture (`ir-pass/test/…`) | mutations MISSED |
|---|---|---|
| 1 | `control_inplace_ry_inloop_diamond.ll` | `extra_ry_on_cond`, `extra_free`, `extra_x`, `seed_literal` (4) |
| 2 | `control_inplace_ry_stateprep_cond_bitcast_seed.ll` | `extra_ry_on_cond`, `extra_x`, `dup_ctl_gate`, `seed_literal` (4) |
| 3 | `control_inplace_ry_stateprep_cond_cast_seed.ll` | `extra_ry_on_cond`, `extra_x`, `dup_ctl_gate`, `seed_literal` (4) |
| 4 | `control_inplace_ry_stateprep_consumer_ret.ll` | `extra_ry_on_cond`, `extra_x` (2) |
| 5 | `control_inplace_ry_stateprep_deep_chain.ll` | `extra_ry_on_cond`, `extra_free`, `extra_x`, `dup_ctl_gate`, `seed_literal` (5) |
| 6 | `control_inplace_ry_stateprep_f64.ll` | `extra_ry_on_cond`, `extra_x`, `seed_literal` (3) |
| 7 | `control_inplace_ry_stateprep_fcmp_oeq_derived_accept.ll` | all but `uncontrolled_arm` (5) |
| 8 | `control_inplace_ry_stateprep_fcmp_oeq_negzero.ll` | all but `uncontrolled_arm` (5) |
| 9 | `control_inplace_ry_stateprep_fcmp_oeq_twin.ll` | `seed_literal` (1) |
| 10 | `control_inplace_ry_stateprep_i8.ll` | `extra_ry_on_cond`, `extra_x` (2) |
| 11 | `control_inplace_ry_stateprep_i16.ll` | `extra_ry_on_cond`, `extra_x` (2) |
| 12 | `control_inplace_ry_stateprep_i64.ll` | `extra_ry_on_cond`, `extra_x` (2) |
| 13 | `control_inplace_ry_stateprep_intrinsic_bswap_accept.ll` | `extra_ry_on_cond`, `extra_free`, `extra_x`, `dup_ctl_gate` (4) |
| 14 | `control_inplace_ry_stateprep_lifted_phi_after.ll` | `extra_ry_on_cond`, `extra_x` (2) |
| 15 | `control_inplace_ry_stateprep_range_ordered_seed0.ll` | `extra_ry_on_cond`, `extra_x`, `dup_ctl_gate`, `seed_literal` (4) |
| 16 | `control_inplace_ry_stateprep_step_cap_under.ll` | `extra_ry_on_cond`, `extra_free`, `extra_x`, `dup_ctl_gate` (4) |
| 17 | `control_inplace_ry_stateprep_suffix_control.ll` | `extra_ry_on_cond`, `extra_x`, `dup_ctl_gate`, `seed_literal` (4) |

**= 57 cells.** Mutation totals over all 57 accepts: `extra_ry_on_cond` 16,
`extra_x` 16, `seed_literal` 12 (7 of those the reviewer's fp-regex harness
limit, not a fixture gap), `dup_ctl_gate` 9, `extra_free` 6, `uncontrolled_arm`
**0**. ⚠ The two worst are precisely what drbq's **F-C1D-4** round was about: an
injected uncontrolled `cqrt_ry` on the **CONDITION** register after the flag's
free, and an injected `cqrt_x`, are each invisible to **16** accept fixtures in
this family. The repair is the one this increment applied to its own 23 —
whole-file `RYCNT` / `FCNT` / `XCNT` counts and a captured flag handle.

⚠ **THIS IS AN OWED bd ISSUE AND IT IS NOT FILED YET.** `bd` was read-only for
this session (Q4), so the issue is *recorded here as owed* rather than created:
file it **against the drbq Inc-4 state-prep fixture family, not against this
branch**, titled to the effect of *"state-prep accept fixtures: 57 injection
cells missed on 17 pre-existing files (`extra_ry_on_cond` / `extra_x` 16 each) —
add whole-file RYCNT/XCNT/FCNT counts"*, with this table as its body. The
orchestrator owns `bd`; do not close the increment believing it exists.

---

## §8 ROUND-1 ITEMS APPLIED — 2026-09-11

`review_f2_r1.md` returned **CLEAR-WITH-ITEMS** (no confirmed silent miscompile
in the accept direction; items I-1 … I-5, none a blocker). All five are applied
below. **Every edit in this pass is a COMMENT or a DOC** — verified
mechanically: `git diff -- ir-pass/src | grep '^[+-]' | grep -v '^[+-]\s*//' |
grep -v '^[+-]\s*\*' | grep -v '^[+-]\{3\}'` is **EMPTY**, so no non-comment line
in `ir-pass/src` moved and the emitted stream cannot have changed. Gate run after
rebuilding **both** targets (`CQPass` *and* `cq-opt`): `ctest -R ir-pass-lit`
(the layer that can witness a comment-only pass edit at all — every RUN line goes
through `%cq-opt`).

| item | grade | where it landed |
|---|---|---|
| **I-1** — rank **2c FIRST** in the retirement trigger (R4 is the theorem's fence but fired for **0 of 27**; 2c for **16**), and state the measured split | DOC | `ir-pass/src/ArmClassify.cpp:1286` (the α-paragraph parenthetical, rewritten to point forward instead of claiming 14/15) and **`:1294`** (the trigger, now two RANKED doors — 2c the LIVE one with its two prior widenings named, R4 the backstop — followed by the 27-rival table: 2c **16** / F1 **5** / `condition data use neither escaped nor measured` **5** / `bare i1 register condition` **1** / R4 **0**, with `probes/v3.c` cited so "R4 is never reached" is not misread as "R4 is vacuous"). Mirrored in `CLAUDE.md:2007` (the two ranked doors) and **`:2015`** (the split) |
| **I-2** — replace the header's named α rival (the one **R3** already refuses) with the **BOTH-operands-folded** shape, quoting its IR | DOC | `ir-pass/src/ArmClassify.cpp:1371` (⚠ *do not attack this fence with that spelling* — for the accepted `phi [ %rt, %arm ], [ k, %entry ]` its `RotBase` is the register `%q` while the straight-through incoming is the literal `k`, so R3's "ONE base" refuses it before R4 is asked; `probes/u1.c` cited) and **`:1379`** (the rival that matters: the `%t = and %q, 0` shape of `…_stateprep_condwire_alias_accept.ll`, **9 lines of IR quoted verbatim**, both `%t` uses folding to `i32 0`; plus the F-2 matched pair — OFF-wire it LOWERS on both binaries to `cqrt_ry_i32_controlled(h_cmp, h_op, 0.9)`, ON-wire it declines 2c on both) |
| **I-3** — say out loud that `CondWire` is the condition's whole backward **TAINTED CONE**, safe only because it is byte-identically `CondRails`; write the **cancellation** as a sentence; add the divergence retirement trigger | DOC | `ir-pass/src/ArmClassify.cpp:1233` (the cone, the rails-are-distinct warning, and the cancellation set off as its own indented sentence — *"an argument about the EQUALITY OF TWO SETS, not about physical rails"* — plus why it survives a rival module and the `r9e5` round-2 taint window) and **`:1256`** (⚠ *if `railWireClosure` here and R4's `CondRails` ever DIVERGE … this narrowing must be RE-DERIVED FROM SCRATCH*, naming `…_condwire_alias_accept.ll` as the only tripwire and saying it pins only the chained-theta hop). Mirrored in `CLAUDE.md:1958` / `:1971`, and stated in this record as **§1 item `1c-bis`** (`IMPL_f2.md:91`) |
| **I-4** — record the measured **over-decline residuals** | residual (measured) | **`IMPL_f2.md:689` (§7 Q7)** — a two-row table: an OFF-wire register pinned to the seed (reviewer probe `review_f2_r1_probes/c/o4_int_other_reg_pinned.c`, a prep of \|15⟩ under `if (q == 5)` beside a live `int t = q * 3;`) and **any second tainted `i1`** (`control_inplace_ry_reject_stateprep_second_flag_i1.ll`), with the sentence the owner needs — *the ruling buys the owner's `_Bool` prep; it does not buy every `_Bool` prep*. Mirrored in `CLAUDE.md:2043` |
| **I-5** — the **57-cell / 17-fixture** pre-existing injection debt: list it, file it as owed; **do not fix it here** | coverage, PRE-EXISTING | **`IMPL_f2.md:707` (§7 Q8)** — all 17 fixtures enumerated with their missed mutations (summing to 57), the per-mutation totals (`extra_ry_on_cond` 16, `extra_x` 16, `seed_literal` 12 — 7 of them the reviewer's fp-regex harness limit — `dup_ctl_gate` 9, `extra_free` 6, `uncontrolled_arm` 0), the drbq **F-C1D-4** connection, the repair, and an explicit ⚠ that the **bd issue is OWED and NOT FILED** (`bd` was read-only this session; it belongs against the drbq Inc-4 fixture family, not this branch, and the orchestrator owns `bd`). §7 Q2's narrower 25/34 measurement is left as written with a forward cross-reference at `IMPL_f2.md:622` |

**Not applied, deliberately:** the review's *"not an item, but say it once"* —
the change ships **no diagnostic** by choice, and the disclosure must stay in the
fixture headers' own words (*"a program that was LOUDLY REFUSED before this
ruling now receives the circuit for the OTHER reading"*). That wording is already
in `CLAUDE.md`, in `f2SeedPinnedByLiveRegister`'s header and in every flipped
fixture header; nothing was reworded.

**Still owed before landing, and NOT done in this pass** (unchanged from §5c /
§7 Q4): ONE clean full-suite run on a quiet box (the gate stands at 389/390 plus
a separate green `e2e-loop-twin-matrix` re-run, which is not the same thing —
review §5), the `bd` writes of §7 Q4 and Q8, and the `CONTROL_IN_PLACE_INC4_NOTES.md`
ERRATA block. The full suite is the orchestrator's, on the merged tree.
