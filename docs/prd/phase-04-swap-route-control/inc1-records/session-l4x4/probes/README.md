# Probes — bd `test_C_libtooling-l4x4` (3qlq Inc 1b-C) SCOPING

READ-ONLY session, 2026-09-11, `main` at **0c7380c** (`git status --porcelain` clean).
Every verdict below is the **landed `main` binary** `build/ir-pass/cq-opt`, measured — never
predicted. Nothing under `ir-pass/`, `include/`, `runtime/`, `tests/` or `tools/` was touched.

## How each row was produced

```sh
LLVM=/usr/local/opt/llvm@19/bin
$LLVM/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S P.c -o P.s1.ll
<repo>/build/ir-pass/cq-opt -load-pass-plugin <repo>/build/ir-pass/libCQPass.so \
    -passes=cq-lowering -S P.s1.ll -o P.s2.ll          # rc + diagnostic string
CQ_CTRL_DBG=1 <repo>/build/ir-pass/cq-opt -passes=cq-lowering -S P.s1.ll -o /dev/null \
    2>&1 | grep CQ_CTRL_DBG                            # the DECLINE ANCHOR
```

`run.sh` in this directory is exactly that, plus the `br i1` / `select` counts of the
stage-1 IR (`brs=` / `sel=`), which is how "what shape does `-O1` actually hand the pass"
was decided rather than assumed.

## Naming

* `tNN_*.c` — the RAIL (bare `_Bool` register) spelling, the 1b-C subject.
* `tNNc_*.c` — its **COMPARE twin**: the identical program with `int q = cq_theta(…);
  if (q == 5)`. The twin is the oracle — it says what the shipped drbq Inc-1/2b/3/4
  lowering does for the same source, and therefore what 1b-C must reduce to.

## Verdict table

See `../SCOPE_l4x4.md` §0.1. Every row there is one file here.

## The four rows that changed the shape of the increment

* **`t2` / `t2c`** — the `if/else` twin is NOT a diamond from plain C. `-O1` folds it to an
  **angle select** (`select i1 %b, double 0.9, double 0.3`), so the if/else half of 1b-C is
  `AngleSelectEmit`'s Ry stem, not `emitInPlaceRotationRegion`'s two-arm path.
* **`t5` / `t5c`** — the IN-LOOP rail form reaches `classifyArms` (`bare i1 register
  condition`) while its COMPARE twin declines `condition predates a non-diagonal gate`
  (CLAUDE.md row W: LICM hoists the invariant compare, `condWireDisposition`'s P4 refuses a
  cross-block condition). `railCondWireDisposition` has NO P4 prong, so the rail form has a
  capability the compare form structurally cannot express — and therefore **no twin to be
  byte-identical to**.
* **`t6` / `t6c`** — "Ry on the condition's own wire" is NOT caught by R4/S8 from plain C.
  `-O1` folds the arm's `cq_theta(b, θ)` to `cq_theta_i1(i1 true, θ)`, i.e. a STATE PREP,
  for which R4/R6 are SKIPPED; the fence that fires is **F1's second clause**,
  `state prep merged with a quantum register` (the merge's Pred incoming is the rail).
* **`t7` / `t7c`** — `if (!b)` IS plain-C reachable (an orientation-B diamond), and the
  compare twin lowers it with a `cqrt_x(flag)` **bracket**. A `cqrt_x` on a user register is
  forbidden by Inc 1b, and unlike the phase path there is no diagonal identity to fall back
  on. Negation is the increment's one genuine design decision.

---

## IMPLEMENTATION probes (bd `l4x4.b`, branch `l4x4b-bool-ry-arm`)

Added by the IMPLEMENTATION session, 2026-09-11, under `impl/`. Every verdict is
measured THREE WAYS with `impl/run3.sh` (single TU) or `impl/run3m.sh` (an
`llvm-link`ed pair): **ORACLE** = `main` 0c7380c, **F2** = the base checkpoint
578dbc4 (Track C, bd `drbq.14`), **SUBJ** = this branch. The SUBJ column is the
only one that moves; where ORACLE and F2 differ the difference is Track C's, not
this increment's.

| probe | shape | ORACLE | F2 | SUBJ |
|---|---|---|---|---|
| `impl/o1_owner_second_region.c` | the OWNER's second region in isolation: a `_Bool` state prep under a NEGATED bare rail | `bare i1` | `bare i1` | **rc 0** |
| `impl/p1_sibling_theta_real.c` | the REAL F-1b-1 class (TAINTED seed, so `-O1` cannot fold the siblings apart) | `bare i1` | `bare i1` | `condition predates a non-diagonal gate` |
| `impl/p2_chained_between.c` | a chained theta between the rail's def and the branch | `bare i1` | `bare i1` | same |
| `impl/p3_rival_on_cond_wire.c` | the α RIVAL of `t6`: in-place Ry on the condition register, register kept live | `bare i1` | `bare i1` | `state prep merged with a quantum register` |
| `impl/p4_opaque_seed.c` | a rail whose classical seed is an opaque run-time value | `bare i1` | `bare i1` | **rc 0** |
| `impl/p5_classical_call_arm_rail.c` | ⚠ **NOT the 6.5 arm** — see F-4 below | rc 0 | rc 0 | rc 0 — `-O1` folds it to a 4.4 DATA SELECT, already shipped by bd `r9e5`; NOT this class |
| `impl/p6_eqfold_rail.c` | ⚠ **NOT an eq-fold** — a `cq_phi` arm on a rail | rc 0 | rc 0 | rc 0 — the 3qlq Inc-1b KICKBACK, already shipped |
| `impl/multi/w1_*.c` | H-2 round-2 window, 6.5 arm IMMEDIATELY before the rail region | `bare i1` | `bare i1` | `control flow` — see ⚠ below |
| `impl/multi/w1c_caller.c` | its COMPARE twin | **`control flow`** | **`control flow`** | `control flow` |
| `impl/multi/w2_*.c` | the same with an opaque CLASSICAL diamond in between | `bare i1` | `bare i1` | `condition predates a non-diagonal gate` (**from `reverifyRailCondReads`**) |
| `impl/multi/w3_caller.c` | the rung-(ii) half: the `%out`-derived PARENT measured before the branch | `bare i1` | `bare i1` | `condition measured before the control route` (**from `reverifyRailCondReads`**) |
| `impl/ir/a_value.ll` | §2.6 VALUE class on a rail (hand IR) | `bare i1` | `bare i1` | `bare i1` (now from the per-class re-decline) |
| `impl/ir/b_ifelse.ll` | a two-arm if/else on a rail (hand IR) | `bare i1` | `bare i1` | `bare i1` (the one-content-arm fence) |
| `impl/ir/c_multigate.ll` | a multi-gate arm (R1) on a rail | `bare i1` | `bare i1` | `control flow` |
| `impl/ir/d_condwire.ll` | the rotated base is a CAST of the condition | `bare i1` | `bare i1` | **rc 0** — a cast is a different physical wire |
| `impl/ir/d2_condwire.ll` | the arm rotates the condition register ITSELF | `bare i1` | `bare i1` | `condition predates a non-diagonal gate` |
| `impl/ir/e2_emptyarm.ll` | §2.6 PHASE class on a rail (an EMPTY arm) | `bare i1` | `bare i1` | `bare i1` (per-class re-decline) |
| `impl/ir/f_undefangle.ll` | an `undef` angle on a NEGATED rail arm | `bare i1` | `bare i1` | `rotation angle` |

### Three measurements that changed the shape of the implementation

* **`t10` IS NOT THE F-1b-1 CLASS AT `-O1`, and SCOPE could not have known.** Its
  seed is the CONSTANT `false`, so `-O1` const-folds BOTH siblings' arg-0 and they
  become two SOURCE thetas on two SEPARATE rails — the accept is correct, and
  MEASURED (two `cqrt_alloc_i1`, the gate on the one the branch names). The real
  sibling shape needs a TAINTED seed, which is `impl/p1_sibling_theta_real.c`.
  A fixture built on `t10` would have pinned nothing.
* **`w1` EXPOSED A PRE-EXISTING, ARM-CLASS-INDEPENDENT DECLINE.** A 6.5
  classical-call-arm region IMMEDIATELY followed by a flat control region declines
  `control flow` at `lowerControlRegions`' hcrg precedence graph:
  `sequentialChainAlias`'s `reorderable()` admits only `BranchRegion` and
  `PhaseKickback` kinds, so `A.Pred == B.MergeBB` with a `ClassicalCallArm` `B` is
  an unresolvable alias. MEASURED on `main` with the COMPARE twin
  (`impl/multi/w1c_caller.c`), which declines identically — so it is not this
  increment's, and it is why the H-2 fixtures interpose an opaque classical
  diamond (`w2`/`w3`) to move the rail region out of that block.
* **`t16b` (an `i1` STATE PREP under an `i1` rail) ACCEPTS**, where SCOPE §2.5
  predicted an F2 collision. That is Track C's narrowing, not a hole: the pinned
  register IS the condition, so it is in `CondWire` and excluded. Pinned as
  `ir-pass/test/control_inplace_ry_stateprep_rail_i1_seed.ll`.

### The owner's file, measured

`impl/V0_owner_file_2026-09-11.c` is the committed snapshot of
`example/grover/grover_oracle_uncompute.c`. On ALL THREE binaries it is
**`rc 1`, `cq controlled lowering: control flow under quantum control`**,
anchored (`CQ_CTRL_DBG=1`) at `br i1 %1, label %4, label %2` — the FUSED second
and third `if`, carrying TWO merge phis. That is **wall 1**, bd `b6ap`, on
another branch; l4x4.b moves wall 2 and cannot move this one. Its SECOND REGION
IN ISOLATION (`impl/o1_owner_second_region.c`) lowers here, in seven trace lines,
and is committed as `tests/e2e/slice_control_inplace_ry_bool_stateprep_negated.c`.

---

## ⚠ ROUND-1 RULE-13 REVIEW (`../review_l4x4b_r1.md`, CLEAR-WITH-ITEMS) — corrections to THIS file

**F-4 — `impl/p5` and `impl/p6` do not measure what their first headers claimed,
and the record cited them for two `SCOPE_l4x4.md` §2.6 partition rows.** Both
probe headers have been rewritten with the measurement; the table rows above are
marked. Re-measured on the fix binary:

* **`impl/p5_classical_call_arm_rail.c` — 0 `br i1`, 2 `select i1` after `-O1`.**
  The `noinline const` callee's arm folds to a `select i32`, so there is no
  control region and `classifyClassicalCallArm` is never reached: the program is
  compiled by bd `r9e5`'s 1b-B.1 rail DATA-SELECT with `CopyRailRoot`
  (`cqrt_alloc_i1; cqrt_cnot; 2 × cqrt_copy_i32_controlled; cqrt_x; cqrt_cnot;
  cqrt_free`) and ACCEPTS, on this tree AND on `main` 0c7380c. It therefore says
  nothing about §2.6's CLASSICAL-CALL row in either direction. The fact it DOES
  establish is worth carrying for bd `54ur`: **the plain-C spelling of "a pure
  classical call in the arm of a bare-`_Bool` `if`" is already compiled**, so
  `54ur` needs a spelling `-O1` does not fold, and measuring that is its
  implementer's first job.
* **`impl/p6_eqfold_rail.c` contains no equality and emits `cqrt_rz_i1`** — the
  3qlq Inc-1b branch-phase KICKBACK. `tryEqFoldArm`'s subject is an
  `if (q == K)` diamond reached through an `ICmpInst`, which a bare rail cannot
  present. It is kept as a real regression probe for the SEPARATION l4x4.b relies
  on (a `cq_phi` arm on a rail must keep going to the kickback and must not be
  captured by the new rotation-arm path).

**Neither §2.6 row has a dedicated fixture**, and `IMPL_l4x4b.md` §8 Q9 now says
so instead of implying coverage. What fences them is
`classifyClassicalCallArm`'s own `isa<CmpInst>` early return and
`declineRailClass()` at the eq-fold accept site — **read, not measured.**

**F-3 — the `w1` over-decline is now FILED: bd `test_C_libtooling-35t0`** (P2,
pre-existing on `main` 0c7380c). A 6.5 classical-call-arm region immediately
followed by a flat control region declines `control flow`, because
`lowerControlRegions`' hcrg precedence graph resolves `A.Pred == B.MergeBB` only
when both regions are `BranchRegion`/`PhaseKickback`
(`SwapRouteEmit.cpp:2459`'s `sequentialChainAlias` → `reorderable()`), so a
`ClassicalCallArm` predecessor is an alias ordering cannot resolve. Measured on
ORACLE, F2 and this tree alike with the COMPARE twin
(`impl/multi/w1c_caller.c`), i.e. arm-class-independent. The independent reviewer
re-derived it from the source; it cost this increment the `w2`/`w3` opaque-diamond
interposition and will cost the next one the same.

**F-1 — the three probes that found the round's one wrong unitary live in the
REVIEWER's directory, not this one**: `../review_l4x4b_r1_probes/x01_neg_inf_angle.c`,
`x02_neg_nan_angle.c`, `n11_neg_runtime_angle.c`, with the compare twin
`x01c_neg_inf_cmp.c` and the `θ = 0.0` control `n12_neg_zero_angle.c`. Their
shapes are now committed as fixtures
(`control_inplace_ry_reject_rail_negated_{inf,nan,neginf}_angle.ll` and the three
accept controls) — see `IMPL_l4x4b.md` §4a-R1 / §4b-R1 and §8 Q8.
