# PRD — g5gi: guarded Shadow store widening (swapped / negated arm + multi-store)

> **Status:** DRAFT, opened 2026-07-07. Additive coverage on iw81.7 (core DONE +
> Rule-13-cleared, commit `48a4d59`). Parent epic `8h7d` (7.x widenings,
> freeze-orthogonal — adds NO frozen symbols). This touches the lowering CORE
> (the flag mint + the cross-region pre-flight) → a Rule-13 adversarial clearance
> is REQUIRED before commit. Bennett.jl remains the store-mechanics ground truth.
>
> **Scope (g5gi):** two additive accepts on the existing v1 guarded-store shape.
> **NOT in scope:** deeper nests (issue-body item 3 — needs the iw81.14 block
> path-predicate OR-reduction) and two stores in ONE arm block (a separate
> `soleSideEffectStore` widening). Both still decline LOUDLY (Prime Directive).

---

## 0. What v1 declined, and why each is a SAFE additive follow-on

iw81.7 v1 accepts ONLY the **un-negated (TRUE-successor) depth-1** store arm and a
**single** guarded-store diamond. Two adjacent shapes decline today — safe, not
correctness debt:

1. **Swapped / negated arm** — `clang -O1` canonicalizes `if (q != k) { arr[i]=v; }`
   to `icmp eq; br eq, %merge, %arm` (Rule 9): the side-effect-only store arm is the
   **FALSE** successor, so the store must fire on `¬(q==k)`. v1 declined this with
   `guarded store on a swapped branch`.

2. **Multi-store** — two SEPARATE guarded-store diamonds that share a block
   (`if(q<3){arr[i]=7;} if(q<5){arr[j]=8;}`, where the first diamond's `%merge1` is
   the second diamond's `Pred`). BOTH diamonds are ACCEPTED by
   `classifyGuardedStoreArm`, but `lowerControlRegions`' **cross-region
   block-lifetime pre-flight** declines: it marks the first region's `MergeBB`
   (`%merge1`) as "doomed" and sees the second region reference it (as `Pred`). The
   pre-flight is **over-conservative for guarded stores**: unlike the phase / if-else
   flatten, `emitGuardedStoreArmRegion` **does NOT erase `MergeBB`** — it erases only
   the `Arm` block and rewires `Pred → MergeBB` unconditionally.

---

## 1. Feature 1 — the swapped / negated arm: **negated mint**, not `cqrt_x` brackets

The issue sketched "fire the store on the ¬flag brackets (`cqrt_x`) threaded through
the guarded `_controlled_unc`." That path is **rejected** — it is unsound with the
current uncompute spine:

- The guarded store's flag is STRIPPED by the whole-DAG LIFO uncompute (the flag-mint
  compare is a reversible DAG ancestor; the spine appends `_unc` to reverse it). A
  `cqrt_x(flag)` bracket in the forward stream would have to be **recovered and
  reversed by the spine** in strict reverse order relative to the store's
  `_controlled_unc`.
- But `ChainWalk::isInPlaceGateOn` does **NOT** recognize `cqrt_x(H)` as an in-place
  gate on `H` (it matches only `cqrt_ry/rz`, plain + guarded `cqrt_qram_store`). So
  the spine would silently DROP the `cqrt_x` brackets from the reversal — the
  `store_..._controlled_unc` would then read the flag at its `icmp` value, NOT `¬flag`
  → un-pops the store on the WRONG basis branch (a dephasing silent miscompile).
  Teaching `isInPlaceGateOn` about `cqrt_x` is a broad blast-radius change to the
  core spine vocabulary (it would also perturb every select / if-else `¬flag`
  bracket) — declined.

**Chosen design — negated mint.** For a FALSE-successor store arm, mint the flag with
the **inverse predicate** (`CmpInst::getInversePredicate`): the guard IS `¬cond`, so
`flag = icmp_ne(q,k)` (for `br [q==k]`) fires the store exactly on the taken (false)
edge. NO bracket. The spine reverses `cq_template_icmp_ne_i32_hl` via
`cq_template_icmp_ne_i32_hl_unc` — **identical** machinery to the un-negated case;
only the predicate string differs. Every integer inverse predicate (`slt↔sge`,
`eq↔ne`, `ult↔uge`, …) has a forward AND `_unc` template already (verified in
`runtime/cq_templates.h`). fp-tainted conditions never reach here (the width gate
`widthHasReversibleCopy` rejects `f64`), and any out-of-scope inverse self-declines
loudly inside `lowerCompareToFlag` (`compareInScope` → `diagnoseNoTemplate`).

**Correctness (analytic, Rule 2).** Forward: `flag = ¬cond`; `store_c(flag,arr,i,v)`
fires iff `flag=1` iff the FALSE edge is taken ✓. Reversal (LIFO):
`store_c_unc(flag,...)` un-pops iff `flag=1` (same polarity) → then
`icmp_..._unc(flag,q,k)` recomputes-and-XORs `flag ^= ¬cond` → `flag=0` (q untouched
by a store) → `cqrt_free(flag)`. Byte-for-byte the un-negated reversal with an
inverse predicate. The `railOf`/`Earliest`/free-point reasoning is unchanged.

**Impl.** Add `bool negate=false` (defaulted, END of the arg list — no existing
call-site churn) to `lowerCompareImpl`/`lowerCompareToFlag`; when set, apply
`getInversePredicate` to the predicate BEFORE the existing classical-on-left
`flipPredicate` (`getInversePredicate` ∘ `getSwappedPredicate` commute for integer
predicates). `lowerCompareToFlagRail` passes `negate=false` (nested control is a
separate path). `classifyGuardedStoreArm` drops the `if (Negated) decline`, sets
`R.ArmNegated = Negated`; `emitGuardedStoreArmRegion` passes `negate = R.ArmNegated`.

---

## 2. Feature 2 — multi-store: exempt the guarded MergeBB from the pre-flight

`emitGuardedStoreArmRegion` erases **only the `Arm` block** (`ArmBB->eraseFromParent()`),
the dead `br`, and the dead compare. It leaves `Pred` and `MergeBB` intact (Pred is
rewired to an unconditional `br MergeBB`). So a `GuardedStoreArm` region's genuine
"doomed" set is **`{Arm}`**, NOT `{Arm, ArmFalse, MergeBB}`.

**Impl.** Replace the inline `{B.Arm, B.ArmFalse, B.MergeBB}` doomed list in the
pre-flight with a per-region-KIND helper `doomedBlocks(R)`:
- `GuardedStoreArm` → `{Arm}` (MergeBB survives; ArmFalse is null anyway);
- every other kind → `{Arm, ArmFalse, MergeBB}` (unchanged — nulls skipped).

This is a NARROW, direction-aware exemption: only a GUARDED region's own MergeBB is
lifted from "doomed". A phase / if-else region that DOES erase its merge keeps
MergeBB in its doomed set, so a guarded region whose `Pred` is a phase region's merge
still declines (the phase flatten really would erase it) — defense-in-depth intact.

**Correctness.** Two guarded diamonds `A` (`Pred=entry,Arm=arm1,MergeBB=merge1`) and
`B` (`Pred=merge1,Arm=arm2,MergeBB=merge2`): `A` doomed `{arm1}`, `B` doomed `{arm2}`.
Neither references the other's doomed block → both emit. `A`'s flatten rewires
`entry→merge1` (merge1 survives, still holds `%f2`+`br`); `B`'s flatten splices arm2
into merge1, rewires `merge1→merge2`. Independent, order-insensitive. The whole-DAG
uncompute recovers both stores as in-place gates on the shared array handle and
reverses them + both flag strips in strict reverse program order (two flags, freed
each after its own strip; array handle never freed §2.9). Nested cell overwrites
reverse via the runtime's per-store LIFO tape (same as the existing multi-access
Shadow array).

---

## 3. Decline matrix (unchanged — the boundary of g5gi)

Still loud-declines (fixtures pin each):
- a guarded store NESTED inside another tainted diamond (`instUnderTaintedControl(BI)`
  → `guardedShadowStoreShapeImpl` false → carve `NotQram` → generic taint-escape /
  `recoverRegionTree` nested decline) — issue item 3, deferred to iw81.14;
- two stores in ONE arm block (`soleSideEffectStore` → null) — a separate widening;
- the pre-existing v1 declines (cond-reads-memory §3c, arm side effect, merge value,
  Q+Q / unsupported-width / non-HL condition, fp/i128 cell, dynamic-N/heap/aliased).

---

## 4. Test plan (Rule 12 red-green + Rule 16 e2e smoke)

- **Positive** `lowering_qram_guarded_store_swapped.ll` — the ex-reject fixture
  repurposed: `if (q != 3)` → `icmp eq; br eq, merge, arm`; CHECK `icmp_ne` mint +
  `store_i32_controlled` + `store_i32_controlled_unc` + `icmp_ne_..._unc` strip +
  free, ordered.
- **Positive** `lowering_qram_guarded_store_multi.ll` — two diamonds sharing a block;
  CHECK two guarded stores, two flags, two strips, reversal LIFO order, array not
  freed. (An un-negated + a negated variant to exercise the compose.)
- **Negative** `lowering_reject_qram_guarded_store_nested.ll` — a nested guarded
  store; mirror the decline string char-for-char.
- **Negative** `lowering_reject_qram_guarded_store_two_arm.ll` — two stores in one
  arm; mirror the decline string.
- **e2e** extend/add a slice that links + trace-diffs a swapped and/or multi-store
  guarded store (the only layer that proves every emitted symbol resolves).

## 5. Rule-13 clearance gate

Core-touching (flag mint + pre-flight). Independent adversarial review over the
swapped-polarity flag/strip correctness, the multi-store DAG reversal ordering + flag
frees, and the pre-flight exemption's direction-safety BEFORE commit. Green suite
alone does not clear it.
