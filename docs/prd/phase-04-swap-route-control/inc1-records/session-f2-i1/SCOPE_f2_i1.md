# SCOPE — narrowing F2 by excluding the condition's own wire closure

**Read-only scoping record.** Nothing was built, no file under `ir-pass/`, `include/`,
`runtime/`, `tests/`, `tools/`, `example/` was edited, no `ctest` was run. Every verdict
below was produced by running the **shipped** `build/ir-pass/cq-opt` (tree at `main`
0c7380c) on probe inputs under `probes/`. Commands are in `probes/README.md`.

> **Bottom line, up front.** (a) **Every unfolded self-controlled spelling declines today
> — 19 of 19 measured, none through a single fence: `condition predates a non-diagonal
> gate` (2c) for the direct form, `rotation arm on a condition wire` (R4) for an alias,
> `state prep merged with a quantum register` (F1) for the mux form, `condition data use
> neither escaped nor measured` for a rotation of the flag itself.** The proposal's
> premise holds. (b) **19 of the 40 F2 fixtures flip to ACCEPT; 21 stay declines** —
> the F-R1-1 six, both sideways rewrites, all four curated intrinsics, all three cast
> rails, the fp forward hop, the `sitofp`, and the three `Truncated` cells are all
> **outside** the condition's backward cone and are untouched. (c) **The predicate
> change is ~6 added lines plus deleting the now-dead literal fast path** — but only in
> the *one* correct spelling; the obvious alternative spelling flips all 40 (H-6).
> (d) **The owner's file still does not compile after this narrowing.** F2 is the
> **third** wall, not the first: `control flow` (two merge phis, bd `b6ap`) → `bare i1
> register condition` (bd `l4x4`) → F2. All three measured.

---

## §0 MEASURE-FIRST — what fires today, at `main` 0c7380c

| probe | source (abbrev) | rc | diagnostic |
|---|---|---|---|
| `V0.c` | the owner's `example/grover/grover_oracle_uncompute.c`, verbatim | 1 | `control flow` |
| `C2.c` | V0 minus `cq_measure(a)` (one merge phi) | 1 | `bare i1 register condition` |
| `M1.c` | `bool b0=cq_theta(0,.5); bool b1=0; if(b0) b1=cq_theta(b1,.5);` | 1 | `bare i1 register condition` |
| `M2.c` | the same with an **`int` compare** condition (`if (q>5)`) | 1 | **`state prep seed is proven equal to the condition register`** |
| `M3.c` | `int` seed under an `int` compare — the drbq Inc-4 shipped accept | **0** | — |
| `mp.c` | two state preps in one arm → **two merge phis** | 1 | `control flow` |
| `alt/rail_cond_i1.ll` | `range_i1_both_edges` with `br i1 %q` instead of the `icmp` | 1 | `bare i1 register condition` |

**Read the V0 row carefully.** `-O1` FUSES the owner's second and third `if`s into ONE
diamond on the bare rail `%b0` carrying **two** phis (`%5 = phi i32 [5,%2],[2,%0]` for
`a`, `%6 = phi i1 [%3,%2],[false,%0]` for `b1`) — because `a` is a compile-time 5, the
first guard folds away and the third guard's truth is decided by the second region's
outcome. That is exactly bd `b6ap`. So the framing in the task prompt ("F2 refuses it")
is **not** what the shipped binary does with V0 today; F2 is reachable for the owner's
*shape* only once `b6ap` and `l4x4` are both closed. It is nevertheless real: `M2` is
the same state prep one token away from V0's and it declines on F2, and
`SCOPE_l4x4.md` §2.5 independently predicted the collision (its probe `t16b`).

---

## §1 F2 as shipped

### 1.1 The predicate

`ir-pass/src/ArmClassify.cpp:1195` —
```cpp
bool f2SeedPinnedByLiveRegister(const ControlRegion &Region, Constant *Seed,
                                TaintSet &Taint, const DominatorTree *DT,
                                bool &Truncated)
```
Header (`:1190-1194`): *"TRUE ⇒ some live tainted value of the SEED'S type is provably
EQUAL to the seed on one of the branch's two edges, i.e. the source the author wrote
could have been `cq_theta(<that register>,θ)` and this arm's constant is `-O1`'s fold of
it."*

**The BACKWARD half — LVI on both edges.**
* The candidate list, `ArmClassify.cpp:1254-1263`: every `Argument` and every
  `Instruction` that `isIntegerTy()`, is in `Taint.Tainted`, and `DT->dominates(&In, BI)`.
  `Cand` is built in **function order** for determinism.
* Two documented hard API preconditions on that list (`:1223-1252`): the dominance
  filter (asking LVI about a value defined after the branch SIGSEGVs a Release `cq-opt`
  — `solveBlockValueNonLocal` `cast<Argument>`s a non-Argument entry-block live-in), and
  the `isIntegerTy()` filter (`ConstantRange` is an integer lattice).
* The edge query, `:1301-1306`:
  ```cpp
  for (unsigned E = 0; E < BI->getNumSuccessors(); ++E) { ...
    ConstantRange Edge = LVI.getConstantRangeOnEdge(V, Pred, To, BI);
    if (Edge.isFullSet() || Edge.isEmptySet()) continue;
    f2Note(V, f2Refine(V, Edge, DL, &AC, DT), S); }
  ```

**The fp ANCHOR** (`:1265-1296` reads the operands off `BI->getCondition()`, deliberately
**not** `Region.Condition`; `:1308-1354` applies it). An equality `fcmp` against a
`ConstantFP` pins its tainted operand on the edge where the equality holds; `±0.0` and
NaN constants are refused (`:1288-1295`). Polarity: `oeq`/`ueq` on the TRUE edge,
`one`/`une` on the FALSE edge (`:1345-1352`). It seeds exactly **one** fact and reuses
the forward evaluation for everything downstream.

**The FORWARD half — abstract evaluation**, `:1355-1375`:
```cpp
unsigned Steps = 0;
while (!S.WL.empty()) {
  if (++Steps > kF2MaxSteps) { Truncated = true; return false; }
  Value *V = S.WL.pop_back_val();
  if (V->getType() == Seed->getType() && f2Exact(V, S) == Seed)   // ← THE TEST
    return true;
  for (User *U : V->users()) { ...
    if (!Taint.Tainted.count(I)) continue;
    if (!f2Model(I, S, DL, &AC, DT)) { Truncated = true; return false; } } }
```
`kF2MaxSteps = 4096` (`ArmClassify.cpp:882`); the exact boundary is `Steps = N + 2`,
pinned from both sides by `..._stateprep_step_cap_{under,over}.ll`.

### 1.2 The caller and the i1 handling

`ArmClassify.cpp:3011-3037`. Clause **(a)**, the plain-literal fast path
(`:3011-3028`), `dyn_cast<ICmpInst>(Region.Condition)` + `K->getValue() ==
SeedI->getValue()`; it is kept as a no-analysis backstop. Clause **(b)**, the semantic
test (`:3029-3032`), `|| Truncated`. The decline (`:3033-3036`):
```cpp
declineArm(declAnchor(Region),
           "state prep seed is proven equal to the condition register");
```

**There is no `i1` special case anywhere.** The `i1` collision is a *consequence* of the
candidate list: the branch's own condition (an `icmp`/`fcmp` result, or — after bd
`l4x4` — the bare rail) is a tainted `i1` that dominates `BI`, and LVI pins it to
`{true}` on one edge and `{false}` on the other. **Every** `i1` seed therefore matches
one of the two edges. That is the whole of "the `i1` STATE-PREP WIDTH IS OUT" (bd
`drbq.14`, CLAUDE.md's drbq Inc-4 round-4 paragraph).

### 1.3 Where "the condition register itself" enters the candidate set

**It is not entered explicitly — it enters through `Cand`.** There is no clause naming
the condition. Three distinct values reach the test this way:

1. **the branch condition itself** (`%c`, an `i1`) — `Cand` at `:1259-1263`;
   this is what pins every `i1` seed (`..._i1_flag_pinned.ll`, `..._i1_arm_flag.ll`);
2. **the compare's tainted operand** (`%q`, `%t = and %q,1`, the `fcmp`'s `%t`) — same
   loop, or the fp anchor at `:1353`; this is what pins the whole `eqfold_*` /
   `range_{mask1,ordered,knownbits,constleft_*,a2_alias}` / `fcmp_*_folded` family;
3. **anything reachable forward from (1) or (2)** — the `while` loop at `:1355`; this is
   the F-R1-1 six, the sideways pair, the casts, the intrinsics, the `sitofp`.

**(1) and (2) are exactly `R4`'s `CondRails`. (3) is exactly what is not.** That split
is the whole of the proposal, and it is the split the measurements in §3 confirm.

---

## §2 FENCE AUDIT — does every unfolded self-controlled spelling decline?

### 2.1 What "the condition's wire" means, precisely

R4 (`ArmClassify.cpp:3070-3161`) builds
```cpp
railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, …, CondRails);
for (Value *P : Prov)
  railWireClosure(P, Taint, WireDir::BackwardOnly, …, CondRails);
railWireClosure(RotBase, Taint, WireDir::BothWays, ArmA, ArmB, BaseWire, &BaseWireOrder,
                /*Exclude=*/MergePhi);
for (Value *B : BaseWireOrder)
  if (CondRails.count(B)) → decline "rotation arm on a condition wire";
```
with `Prov = condProvenance(Region.Condition, Taint, …)` (`:2459-2460`).

* `condProvenance` (`ArmClassify.cpp:231`) is the **backward tainted operand cone** of
  the condition — it follows *every* operand edge, stopping at `cq_theta` sources, with
  the arg-1 angle exclusion. It collects `%q`, `%t = and %q,1`, `%b = zext %c0`, both
  operands of a Q+Q compare, etc.
* `railWireClosure` (`:476`) is the **rail** relation: an in-place hop keeps the same
  physical rail (`cq_phi` arg-0 unconditionally; a chained `cq_theta` arg-0; `add`/`sub`/
  `xor` with exactly one tainted operand; `phi`/`select`/`freeze` data operands), while
  `mul`/shifts/`and`/`or`/casts/templates **mint a fresh rail** and stop the walk.
* ⚠ `railWireClosure(Region.Condition, …)` **stops dead** — a `CmpInst` is not a
  `BinaryOperator` and the dispatch has no `CmpInst` arm, so it inserts the compare and
  falls off the end (the in-source note at `:3086-3097`). R4's whole condition reach is
  `{Cond} ∪ ⋃_{P∈Prov} backwardRailClosure(P)`, and because every backward rail hop is
  also an operand edge, that union **is** `{Cond} ∪ condProvenance(Cond)`.

**So "on the condition's wire" here means: in the backward tainted operand cone of the
branch condition, plus the condition itself.** `t = q >> 31` is *derived from* `q` and
is a **different physical rail** (`lshr` has no in-place ABI) **and** is not in the cone
(the cone is backward from the compare, and `-O1` rewrote the compare onto `q`, not onto
`t`). Both readings agree: it is **not** on the condition's wire.

### 2.2 The structural argument, then the measurements

`railWireClosure` inserts its seed first (`Out.insert(W)` at `:487`, before any gate), so
`RotBase ∈ BaseWireOrder` always. Therefore **`RotBase ∈ CondRails` ⇒ R4 declines**,
unconditionally, for every chained (register-arg-0) rotation arm. The one way to skip R4
is `StatePrep` (`if (!StatePrep)` at `:3149`), which is the folded case under discussion.
So the proposal's claim reduces to a *theorem about R4*, not to a survey — but the
survey was run anyway, because 2c usually fires before R4 gets the chance.

**Plain-C probes (`probes/*.c`), shipped binary:**

| probe | source | rc | fence that fired |
|---|---|---|---|
| `u1.c` | `int r=q; if (q==5) r=cq_theta(q,.9);` | 1 | F1 `state prep merged with a quantum register` (`-O1` folds the arm to `cq_theta(5,·)`) |
| `u2.c` | `int r=5; if (q==5) r=cq_theta(q,.9);` | 1 | **F2** (`-O1` folds the arm; this IS the ambiguity) |
| `u3.c` | arm-local `r`, never merged | 1 | `value-arm swap-route` |
| `u4.c` | `_Bool c=b; if (b) c=cq_theta(b,.9);` | 1 | `bare i1 register condition` (l4x4) |
| `u5.c` | `_Bool c=(q==5); _Bool r=c; if (c) r=cq_theta(c,.9);` | 1 | `condition data use neither escaped nor measured` |
| `u6.c` | `volatile int k=5; if (q==k) r=cq_theta(q,.9);` — **unfolded** | 1 | **2c** `condition predates a non-diagonal gate` |
| `v1.c` | `int r=q; if (q>5) r=cq_theta(q,.9);` — **unfolded** | 1 | **2c** |
| `v2.c` | derived condition `q+1>5`, arm rotates `q` — **unfolded** | 1 | **2c** |
| `v3.c` | `int t=q+1; if (q>5) r=cq_theta(t,.9);` — an **alias** on the wire | 1 | **R4** `rotation arm on a condition wire` |
| `v4.c` | arm rotates a **disjoint** register — the Inc-1 shipped shape | **0** | — (control: the fence is not vacuous) |
| `w1.c` | rotate the mask rail `t=q&3` under `if (t>2)` | 1 | F1 (`-O1` folded it too) |
| `w2.c` | `int r=q; if (q>5) r=cq_theta(5,.9);` — the **mux** rival | 1 | F1 `state prep merged with a quantum register` |
| `w3.c` | rotate `a=q&6` under `if (a>1)` — **unfolded** | 1 | **2c** |
| `w4.c` | rotate the FLAG under its own control, flag measured | 1 | `condition data use neither escaped nor measured` |
| `w5.c` | rotate `b=(q>7)` under `if (b>0)` | 1 | `condition data use neither escaped nor measured` |

**Fixture-derived probes** — for each of the 19 flip candidates, the shipped fixture with
the arm's constant seed replaced by the in-cone register it folded from (α), or the
phi's Pred incoming replaced by the register (β). `probes/alt/`:

| α (arm-edge) probes, 15 | verdict |
|---|---|
| `eqfold_coincidence`, `eqfold_cast`, `eqfold_ne_else`, `eqfold_extremum`, `eqfold_derived_cond`, `eqfold_ult`, `range_mask1`, `range_ordered`, `range_knownbits`, `range_knownbits_enum`, `range_constleft_eq`, `range_constleft_ugt`, `fcmp_oeq_folded`, `fcmp_une_folded` | rc=1, **`condition predates a non-diagonal gate`** (14/14) |
| `i1_arm_flag` (rotate the flag itself) | rc=1, `condition data use neither escaped nor measured` |
| `i1_arm_flag_owned` (same, with `cq_measure(%c)` added so the lineage is owned) | rc=1, same string — a `cq_theta` user of the condition is *structurally* `Unowned` (`condDataUseDisposition`'s final `return CondDataDisp::Unowned; // unrecognized (store/opaque/cq_invert/phi/…)`) |

| β (straight-through-edge) probes, 4 | verdict |
|---|---|
| `b_coincidence_ne`, `b_a2_alias`, `b_i1_both_edges` | rc=1, **F1 `state prep merged with a quantum register`** |
| `b_i1_flag_pinned` | rc=1, `condition data use neither escaped nor measured` |

**ANSWER TO (2): YES — every unfolded self-controlled spelling declines today, 19/19,
and the plain-C sweep adds 13 more.** The proposal's argument has **no hole in the
accept direction**. It does have a *structure* the proposal's one-sentence form hides:
the rival is refused by **four different fences**, and only one of them (R4) is the one
the argument names. See H-4.

### 2.3 The fold is real, and it is plain C

`probes/a_prep.c` vs `probes/a_self.c` —
```c
int r = 0;  if (q == 0) r = cq_theta(0, 0.9);    /* a genuine prep         */
int r = 0;  if (q == 0) r = cq_theta(q, 0.9);    /* a self-controlled Ry   */
```
`clang -O1 -emit-llvm -S` on both ⇒ **BYTE-IDENTICAL modules** (measured; `diff` empty).
`probes/b_prep.c` vs `probes/b_self.c` (the `_Bool` pair, `if(b0)` vs `if(!b0)`) differ
only in branch polarity and phi operand order — the same module up to Rule-9
canonicalisation. **This is the owner's whole problem in one line: two plain-C programs,
one of which CQ has never been able to lower, arrive at the pass indistinguishable.**

---

## §3 THE FLIP LIST — all 40 F2 fixtures classified

`grep -l 'proven equal to the condition register' ir-pass/test/*.ll | wc -l` → **40**, all
in `control_inplace_ry_reject_stateprep_*`. No `tests/e2e` golden and no other family
mentions the string.

Method: (i) read each fixture's IR and locate the value whose edge range equals the seed;
(ii) confirm it by a **targeted mutation** that moves *only* that value and re-running the
shipped binary — for a class-B fixture, perturbing the out-of-cone expression alone
(leaving the whole cone untouched) must turn the decline into an accept; for a class-A
fixture, perturbing the in-cone pin alone must do the same. All mutants in `probes/mut/`.

### (A) The pinned register IS in the condition's cone → **FLIPS to ACCEPT** (19)

| # | fixture (`control_inplace_ry_reject_stateprep_…`) | pin | edge | mutation evidence |
|---|---|---|---|---|
| 1 | `eqfold_coincidence` | `%q` | arm | `icmp eq %q,5`→`,6` ⇒ **rc 0** |
| 2 | `eqfold_coincidence_ne` | `%q` | straight | `,5`→`,6` ⇒ rc 0 |
| 3 | `eqfold_cast` | `%q` | arm | `,0`→`,1` ⇒ rc 0 |
| 4 | `eqfold_ne_else` | `%q` | arm | `,5`→`,6` ⇒ rc 0 |
| 5 | `eqfold_extremum` | `%q` | arm | `INT_MIN`→`INT_MIN+1` ⇒ rc 0 |
| 6 | `eqfold_derived_cond` | `%a = and %q,6` | arm | `icmp eq %a,2`→`,4` ⇒ rc 0 |
| 7 | `eqfold_ult` | `%q` | arm | structural (only candidate) |
| 8 | `range_mask1` | `%t = and %q,1` | arm | (sibling mutations, class confirmed by 9/13) |
| 9 | `range_a2_alias` | `%t = and %q,1` | straight | `and %q,1`→`,2` ⇒ rc 0 |
| 10 | `range_ordered` | `%t = and %q,3` | arm | `and %q,3`→`,7` ⇒ rc 0 |
| 11 | `range_knownbits` | `%b = zext %c0` | arm | structural (in cone of `icmp eq %b,0`) |
| 12 | `range_knownbits_enum` | `%t = and %q,4` | arm | `and %q,4`→`,8` ⇒ rc 0 |
| 13 | `range_constleft_eq` | `%q` | arm | `icmp eq 5,%q`→`6,%q` ⇒ rc 0 |
| 14 | `range_constleft_ugt` | `%t = and %q,1` | arm | `and %q,1`→`,2` ⇒ rc 0 |
| 15 | `i1_flag_pinned` | `%c` (the compare) | straight | structural — only i1 candidate |
| 16 | `i1_arm_flag` | `%c` (the compare) | arm | structural — only i1 candidate |
| 17 | `range_i1_both_edges` | `%q` / `%c` (both i1) | straight | structural — only i1 candidates |
| 18 | `fcmp_oeq_folded` | `%t` (the fcmp's operand) | arm | `5.0`→`6.0` ⇒ rc 0 |
| 19 | `fcmp_une_folded` | `%t` | arm | `5.0`→`6.0` ⇒ rc 0 |

**What the prep reading emits for each:** the drbq Inc-4 stream, unchanged —
`cqrt_alloc_<W>(SEED)` at the hoisted theta, then `cqrt_ry_<W>_controlled(f, h, θ)` on
that fresh rail, the ordinary flag mint/strip/free, the rail **FROZEN** by
`ChainWalk::railCarriesControlledRotation` and never uncomputed. The condition register
is untouched by the region.

**What the alternative reading would have meant, and what it costs:**
* **α, 15 cells** — the source rotated the *condition's own* register in place. That
  circuit relabels the condition wire; the prep circuit does not. Nobody has ever been
  able to emit it (measured 15/15 decline unfolded, §2.2). The α author loses a loud
  decline and gets a circuit for a different program.
* **β, 4 cells** (`eqfold_coincidence_ne`, `range_a2_alias`, `i1_flag_pinned`,
  `range_i1_both_edges`) — the source's straight-through value was a *live register*,
  so the merge is a quantum data **MUX** between that rail and a fresh prepped one. That
  is F1's `state prep merged with a quantum register`, a **Rule-8 no-cloning** refusal,
  not R4's. **The owner's own shape is a β pin** (`b_prep`: `%2` pins to `false` on the
  Pred edge), so an "arm-edge-only" narrowing would **not** solve the owner's case. See
  H-2.

### (B) The pinned register is NOT in the cone → **stays a DECLINE** (21)

| fixture | pin | why it is out of the cone | mutation evidence |
|---|---|---|---|
| `range_forward_add` | `%fwd = add %t,5` | forward user of a cone member | `,5`→`,55` ⇒ **rc 0** |
| `range_forward_xor` | `%fwd = xor %t,7` | " | `,7`→`,70` ⇒ rc 0 |
| `range_forward_or` | `%fwd = or %t,8` | " | `,8`→`,80` ⇒ rc 0 |
| `range_forward_sub` | `%fwd = or %t,-4` | " | (same family) |
| `range_forward_lshr` | `%fwd = lshr %q,31` | " | `31`→`30` ⇒ rc 0 |
| `range_forward_ashr` | `%fwd = ashr %q,31` | " | (same family) |
| `sideways_sdiv` | `%t = sdiv %q,4` | **sibling** — `-O1` rewrote the compare onto `and %q,-4` | `,4`→`,7` ⇒ rc 0 |
| `sideways_offset` | `%t = udiv %q,3` | sibling of `%o = add %q,-15` | `,3`→`,7` ⇒ rc 0 |
| `merge_edge_sideways` | `%t = sdiv %q,4` | sibling | `,4`→`,7` ⇒ rc 0 |
| `intrinsic_bswap` | `bswap(%q)` | forward, and the in-cone pin is 83886080 ≠ seed 5 | cmp `…80`→`…81` ⇒ rc 0 |
| `intrinsic_bitreverse` | `bitreverse(%q)` | " | ⇒ rc 0 |
| `intrinsic_fshl` | `fshl(%q,%q,8)` | " | ⇒ rc 0 |
| `intrinsic_fshr` | `fshr(%q,%q,8)` | " | (same family) |
| `cast_sext_live` | `sext %q to i64` | forward **and** type-disjoint from every cone member (`%q`:i32, seed:i64) | structural + rc 0 |
| `cast_zext_live` | `zext %q to i64` | " | structural |
| `cast_trunc_live` | `trunc`-class `i16` rail | " | structural |
| `fp_seed_sitofp` | `sitofp %q to double` | forward; no cone member is `double` | structural + rc 0 |
| `fcmp_oeq_derived` | `%d = fmul %t,3.0` | forward hop off the anchor | `3.0`→`4.0` ⇒ rc 0 |
| `step_cap_over` | — (`Truncated`) | the 4096 cap; independent of the pin | cone mutation ⇒ **still rc 1, same string** |
| `unevaluable_pinned_operand` | — (`Truncated`) | conservative half | cone mutation ⇒ **still rc 1** |
| `unfoldable_curated_call` | — (`Truncated`) | `nobuiltin llvm.bswap` refused by `canConstantFoldCallTo` | cone mutation ⇒ **still rc 1** |

**(C) unclear: none.** All 40 resolved.

**Answering the task's specific questions.** *Are the F-R1-1 six's registers on the
condition's wire?* **No, twice over.** `t = q >> 31` is on a *fresh rail* (no in-place
ABI for `lshr`), and it is not in the **cone** either, because the F-R1-1 defect is
precisely that `-O1` rewrote the compare **downward onto an ancestor** of `t` — so the
backward walk from the compare can never reach `t`. Measured: perturbing only `%fwd`
(cone untouched) turns each into an accept. The `sideways_*` pair is the same conclusion
by a sharper route — `-O1` moved the compare **sideways onto a sibling**, so `t` is
neither an ancestor nor a descendant of anything the compare names.

---

## §4 THE OWNER'S FILE

**With the narrowing alone, `grover_oracle_uncompute.c` still does not compile.** The
walls, in the order the shipped binary hits them (all measured, §0):

| # | wall | bd | what it takes |
|---|---|---|---|
| 1 | **two merge phis** → `control flow` | `b6ap` (P1, OPEN, filed 2026-09-11 with this exact file named) | a multi-phi merge capability; bool-independent (the int/compare twin declines byte-identically) |
| 2 | **`bare i1 register condition`** → `classifyArms` `ArmClassify.cpp:2394` | `l4x4` (P2, OPEN — Inc 1b-C) | admit a rail leaf on the in-place-Ry / state-prep arm path |
| 3 | **F2** | this scope | the narrowing below |

`C2.c` (V0 minus `cq_measure(a)`) was re-measured this session: **`bare i1 register
condition`** — one phi, so wall 1 is gone and wall 2 is next. `SCOPE_l4x4.md` §2.5 and
its probe `t16b` already recorded that F2 is wall 3 behind it (*"`t16b` declines at
F2"*), reached independently. So the three scopes agree and the ordering is settled.

**After all three:** V0's second region lowers as
`cqrt_alloc_i1(0)` + `cqrt_ry_i1_controlled(h_b0, h_new, 0.5)` — with `h_b0` **itself**
as the control (l4x4's mechanism: the register is the flag, no mint, no strip, no free),
the new rail frozen, and `b0` untouched and still measurable. Note the pleasant
consequence for the owner's file specifically: **its β rival is not `clang`-reachable.**
`probes/b_copy.c` (`bool b1 = b0; if (b0) b1 = cq_theta(0,.5);`) does **not** produce
V0's module — `-O1` keeps `%2` as the phi's Pred incoming, so F1 catches it
(measured; `diff` shows the phi differing). For the owner's exact shape there is
therefore **no rival reading at all** — the narrowing costs nothing *there*. The cost is
at `i32`, where the rival *is* reachable (§H-1, §H-2).

---

## §5 DESIGN

### 5.1 The predicate change

**Exclude at the TEST, never at the ANCHOR.** Two lines in
`f2SeedPinnedByLiveRegister`'s signature and loop, plus the set at the caller:

```cpp
// ArmClassify.cpp:1195 — new parameter
bool f2SeedPinnedByLiveRegister(const ControlRegion &Region, Constant *Seed,
                                TaintSet &Taint, const DominatorTree *DT,
                                const SmallPtrSetImpl<Value *> &CondWire,   // NEW
                                bool &Truncated)

// ArmClassify.cpp:1361 — the ONE conjunct
if (V->getType() == Seed->getType() && !CondWire.count(V) &&
    f2Exact(V, S) == Seed)
  return true;
```
and at the caller (`ArmClassify.cpp:~3029`), built **by calling R4's own helpers** so the
two sets cannot drift (Rule 14; `Prov` is already in scope from `:2460`):
```cpp
SmallPtrSet<Value *, 16> CondWire;
railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                CondWire);
for (Value *P : Prov)
  railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr, CondWire);
```
*(`railWireClosure` and `WireDir` are file-local to `ArmClassify.cpp`'s anonymous
namespace, so no header move is needed.)*

**Clause (a), the literal fast path (`:3011-3028`), becomes dead and must be DELETED,
not left to rot.** `H` is by construction the compare's own operand, hence always in
`CondWire`; keeping it would re-introduce exactly the declines the narrowing removes for
`eqfold_coincidence`/`_ne`. Deleting it retires the "it depends on no analysis" backstop
argument — say that in the commit, do not delete it silently.

**Diff size:** ~6 lines added, ~18 lines deleted, 5 call-site tokens. The *comment* work
is much larger: `f2SeedPinnedByLiveRegister`'s header and the `:2883-3010` block are
~130 lines of rationale that now state a narrower question.

### 5.2 Classification of the change

* It is an **ACCEPT-WIDENING of a Rule-13 core fence** (`ArmClassify`, the control
  classifier; the fence whose failure is a wrong unitary). Rule 13 applies in full:
  **one independent adversarial round minimum**, and the drbq Inc-4 history says budget
  **two** — F2 lost four consecutive rounds, each to a different `-O1` rewrite, and the
  standing lesson (`F2 lesson: syntactic enumeration loses to instcombine`) is that a
  *syntactic* answer to a semantic question loses. The proposed exclusion set is
  syntactic (a cone) answering a semantic question ("could `-O1` have folded this from a
  register?"). **That is the same shape as the three defeats.** The saving grace is the
  direction: the *set being excluded* is one for which a **theorem** exists (R4 declines
  it), not a guess — see §2.2 — so the round should attack the theorem, not the cone.
* It is **monotone in the accept direction**: it can only turn declines into accepts.
  No currently-accepting fixture or golden can move. A corpus sweep is still owed
  (`tools/cq_opt_equivalence.py`-style, all 1776 fixtures) to *measure* that.

### 5.3 Fixtures

**19 rewrites** (decline → accept). Each keeps its IR byte-for-byte and its measured
history, gains a `RUN:` without `not`, `CHECK`s for `cqrt_alloc_<W>` +
`cqrt_ry_<W>_controlled` + the flag mint/strip/free counts, whole-file `NOROUTE`/`FCNT`/
`XCNT`/`ACNT` negatives (the drbq Inc-4 round-1 lesson: a positive `-COUNT-n` inside the
`NOROUTE` prefix **windows** every negative after it — 9 of 20 accepts were blind), and a
header that **states the ruling and names the rival**: *"this module is byte-identical to
`<the α/β source>`, which declines `<string>` unfolded (measured, `probes/alt/<n>.ll`);
the owner ruled 2026-09-11 that the prep reading wins."*

**21 unchanged**, but each needs one added sentence saying **why it is still a decline
under the narrowed fence** — otherwise the next reader cannot tell a surviving fence from
an accident. For the three `Truncated` cells say explicitly that they never reach the
test.

**New fixtures (≥8):**

| new file | kind | what it pins |
|---|---|---|
| `…_stateprep_rail_i1_seed_accept.ll` | ACCEPT | the owner's shape at `i1` (once l4x4 lands); RED on `main` |
| `…_stateprep_self_controlled_folded_accept.ll` | ACCEPT | `a_prep.c`/`a_self.c`'s shared module, header carrying the trade **and the `diff`-empty measurement** |
| `…_reject_stateprep_offwire_forward_min.ll` | DECLINE | the minimal out-of-cone forward pin — the discriminator that the exclusion is a **cone**, not "anything derived from the condition" |
| `…_reject_stateprep_offwire_sideways_min.ll` | DECLINE | the sideways sibling, likewise |
| `…_stateprep_condwire_alias_accept.ll` | ACCEPT | a pin reached through a **rail hop** (`add`/`xor`) rather than an operand edge — pins that `railWireClosure` is in the set builder, not just `condProvenance` |
| `…_reject_stateprep_second_flag_i1.ll` | DECLINE | an `i1` seed pinned by an **independent second compare** not on this branch — the residual the narrowing must keep (H-7) |
| `…_stateprep_fcmp_oeq_narrowed_accept.ll` | ACCEPT | `fcmp_oeq_folded`'s flip, with the fp-anchor seed still live |
| `…_reject_stateprep_fcmp_oeq_derived_still.ll` | DECLINE | its one-hop sibling — pins that the anchor still **seeds** under the narrowing (the option-(i) tripwire, H-6) |

**e2e:** ≥1 STRICT slice for the owner's file or its minimal twin, with its golden. It is
not a `compare_files` twin gate — there is no byte-identical twin (the drbq Inc-4
precedent: the witness is a stated reduction, not a diff).

### 5.4 `DS_Warning`?

The machinery exists (`RotationLowering.cpp:1533`, `DiagnosticInfoUnsupported(F, msg,
dbg, DS_Warning)`; `opt` prints `warning:` and exits 0 — the lyyf/M-A Inc-7b precedent).

**Recommendation: NO warning by default.** It would fire on *every* narrowed accept
— which is every Grover state prep the owner writes, including `grover_oracle_uncompute.c`
— i.e. on the exact program the ruling exists to make compile. A warning nobody can
silence is a warning everybody learns to skim (Rule 19's own argument).
**Instead:** (i) the ruling in CLAUDE.md + PRD §14, (ii) the accept fixtures' headers
naming the rival, (iii) the committed e2e slice. **Put a flag-gated warning
(`-cq-warn-folded-prep`) on the owner's desk as an option**, not in the default build.
If the owner *does* want it on by default, it must fire **only when a pin exists**
(i.e. only in the narrowed cases), never on an uncontested prep.

### 5.5 Records the ruling must update

| file | what |
|---|---|
| `CLAUDE.md`, the drbq Inc-4 round-4 paragraph | the sentence **"⚠ THE `i1` STATE-PREP WIDTH IS OUT, and it is the one capability this cost"** and the two clauses after it become **dated HISTORY** — kept verbatim, re-dated, with the ruling and its date appended. The four-round F2 history stays (it is the reason the narrowing is risky), but must stop reading as current policy. |
| `CLAUDE.md`, the "Where Things Live" F2 row and `ArmClassify` row | the fence's question is now *"…equal to the seed **and not on the condition's own wire**"* |
| `docs/prd/phase-04-swap-route-control/control-in-place-PRD.md` §14.2b / §14.11 Q1 / the i1 clause | the accept class grows; Q1's "workaround one character" note is retired for cone pins and **kept** for off-cone ones |
| `CONTROL_IN_PLACE_INC4_NOTES.md` §9/§12 | an ERRATA block, not an edit |
| bd `drbq.14` | the "i1 width OUT" and "seed==literal over-decline" bullets are answered; the *residual* (deleted-register fold, Q3/OQ-1) is **untouched** and must be said so |
| bd memory `f2-syntactic-enumeration` | append: the narrowing is itself syntactic, and the reason it is admissible is the R4 theorem, not a survey |
| bd memory `control-in-place-drbq` | new increment id + landing hash |
| new bd issue | the increment itself (P1, Rule-13 core, accept-widening) |

---

## §6 HAZARDS

**H-1 (TOP) — the α silent miscompile, plain-C reachable.**
`int r = k; if (q == k) r = cq_theta(q, θ);` is **byte-identical after `-O1`** to the
genuine prep (MEASURED: `a_prep.c`/`a_self.c`, `diff` empty). Today: loud decline. After
the narrowing: it compiles, as a **fresh rail rotated under a flag, with `q` never
touched** — a different unitary from the one that source names. 15 of the 19 flips are
this shape. **This is what the owner is accepting**, and it must be put to them in those
words: *a program that today is loudly refused will silently receive the circuit for the
other reading.* The mitigation is not a fence (none exists — the two modules are equal)
but disclosure: the ruling, the fixture headers, and optionally the flag-gated warning.

**H-2 — the β no-cloning mux, also plain-C reachable, and a *different* invariant.**
Four flips pin on the **straight-through** edge, where the rival is
`r = <live rail>` on one branch and a fresh prep on the other — refused today by
**F1**'s `state prep merged with a quantum register`, a **Rule-8** refusal. MEASURED
reachable: `probes/bc1.c`, `int r = q; if (q != 5) r = cq_theta(5,.9);` ⇒ `-O1` emits
`%7 = phi i32 [%5,%4], [5,%1]` — the Pred incoming **folded from `%q`** — and it declines
F2 today. Under the narrowing it accepts as a prep, dropping the source's aliasing of
`q` into `r`. *Mitigating:* on that edge `q` is pinned to the seed, so the fresh rail
carries the same basis value; the two differ in **entanglement** (in the rival, measuring
`r` measures `q`). *Not mitigating:* the argument depends on the pin being exact, which
is the very thing F2 existed to distrust. **And the obvious safer variant — narrow the
ARM edge only — does not work: the owner's own pin is a β pin** (§4). So the owner must
take H-2 with H-1 or take neither.

**H-3 — the exclusion set must be R4's, computed by R4's own call.**
A smaller set (`{Region.Condition}` alone, or the compare's direct operands) leaves flips
1–14 and 18–19 unexplained and gives no theorem. A larger one (adding `WireDir::BothWays`
or a forward closure) swallows the F-R1-1 six, the sideways pair, the casts, the
intrinsics and the `sitofp` — i.e. **all 21 class-B fixtures**, every one of which is a
recorded CONFIRMED miscompile. The set must be built by calling `railWireClosure` /
`condProvenance`, never re-spelled. **Consequence:** a narrowing of `condProvenance` is
now a Rule-13 change to **two** fences (R4 *and* F2), not one — the existing in-source
warning at `ArmClassify.cpp:231-232` must be extended to say so.

**H-4 — the theorem is about R4, but R4 is not what fires.**
§2.2's proof is *"`RotBase ∈ CondRails` ⇒ R4 declines"*. Measured, 2c (14 cells) and the
condition-data-use clause (1 cell) fire **first**, and F1 covers the β rivals. So the
safety of the narrowing rests on a fence that, in practice, is never reached. **That is
fine but fragile**: if 2c is ever made position-aware enough to admit a post-region
rotation on the condition's wire, R4 is the backstop and it still holds. **Write the
retirement trigger:** *the day any chained rotation arm whose `RotBase` is in `CondRails`
lowers, this narrowing is an over-accept and must be re-derived.* That is a live wish —
"rotate the flag in place" is a natural Grover-ancilla idiom.

**H-5 — R4 and R6 are SKIPPED for a state prep, and the narrowing enlarges the prep
class.** The §14.5 argument for the skip is *structural* (the rotated rail is minted by
the hoisted `T` itself, so no pre-region SSA name for it exists), so it does not weaken
as the class grows. **But R6's absence means no post-region-read fence applies to the new
accepts.** Cross-reference bd `3d8q` (P1): the pass-wide stale-record guard sweeps PURE
ops only, so a `cq_theta`/`cq_measure` reader of a stale name is never asked. That hole
is about sibling thetas on one rail and is *not* reached by the prep (a fresh rail), but
the round must probe it — the two are one question apart. Also cross-reference bd `r10v`
(the 4.4 compare-select classifier has no measured-before rung at all).

**H-6 — implement the exclusion at the TEST, not at the ANCHOR. This is the one way to
get the change catastrophically wrong.** If `CondWire` members are dropped from `Cand`
(or from the fp anchor's seed) instead of from the equality test, the forward walk never
starts, and **all 21 class-B fixtures flip too** — including the six F-R1-1 CONFIRMED
plain-C miscompiles, the 30-program sideways family and the four curated-intrinsic
rails. The anchor must keep seeding; only the *answer* is filtered.
**Tripwire:** `…_reject_stateprep_fcmp_oeq_derived_still.ll` + `range_forward_add` go red
on the anchor spelling and green on the test spelling. Make that a stated mutant.

**H-7 — the residual at `i1`.** After the narrowing an `i1` seed still collides with any
tainted `i1` **not** on this branch's wire — a second, independent compare's result, or
another `bool` rail. That is correct and must keep a fixture
(`…_reject_stateprep_second_flag_i1.ll`). It is also why the ruling should be phrased
*"the `i1` width is no longer categorically out"*, not *"`i1` is in"*.

**H-8 — `Truncated` must stay untouched.** MEASURED this session: `step_cap_over`,
`unevaluable_pinned_operand` and `unfoldable_curated_call` still decline after a cone
mutation, i.e. their declines do not run through the test at all. The narrowing must not
add a `CondWire` check on any path that sets `Truncated`, or the conservative half — the
one that catches what LLVM's own machinery cannot evaluate — becomes selectively
skippable.

**H-9 — interaction with the eq-fold re-anchors.** `straightThroughConstFoldHandle`
(`ArmClassify.cpp:2324`) and `tryEqFoldArm` (`EqFoldArm.cpp:27`) read a folded constant
the *other* way — as evidence to re-anchor onto the register. Both are gated off the
state-prep shape today (`H != Base` at `:2369`; D6 requires a **pure phase spine**), so
there is no live conflict. **But the same IR now has two readers with opposite
policies**, and CLAUDE.md §14.2d already records that asymmetry as a known oddity. The
round must re-measure that D6/`H != Base` gating rather than assume it.

**H-10 — the owner's file does not become compilable.** Shipping this narrowing alone and
reporting "the prep now compiles" would be false for `grover_oracle_uncompute.c`. It is
wall 3 of 3 (§4). Sequence it after (or with) `l4x4`, and note that `b6ap` is independent
of both.

---

## §7 COST

| item | estimate | basis |
|---|---|---|
| pass diff | ~6 lines added, ~18 deleted (the dead fast path), 5 call-site tokens | §5.1, read from the shipped source |
| comment/rationale rewrite | ~130 lines re-stated | `ArmClassify.cpp:1190-1194`, `:2883-3010` |
| fixtures rewritten decline→accept | **19** | §3(A), each measured |
| fixtures gaining one explanatory sentence | **21** | §3(B) |
| new fixtures | **≥8** (5 accept / 3 decline), incl. the H-6 tripwire pair | §5.3 |
| e2e | **≥1** STRICT slice + golden (no `compare_files` twin — no byte-identical twin exists) | drbq Inc-4 precedent |
| corpus sweep | all 1776 fixtures, expect 19 DECLINE→ACCEPT, **0** ACCEPT→DECLINE, 0 string changes | monotone by construction; must be measured, not asserted |
| Rule-13 | **≥1 independent adversarial round; budget 2** | F2 lost 4 consecutive rounds (drbq Inc-4 R1–R4); this is an accept-widening of that same fence |
| docs/bd | CLAUDE.md (the "i1 WIDTH IS OUT" paragraph → dated HISTORY), PRD §14.2b/§14.11, INC4_NOTES ERRATA, `drbq.14`, 2 bd memories, 1 new bd issue | §5.5 |

**Owner's decision, in one sentence:** *accept that two plain-C programs which `-O1`
makes byte-identical — a state prep and a rotation of the condition register itself
(and, at `i32` with `!=`, a copy-mux of the condition register) — will from now on both
compile as the state prep, silently, because the other reading has never had a lowering
in CQ and declines in every spelling that survives `-O1` intact.*
