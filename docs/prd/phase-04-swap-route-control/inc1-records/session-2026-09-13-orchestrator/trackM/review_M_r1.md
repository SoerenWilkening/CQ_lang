# Rule-13 REVIEW, round 1 — Track M (bd `boi6` D-B, `8xaw`): the REGION-MERGE-φ rail leaf for the 4.4 DATA SELECT

Independent adversarial review, 2026-09-13. Model: opus. SUBJECT worktree
`/Users/sorenwilkening/Desktop/CQ_mphi` (branch `mphi-rail-leaf`); ORACLE
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`. Protocol row "review": **no build, no suite**.

## VERDICT — CLEAR-WITH-ITEMS

**No over-accept found.** The increment's central safety property holds and I could not break it: an
accepted merge-φ select can only reach an emitted stream if, at emit time, the select's condition is a
`cq_theta_i1` CALL. Everything else is a loud `control flow` decline before any mutation. Two
over-declines, one doc defect that must not be left standing (it invites deleting a load-bearing backstop),
one missing fixture, one pre-existing `3d8q` reproducer to file.

## Build-side obligation (my ONE gate)

```
ran: shasum -a 256 /Users/sorenwilkening/Desktop/CQ_mphi/build/ir-pass/cq-opt
     ae216b3727f5b1ec6e621474631bc99c2225a8edda99cc3c8c5eae1bd942da97   MATCHES GATES.md
ran: shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
     fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661   MATCHES PROTOCOL.md
```
No mismatch ⇒ no FINDING. Cited, not re-run: `ir-pass-lit` 1908/1907 PASS/1 XFAIL/0 FAILED @ `ae216b3727f5b1ec`
(GATES.md line 50); injection matrix 56 applied / 0 MISSED / 0 N/A @ `ae216b37` (line 47); corpus sweep
@ `ae216b37` vs `fbbe0820` (line 51, IMPL_M.md §6: 2696 rows, 2672 unchanged, 0 ACCEPT→DECLINE, 0
both-accept lowered-IR changes); the 4 e2e slices 4/4 (line 48); `p3d8q_sibling_rail` ACCEPT on the ORACLE
(line 42). **I ran no build and no suite; I used 0 of my 1 allowed `lit --filter`** (the fixture spot-check
below was done by running `cq-opt` directly on the fixture, which is a probe, not a lit run).

Probes + runner: `review_M_r1_probes/` (`./run.sh` — it re-checks BOTH hashes and aborts on a mismatch; per
probe it runs the `PROTOCOL.md` pipeline 1/2/2b/3/4 on the SUBJECT and on the ORACLE).
Scratch: `/private/tmp/claude-501/.../scratchpad/trackM_review/`.

## Measured verdict table (`ran: ./review_M_r1_probes/run.sh`)

| probe | shape | SUBJECT | ORACLE |
|---|---|---|---|
| `r01_inplace_arm_bool` | in-place Ry **ARM** (not a prep) on a `_Bool` rail, select on its φ | DECLINE `condition predates a non-diagonal gate` | DECLINE `control flow` |
| `r02_ifelse_both_arms` | if/else prep, both arms rotations (`-O1` → angle select) | DECLINE `rotation angle` | same |
| `r03_order_third_region` | `if (b1) a-=3; if (a==2) cq_phi(.3);` | DECLINE `control flow` **at the select, AT EMIT** | same |
| `r04_order_same_cond` | `if (b1) a-=3; if (b1) cq_phi(.3);` | DECLINE `control flow` at the **φ** (the `br`) | same |
| `r05_two_selects_distinct` | two selects on one φ, distinct registers | **ACCEPT 43**, 2b `4 free: 4 verified, 0 violation(s), 0 unproven` | DECLINE `control flow` |
| `r06_round2_window` | first (failed) round-2 attempt — `-O1` fused the guards | DECLINE `control flow` at the 6.5 `br` | same |
| `r07_phi_other_users` | φ also read as DATA after the select | **ACCEPT 31**, 2b clean | DECLINE `control flow` |
| `r08_measure_after_select` | `cq_measure(b1)` AFTER the select | **ACCEPT 29**, 2b clean | DECLINE `control flow` |
| `r09_prep_seed_nonzero` | prep seed `true`, not `false` | **ACCEPT 29**, 2b clean | DECLINE `control flow` |
| `r10_mixed_value_rotation` | `ClassArm=Value` + `ClassArmFalse=InPlaceRotation` | DECLINE `state prep seed does not match the merge incoming` | same |
| `r11_mixed_rotation_value` | the same, arms swapped | DECLINE, same string | same |
| `r12_phi_second_user_survives` | φ's second user survives as its OWN select | **ACCEPT 41**, 2b clean | DECLINE `control flow` |
| `r13_m16_runtime_a` | `m16`, run-time `a` | **ACCEPT 31**, 2b `3 free: 3 verified` | DECLINE `control flow` |
| `r14_i2_cmpladder` | compare-guarded prep (the item-2 widening's customer) | **ACCEPT 21**, 2b `2 free: 2 verified` | DECLINE `control flow` |
| `r15_p3d8q_sibling` | bd `3d8q` siblings through the φ | **ACCEPT 31** (see F-M5) | DECLINE `control flow` |
| `r16_p20` | boi6 `p20` verbatim | DECLINE `condition predates a non-diagonal gate` | DECLINE `control flow` |
| `r17_owner_file` | the owner's file | **ACCEPT 29**, 2b `8 mints / 6 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven` | DECLINE `control flow` |
| `r18_third_is_select` | r03 with the third construct a DATA SELECT | **ACCEPT 40**, 2b clean | DECLINE `control flow` |
| `r19_third_kick_before` | kickback BEFORE the prep | DECLINE `control flow` at the `b0` theta | same |
| `r20_round2_window` | the REAL round-2 window (6.5 `%out`-guarded prep) | DECLINE `control flow` at the select, **1 diagnostic, detection-time** | same |
| `r21_m30_inloop` | `m30` re-measured | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` | same |
| `r22_inloop_select_outside_prep` | select IN a bounded loop on an OUTSIDE prep's φ | **ACCEPT 43** (rolled), 2b clean | DECLINE `control flow` |

---

## Item 1 — the state vector of every accept, re-derived from the stage-1 IR

**`r17` the owner's file, 29 lines, line by line.** `alloc_i1(0)→h0; ry_i1(h0,½)` — the `a>=3` guard folds
classically, so `b0`'s prep is unconditional. `alloc_i1(0)→h1; ry_i1(h1,½); ry_i1_controlled(h0,h1,−½)` —
`-O1` rewrote `a>=3` (with `a ∈ {2,5}` pinned by `b0`) into `b0 == 0`, so the `b1` prep fires on **¬b0**, and
that is the l4x4.b anti-control by Ry additivity: `b0=0 ⇒ Ry(½)`, `b0=1 ⇒ Ry(½)Ry(−½)=I`. Exact (a sign-bit
flip). Then the `a`-mux: `alloc_i1(0)→h2; cnot(h0,h2)` (a CNOT copy of a superposed register into a `|0⟩`
ancilla = `Σαₓ|x⟩|x⟩`, basis-faithful, `b0` untouched), `alloc_i32(0)→h3` (the out rail), `alloc_i32(2)→h4`,
`copy_i32_controlled(h2,h4,h3)`, `x(h2)`, `alloc_i32(5)→h5`, `copy_i32_controlled(h2,h5,h3)`, `x(h2)`,
`cnot(h0,h2)`, `free(h2)` — `h3 = b0 ? 2 : 5`, and `h2` returns to `x⊕x = 0` on every basis branch, so its
free is a proven-`|0⟩` one (Rule 6). Then the merge-φ select: `add_i32_hl(h3,−3)→h6` (the arm's chain hoisted,
unconditional, on the ORIGINAL rail), `alloc_i1(0)→h7; cnot(h1,h7)`, `alloc_i32(0)→h8`,
`copy_i32_controlled(h7,h6,h8)`, `x(h7)`, `copy_i32_controlled(h7,h3,h8)`, `x(h7)`, `cnot(h1,h7)`,
`free(h7)` — `h8 = b1 ? a−3 : a`. Measures `h0`, `h1`, `h8`. **`h0` and `h1` are read ONLY as controls**
(`cnot` source / `ry_controlled` control): never `cqrt_x`-bracketed, never freed. Both `cqrt_x` pairs are on
the ancillas. ✓ That is the CLAUDE.md §4 invariant, and the fixture
`control_swap_accept_select_mergephi_rail_negated.ll` pins it exactly (spot-check below).

⚠ EMISSION ORDER: the `b1` prep (lines 3–5) is emitted BEFORE the `b0`-mux (6–16), swapped vs source. Same
unitary: both are block-diagonal in `h0`'s computational basis and act on disjoint targets (`h1` vs
`h2…h5`), so they commute. Structural, not a choice — `-O1` left no source order between them.

**`r13` (`m16`, run-time `a`), the THREE freed rails, each proven `|0⟩` at its free.**
(a) `h1` — the CNOT-copy ancilla of the `b0` rail, un-copied at line 12 (`cnot(h0,h1)`) ⇒ `x⊕x = 0`.
(b) `h5` — the compare flag `icmp_sgt_i32_hl(h2,2)`, stripped by its `_unc` at line 17. The gate it controlled
(`ry_i1_controlled(h5,h6,½)`) is **diagonal in `h5`'s basis**, so it does not disturb the flag and the strip is
still the exact adjoint of the mint: `Σαₓ|x⟩|f(x)⟩(Ry^{f(x)}|0⟩) → Σαₓ|x⟩|0⟩(Ry^{f(x)}|0⟩)`. ⇒ `|0⟩`.
(c) `h8` — the CNOT-copy ancilla of the prepped `b1` rail `h6`, un-copied at line 27. ⇒ `|0⟩`.
2b STRICT `3 verified, 0 violation(s), 0 unproven`. ✓

**`r14` (`i2_cmpladder`), the two ordering questions the brief asks.** The compare flag `h1` is minted (3),
used (5), STRIPPED (6) and FREED (7) — **strictly before** the select's first gate (8). ✓ The prep's M-β
target is the hoisted `ry_i1_controlled(h1,h2,½)` result, i.e. `h2`; the select's CNOT reads `h2` at line 9,
after it. ✓ (Same two answers in `r13`: strip 17 / free 18 / select's first gate 19; M-β target `h6` at 16,
read at 21.)

**`r05`** (two selects, distinct registers) and **`r12`** (the φ's second data user, which `-O1` turned into
its OWN select) are both correct: each select mints its own CNOT-copy ancilla off the ONE prepped rail, writes
its own fresh `|0⟩` out rail, un-copies and frees. In `r12` the two selects are emitted in the reverse of
source order — they commute (disjoint targets, the same read-only control). **`r07`** is the interesting one:
`-O1` ABSORBED `a + (int)b1` into the select's true arm (`a−3+1 = a−2`, trace line 19 `add_i32_hl(h2,−2)`), so
what reads like a data escape is a plain select. **`r09`** (seed `true`) and **`r08`** (measure after the
select) are the shipped 29-line stream unchanged.

---

## Item 2 (ANSWERED) — which `InPlaceRotation` region's merge φ does M-β NOT turn into a `cq_theta` CALL?

**NONE that rung 0 can reach, and the search closes by construction, not by enumeration.**

1. `inPlaceRotationArmTheta` (`ArmClassify.cpp:798`) requires the merge φ's ARM INCOMING to **be** the theta
   (`dyn_cast<CallInst>(ArmIncoming)`) and the theta's **sole user to be the merge φ**
   (`!T->hasOneUse() || T->user_back() != MergePhi → nullptr`). So `Shadow.front()` is the φ's arm value, at
   the φ's own type — and `isCondRailPhiShape` fixes that type at `i1`, hence `cq_theta_i1`, hence
   `isCondRailLeaf`.
2. `emitRegion` (`SwapRouteEmit.cpp:1129-1211`) sends **every** `BranchRegion` with
   `ClassArm|ClassArmFalse == InPlaceRotation` to `emitInPlaceRotationRegion` — both the rail-condition path
   (`:1153`) and the compare-condition path (`:1210`). That emitter's only merge RAUW is `:1105`
   `MergePhi->replaceAllUsesWith(Gates.back().first)`, and `Gates.back().first` is a `CallInst*` that is
   always a theta: the hoisted gate, or (l4x4.b anti-control) its clone `TNeg`, which `:940` explicitly
   installs as the RAUW target.
3. **The one shape that could outrun that dispatch** is `ClassArm == Value` with
   `ClassArmFalse == InPlaceRotation`: rung 0's `TrueArm || FalseArm` disjunction would pass, and
   `emitRegion:1198` dispatches **Value first**, whose RAUW is `:536 MergePhi->replaceAllUsesWith(Sel)` — a
   `SelectInst`, not a call. It is refused by `classifyArms`' mixed-arm fences (`ArmClassify.cpp:3517` in the
   rotation clause and `:4496` in the value clause, both directions). **MEASURED both polarities**: `r10`
   and `r11` decline `state prep seed does not match the merge incoming` on BOTH binaries.

Per sub-case the brief names: the un-negated true-edge prep RAUWs to `T` (a call) ✓; the in-place **ARM**
on a `_Bool` is a legitimate one-wire rail leaf whose M-β target is the CHAINED theta — admitted by the
grammar and by rung 0, and then declined at rung (iii) (F-M3 below, `r01`); the **`i32`** in-place arm never
reaches the grammar (`isCondRailPhiShape` requires `i1`; `-O1` hands those over as an `icmp` compare leaf
instead — the shipped `m11`/`m12` path); the **ANGLE SELECT** is `Kind == AngleSelectRegion`, a different
top-level `Kind`, so `R.Kind != BranchRegion` refuses it at rung 0's first conjunct (`r02` declines
`rotation angle` on both binaries — `-O1` folded the if/else prep into one call with a select on the angle);
**both arms `InPlaceRotation`** chains the two thetas (`setArgOperand(0, Prev)`) and `Gates.back()` is still
a theta ✓; the **4.5 switch** is `SwitchRegion` ⇒ refused; the **in-loop rolled prep** is refused before
rung 0 by the LOOP layer, not by the select (`r21`/`m30`: `cq loop lowering: loop-carried tainted value
crosses iterations`, identical on both binaries).

**And the backstop makes the whole question fail-safe rather than fail-silent.** `emitSelectRegion` re-reads
`Sel->getCondition()` and calls `collectCondTree` **without** `AllowRailPhi`. So if the condition is anything
other than a `cq_theta_i1` call or a compare tree — a surviving φ, a constant (M-α on a prep would RAUW to
the seed), a `SelectInst` — the walk returns false and the LOUD `control flow` decline fires before any
mutation. I confirmed this is a LIVE path, not a theoretical one (F-M1).

---

## Item 3 (ANSWERED) — F-M1: the EMISSION-ORDER premise is FALSE, and its "no subject today" claim with it

**Grade: OVER-DECLINE + DOC. Reproducer: `review_M_r1_probes/r03_order_third_region.c`; control:
`r18_third_is_select.c`.**

`SelectMergeEmit.cpp:96-119` states, as the ground for H-1's fix:

> "…and that region is emitted FIRST (plan index is push order is block order: the diamond's `br` lives in
> `Pred`, the select in the merge block)"

and closes with

> "The φ-still-present-at-emit-time branch has NO SUBJECT today and is stated as such: the only other
> producer of a `SelectRegion` is `SwapRouteEmit::emitValueRegion`, whose conditions are `CmpInst`-only".

**Both sentences are false at HEAD.** `lowerControlRegions` does not emit in plan order: it Kahn-sorts a
PRECEDENCE graph (bd `hcrg`, `SwapRouteEmit.cpp:2543-2617`). A `SelectRegion` has all-null block fields, so
it is **inert** in that graph (`doomedBlocks` all null ⇒ `continue`; `Pending == 0` always). A following
`PhaseKickback` whose `Pred` **is the prep's `MergeBB`** is the sanctioned `sequentialChainAlias`, which adds
`Precedes[kickback] = {prep}` — so the **prep is emitted LAST**, after the select.

Measured, plain C at `-O1`, on BOTH binaries:

```
ran: ./run.sh r03_order_third_region.c      # if (b1) a -= 3;  if (a == 2) cq_phi(0.3);
     SUBJ exit=1  cq controlled lowering: control flow under quantum control
ran: CQ_CTRL_DBG=1 … r03…s1.ll
     CQ_CTRL_DBG: decline [control flow] at:  %7 = select i1 %5, i32 %6, i32 %out
ran: ./run.sh r18_third_is_select.c          # the same, third construct a DATA select (inert in the graph)
     SUBJ exit=0  ACCEPT trace=40  2b 3 verified, 0 violation(s), 0 unproven
```

The anchor is the proof of WHERE it fires: it prints `i32 %out`, the 4.4 emitter's out-rail name, so the
FIRST select's region had already been **emitted** when the diagnostic fired — i.e. this is
`emitSelectRegion`'s H-1 backstop, not `classifySelectRegion`'s rung 0. (It cannot be a round-2 decline:
only `ClassicalCallArmEmit.cpp:226` and `SwitchDataMuxEmit.cpp:151` write `UntaintedMergeRails`, and
`repropagateControlMerges` returns immediately when that set is empty — there is no 6.5/4.5 region in `r03`.)
`r18` isolates the cause to exactly the kickback's precedence edge.

**Order answer, positively.** Where the select DOES emit, the order is source order and the pred-hoist lands
first: `r05` emits prep(14–18) → `a`-select(19–28) → `c`-select(29–39), matching the source; `r13`/`r14` put
the compare flag's whole mint-use-strip-free before the select's first gate. The one place order is inverted
(`r12`, the two selects; `r17`, prep vs mux) the two streams commute — disjoint targets, read-only shared
control, block-diagonal in the control's basis.

**Direction: SAFE.** Nothing is emitted, `opt` exits 1, no output file is written. **Why it is still a
finding:** the source comment tells the next agent the branch has no subject. Under CLAUDE.md L3/L8 that is
exactly the sentence that gets a backstop deleted "for symmetry" — and this backstop is the ONLY thing
standing between a reordered emission and a `SelectRegion` walking freed φ memory. The comment must say:
*the branch HAS a subject (`r03`), it is reached through the `hcrg` Kahn reorder, and the decline it produces
is an over-decline filed as bd `<new>`.*

The second half of item 3 — `if (b1) a -= 3; if (b1) cq_phi(.3);` — is `r04`: it declines `control flow`
anchored on the **φ itself** (`%6 = phi i1 …`), i.e. the phase consumer's `br` is classified before the
block's selects and pre-empts, exactly as H-8 intends. That is the filed `3qps` leaf-grammar over-decline,
unchanged on both binaries. `r19` (the kickback placed BEFORE the prep) declines at the `b0` theta on both
binaries — pre-existing, unmoved.

The `m07`-style two-selects question: with `±1` deltas `-O1` folds the pair away (that IS why the ORACLE's
`m07` accepted). With distinct registers it does not fold — `r05`, ACCEPT 43, order = source order.

---

## Item 4 — H-1 is a re-read, and no other reader of `R.Condition` can see the dangling φ

`grep -n "R\.Condition" ir-pass/src/SelectMergeEmit.cpp` → 5 hits, **all inside comments**. The emitter's two
former dereferences are now `Sel->getCondition()` (`:150`) and `emitCondNetwork(Cond, …)` (`:271`). ✓

`markRailCondRead(taint, Rail, Cn)` at `CondTreeEmit.cpp:248` records `Out.Root`, which
`emitCondNetwork`/`CopyRailRoot` derived from the value the caller passed — and the caller now passes the
**re-read theta call**, not the plan's pointer. ✓ So `reverifyRailCondReads`' `CallInst` cast at
`ArmClassify.cpp:2504` sees a live call, and the H-4 emergent property is not needed to rescue a dangling
record.

Every other plan-`Condition` reader is unreachable for a `SelectRegion`: `flattenRegion`/`flattenRegionTree`
return early on null `Pred`/`Merge`; `emitRegion` is never dispatched one (`lowerControlRegions:2632`
dispatches + `continue`s first); the alias pre-flight cannot pick one as `A` (all four block fields null ⇒
never `Aliases`) or as `B` (`doomedBlocks` all null ⇒ `continue`); the Kahn-cycle `declineRegion` cannot
reach one (`Pending == 0` always, so it is always scheduled). The taint-side consumers
(`declineClassicalMuxes`, `adjudicateTaintDelta`) all read `SI->getCondition()` live, never the plan. ✓

**NOTE, not a finding (retirement trigger worth writing down):** `declineRegion`
(`SwapRouteEmit.cpp:2526`) does `dyn_cast_or_null<Instruction>(A.Condition)` — a read of freed memory the
day a region kind that DOES carry block fields is given a merge-φ condition. It is unreachable today for the
reason above; it deserves the one-line trigger beside it, because `RegionFlatten`'s new
`isCondRailPhiShape` guard was added for precisely this class of future widening and this site was not.

---

## Item 5 (ANSWERED) — the round-2 window: LOUD, at the select, in ROUND 1, one diagnostic

**Reproducer: `review_M_r1_probes/r20_round2_window.c` (+ `r20_round2_window_lib.c`, `llvm-link`ed).** A real
6.5 classical-call arm (`int y = yv; if (q > 5) y = ext_f(7);` with `yv` volatile so `-O1` cannot fuse the
guards — my first attempt `r06` was fused and did NOT build the shape; recorded so round 2 does not repeat
it), then `if (y > 3) b1 = cq_theta(b1, .5);`, then `if (b1) a -= 3;`.

```
ran: ./run.sh r20_round2_window.c
     SUBJ exit=1  cq controlled lowering: control flow under quantum control     (1 diagnostic)
     ORAC exit=1  cq controlled lowering: control flow under quantum control     (identical)
ran: CQ_CTRL_DBG=1 …
     CQ_CTRL_DBG: decline [control flow] at:  %12 = select i1 %11, i32 2, i32 5   (r20…c:16 — the SELECT)
```

**The string is `control flow`, at the select, in ROUND 1** — the anchor text carries **no `%out`**, so
nothing had been emitted yet: this is detection-time rung 0 finding no claimed region, because `y > 3` is
untainted until `repropagateControlMerges`. That is the brief's first disjunct, confirmed. No output file is
written, so no accept sneaks through with the φ unlowered (SCOPE §2.2 (b2) has no subject here).

**And the window cannot be entered silently, by construction.** The φ's arm incoming is a `cq_theta` call —
the taint SOURCE — so the select's condition is tainted in round 1 *unconditionally*, hence gate 1 always
admits it and rung 0 is always asked in round 1. There is no shape in which round 1 skips the select and
round 2 quietly accepts it: round 1 always speaks first, and it speaks loudly.

---

## Item 6 — bd `3d8q`: confirmed, and the φ spelling for the reproducer list

`r15_p3d8q_sibling.c` ACCEPTS on the SUBJECT (31 lines, 2b `2 verified, 0 violation(s), 0 unproven`); the
trace is the proof:

```
27 cqrt_ry_i1(h1, 0x1p-2)      <- bool c = cq_theta(b1, .25)  — CHAINED, in place on h1
29 cqrt_measure_i1(h1) -> 0    <- cq_measure(b1)  reads the POST-rotation state
30 cqrt_measure_i1(h1) -> 0    <- cq_measure(c)   — the SAME register, second SSA name
```

Two SSA names, one physical rail, two measurements, and nothing asks (the pass-wide stale-record guard
sweeps PURE ops only). **Pre-existing**: the rail spelling accepts on the frozen ORACLE (cited: GATES.md
line 42), so Track M adds a CUSTOMER, not a shape — I do not grade it as this increment's over-accept.

**For bd `3d8q`'s reproducer list, add the φ spelling:**
`docs/prd/.../trackM/probes/impl/p3d8q_sibling.c` — ORACLE `fbbe0820` DECLINE `control flow`, SUBJECT
`ae216b37` **ACCEPT 31 lines** (also reproduced here as `review_M_r1_probes/r15_p3d8q_sibling.c`).

I looked for a NEW shape the φ admission reaches and the rail spelling does not, and found none: every
accept I could build has a rail-spelling twin that the ORACLE already accepts, except the two order/loop
cells below.

---

## Item 7 — over-declines met in passing

**F-M3 (OVER-DECLINE)** — `r01_inplace_arm_bool.c` and `r16_p20.c` (boi6 `p20`). The in-place **ARM** φ
(`%7 = phi i1 [%5 = theta(%2), arm], [%2, pred]`) is admitted by the grammar and by rung 0, then declines at
rung (iii)/gate 2c with `condition predates a non-diagonal gate`. **From the state vector the circuit is
valid.** There is ONE physical rail for `b`; `lowerRotations` RAUWs `%2` and `%5` to the same `i32` handle
(chained), M-β RAUWs the φ to `%5`, and `SelectMergeEmit` inserts its whole stream immediately BEFORE the
select — i.e. AFTER the hoisted controlled Ry. So the CNOT copy reads exactly the basis the source's `b`
denotes at that point. The decline comes from the seed set: `condProvenance(φ)` walks the φ's operand edges
and therefore drags the PRE-rotation name `%2` into `RailProv`, on whose wire the arm's own theta sits; the
DT prong only accepts a gate provably AFTER the select, and this one is provably BEFORE, so there is no
accepting reading. Direction safe; string moved vs the ORACLE (`control flow` → the wire string), disposition
unchanged; it is correctly pinned by `control_swap_reject_select_mergephi_chained_arm.ll` (cited: GATES.md
line 60).

⚠ **Do not "fix" it by narrowing the φ's rung-(iii) seed to the arm theta alone.** That cone is also what
keeps an in-place-ARM φ whose PRE-rotation name has SIBLING readers out — i.e. the bd `3d8q` class in its
in-place-arm form. The narrowing is a Rule-13 change to the same fence CLAUDE.md flags for R4, and it owes
the `3d8q` fence first.

**F-M6 (DOC — a measured new accept with no fixture)** — `r22_inloop_select_outside_prep.c`: a 4.4 select
INSIDE a bounded loop whose condition is the merge φ of a FLAT prep OUTSIDE the loop. SUBJECT **ACCEPT 43**
(the loop stays ROLLED: 6 static rail mints, 1 static `cqrt_free` site, 12 dynamic allocs over 3 trips),
ORACLE DECLINE `control flow`. Stream verified per iteration: `alloc_i1→bf; cnot(h1,bf); alloc_i32(0)→out;
alloc_i32(i); copy_controlled; x(bf); alloc_i32(5); copy_controlled; x(bf); cnot(h1,bf); free(bf)` — `h1`
read only as a control, never bracketed, never freed; each trip's ancilla returns to `|0⟩`; 2b STRICT clean.
**Correct.** But `SCOPE_M.md` §4 lists "a φ in a loop" as OUT and pins it with `m30` — and `m30` pins the
*loop-carried* shape (`cq loop lowering: loop-carried tainted value crosses iterations`, which I re-measured
identical on both binaries, `r21`). The outside-prep/in-loop-select cell is a **different** cell, it moved
DECLINE→ACCEPT with this increment, and it has **no fixture and no injection-matrix row** (Rule 12).

**Not a defect:** `m15i` (compare/rail DT-prong asymmetry) and `m31` (ROOT-ONLY) are recorded in IMPL_M.md
§7 with their measured strings and the ROOT-ONLY retirement trigger is written into
`control_swap_reject_select_mergephi_tree_leaf.ll`; I re-derived neither and have nothing to add.

---

## Item 8 — fixture spot-check against the SUBJECT's real output

`ran: build/ir-pass/cq-opt … -S ir-pass/test/control_swap_accept_select_mergephi_rail_negated.ll` (exit 0) and
compared the 29 emitted `cqrt_*`/`cq_template_*` calls to the file's `CHECK`/`CHECK-NEXT` chain and count
prefixes. **Exact match**, in order, including `%[[H]]`/`%[[H4]]`/`%[[BF]]`/`%[[OUT]]` re-use; counts
`XCNT 4`, `FCNT 2`, `CNOTCNT 4`, `CPCNT 4`, `RYCNT 3`, `ACNT 8` all equal the real output. Rule 12(a) is
respected across the 8 new accepts: ONE `%cq-opt` into `%t.cqd0.ll` reused by every prefix, counts in their
OWN whole-file prefixes, negatives (`NOROUTE`/`NOX`/`NOFREE`) pure. Rule 12(b): every reject fixture's
property is pinned by the `not` on the RUN line. The `NOROUTE-NOT: {{= phi }}` re-anchor is present in the
negated fixture (GATES.md line 45 records the 7 re-anchored files and that the anchor was re-validated against
a module that DOES carry a surviving `phi`).

---

## Findings, graded

| id | grade | one line | reproducer |
|---|---|---|---|
| F-M1 | **OVER-DECLINE + DOC** | the `hcrg` Kahn reorder emits a following `PhaseKickback`'s prep AFTER the inert `SelectRegion`, so the H-1 backstop fires on plain C — `SelectMergeEmit.cpp`'s "emitted FIRST" premise and its "NO SUBJECT today" claim are both false | `review_M_r1_probes/r03_order_third_region.c` (control: `r18_third_is_select.c`) |
| F-M2 | **no defect (closed)** | no reachable `InPlaceRotation` region's merge φ fails to become a `cq_theta_i1` call; the Value+Rotation mix is fenced at `ArmClassify.cpp:3517`/`:4496` | `r10_mixed_value_rotation.c`, `r11_mixed_rotation_value.c` |
| F-M3 | **OVER-DECLINE** | the in-place-ARM φ declines `condition predates a non-diagonal gate` because `condProvenance(φ)` seeds the PRE-rotation name; M-β makes the emitted control the post-rotation gate, so the circuit is valid | `r01_inplace_arm_bool.c`, `r16_p20.c` |
| F-M4 | **no defect (closed)** | the round-2 window declines LOUDLY at the select in ROUND 1, one diagnostic, identical on both binaries, no output written | `r20_round2_window.c` |
| F-M5 | **LEAK (pre-existing, bd `3d8q`)** | two SSA names / one rail / two measures across a chained theta; the φ spelling is a NEW customer of a hole the rail spelling already had on the ORACLE | `r15_p3d8q_sibling.c` = `probes/impl/p3d8q_sibling.c` |
| F-M6 | **DOC** | an in-loop select on an outside prep's φ moved DECLINE→ACCEPT, is CORRECT, and has no fixture and no injection row; `m30` does not pin it | `r22_inloop_select_outside_prep.c` |
| F-M7 | **DOC (nit)** | `declineRegion`'s `dyn_cast_or_null<Instruction>(A.Condition)` would read a freed φ the day a block-carrying region kind gets a merge-φ condition — unreachable today, no retirement trigger beside it | `SwapRouteEmit.cpp:2526` |

**None is a CONFIRMED-MISCOMPILE and none is an OVER-ACCEPT.** The two over-declines and the doc defect are
what stand between this and CLEAR; F-M1's comment correction is the one I would not merge without.
