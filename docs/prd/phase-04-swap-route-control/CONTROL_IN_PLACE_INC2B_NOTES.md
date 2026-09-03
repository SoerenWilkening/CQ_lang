# Control-in-place Increment 2b — angle-select **by difference**, both stems

> Design of record: `control-in-place-PRD.md` §12.3 (bd
> `test_C_libtooling-drbq`, tracked in `test_C_libtooling-drbq.3`, folded-in
> `drbq.6`). Read `CONTROL_IN_PLACE_INC1_NOTES.md` (findings J/K/L/M and the §3
> walker audit) and `CONTROL_IN_PLACE_INC2A_NOTES.md` (§2 the stem split, §5 the
> set removals) first — this increment reuses both increments' machinery and
> changes neither.

---

## 0. What shipped, in one paragraph

**The C `if/else` with a rotation on ONE register in each arm now compiles, for
both rotation stems.** `clang -O1` never presents that source as a diamond:
SimplifyCFG merges the two arms into ONE call whose ANGLE is a
tainted-condition `select`, so the branch CFG is gone before the pass runs
(Rule 9) and no swap-route emitter can ever see it. Increment 2b recognizes that
select and lowers the rotation **by difference** — an unconditional `R(h, B)`,
the ordinary flag mint, ONE `cqrt_{ry,rz}_<W>_controlled(f, h, A−B)` (the drbq
Inc-1 / Inc-2a in-place gate), the ordinary `_unc` strip, one `cqrt_free`. It is
exact **in REAL arithmetic** by angle additivity on one axis
(`R(A) = R(B)·R(A−B)`; for `Rz = diag(1, e^{iθ})` the two diagonals multiply
entrywise, so there is no global-phase residue either). **In IEEE double it is
exact up to ONE rounding, which is not the same thing** (round-1 Rule-13 review,
§9 finding 3): the emitted true-arm angle is `B + fl(A−B)`, so
`|δ| ≤ ½ ulp(A−B) ≈ |A−B|·2^-53` — 2^-54 rad on the flagship golden and 0.858 rad
on `π/1e16`. **BOTH ARMS MUST THEREFORE BE `ConstantFP`**, fenced at the
placeholder `kAngleSelectMaxRoundingRad = 2^-40 rad`; a RUN-TIME arm DECLINES
(`rotation angle under quantum control`) — the compiler would synthesize an `fsub`
the source never wrote, whose error is unbounded in absolute radians and whose
result can be `inf`/`NaN` from two FINITE arms, neither fenceable at compile time
(Rule-13 CLEARANCE review, blocker F-11, owner option (2) — **§11**; two earlier
drafts of this sentence read "RUNTIME arms carry the bound" and then "carry BOTH
residual classes", and both described an accept that no longer exists).
**No CFG surgery, no hoist, no flatten, no
`cqrt_x`, no work rail, no route, and no new frozen symbol** — the emitted gate
family is Increment 0's, unchanged.

The central witness is **byte identity with the manual by-difference twin**
(`r = R(r, B); if (c) r = R(r, A−B);`), which is an ordinary in-place diamond the
**pre-2b binary already lowers**. Measured on FIVE plain-C shapes (the flagship
Ry diamond, the Rz twin, Rz on the condition register, the `!=` polarity, and the
mul-derived base with a late use): whole `define` bodies identical, including the
folded difference constant
`0x3FE3333333333334` — the `IRBuilder` constant folder's APFloat subtract equals
`clang`'s own compile-time `0.9 - 0.3` bit for bit.

> **SCOPE THE BYTE-IDENTITY CLAIM TO A BARE COMPARE** (round-1 Rule-13 review,
> lens L4-4). For a DERIVED (`&&`-folded) condition the two forms differ by ONE
> LINE'S POSITION: the derived condition rail's `cq_template_add_*` lands before
> the unconditional twin in one spelling and after it in the other. The rails are
> disjoint and the two instructions commute, so it is the same unitary — but it is
> not byte identity, and `control_angle_select_ry_derived_cond.ll` accordingly has
> NO twin. "Byte-identical to the manual twin" is a claim about the bare-compare
> shape; say it that way.

Scoped to **ONE consumer** per select, and to **CONSTANT** arms. Everything
outside the accept shape declines loudly, and 46 fixtures at hand-back
(15 accept / 31 decline) — **68 on disk after three review rounds, 18 accept /
50 decline**, §5 — plus a whole-corpus disposition sweep pin that.

---

## 1. Files changed

| file | what |
|---|---|
| `ir-pass/src/ArmClassify.cpp` | `railWireClosure`'s forward exclusion parameter renamed `MergePhi` → `Exclude` and re-commented as a CONTRACT (the value that will denote the post-gate register) rather than one caller's spelling; **new** `classifyAngleSelect` (S1–S10) at the end of the file, hosted here because its S8/S9 halves ARE `classifyArms`' R4/R6 and the helpers are TU-local (Rule 14 — no second spelling) |
| `ir-pass/include/ArmAnalysis.h` | `enum class AngleSelectDisp { Accepted, Declined, NotApplicable }` + `classifyAngleSelect` declaration |
| `ir-pass/src/SelectClassify.cpp` | GATE 3 hook: `if (selReachesRotationArg1(Sel))` now tries `classifyAngleSelect` first and falls through to the unchanged `rotation angle` decline on `NotApplicable`; signature gains `wd` / `DT` / `LI` |
| `ir-pass/include/SelectClassify.h` | signature + the null-`DT`/`LI` contract |
| `ir-pass/src/AngleSelectEmit.cpp` · `include/AngleSelectEmit.h` | **new** — the six-step emitter (validate → difference → unconditional twin → mint → rewire+record → strip+free → erase) |
| `ir-pass/src/SwapRouteEmit.cpp` | dispatch on `Kind == AngleSelectRegion`, before the Depth branch, like `SelectRegion` |
| `ir-pass/include/ControlPlan.h` | `AngleSelectRegion`'s comment rewritten for THIS design (it carried retired WP10 vocabulary and was read by no src file); the stale `AnglePhi`/`AngleConsumers` comment corrected — it named `reduceAngleDiamondPhi`, **a function that does not exist anywhere in the repo**; `detectControlRegions` gains `WidthDispatch &` |
| `ir-pass/src/ControlDetect.cpp` | threads `wd`/`DT`/`LI` to `classifySelectRegion`; the lazy `DominatorTree`/`LoopInfo` now triggers on the first tainted BRANCH **or SELECT** |
| `ir-pass/src/RotationLowering.cpp` · `include/RotationLowering.h` | `suffixFromName` de-anonymized (anonymous → named `cq`) so S5 asks the MINT's own width expression; pure refactor |
| `ir-pass/src/CQLoweringPass.cpp` (×2) · `src/TaintPropagation.cpp` (×1) | `detectControlRegions(M, wd, taint)` call sites |
| `ir-pass/CMakeLists.txt` | `src/AngleSelectEmit.cpp` (one list — `cq-opt` derives its sources from the `CQPass` target) |

**Not changed, deliberately:** `RotationLowering`'s two `ControlledRotations`
mint loops (2b is a third WRITER of that map, not a new reader), `ChainWalk`'s
structural freeze, `EmitInverse`, `FreePoint`, `Uncomputation`,
`tools/free_pairing_check.py` (no new symbol), and Inc-1's own
`abiWidthFromType(T->getType())` spelling of the width fence (changing it is a
Rule-13 change to R4's accept set; see §4-F).

---

## 2. The exact diagnostic strings, and which fixture mirrors each

**REWRITTEN IN THE ROUND-2 RULE-13 REVIEW (lens R2 N4), because the round-1
version was stale in four of its seven rows and misattributed a fifth.** The
table below is the MEASURED partition of ALL **50** decline fixtures in this family
(47 until the CLEARANCE review's clause (2c) added three — §11):
every `control_angle_select_reject_*.ll` was run on the built binary and grouped
by the string it actually prints. Regenerate it, never hand-edit it —
`fix2b_r2/strmap.py` is the script, and it is nine lines of `subprocess`.

The opening claim also changed. `classifyAngleSelect` emits **three** strings of
its own, and `AngleSelectEmit` now emits a **fourth** directly — the round-1
step-0/0b plan-vs-IR re-ask calls `diagnoseUnderControl(Sel, "control flow")` from
a DIFFERENT TU. So "three strings of its own; every other refusal returns
`NotApplicable`" is no longer true of the increment as a whole.

| string | who fires it | count | fixtures (stems, minus the `control_angle_select_` prefix) |
|---|---|---|---|
| `rotation angle` | `SelectClassify` gate 3 on `NotApplicable` (S1–S6, S10) | **25** | `reject_cmp_data_use`, `reject_compound_cond`, `reject_constexpr_arm`, `reject_cross_block_consumer`, `reject_inf_arm`, `reject_nan_arm`, `reject_nested_select`, `reject_overflow_difference`, `reject_poison_arm`, `reject_qq_compare`, `reject_rounding_above_bound`, `reject_rounding_one_1e300`, `reject_rounding_pi_1e16`, `reject_runtime_arms`, `reject_runtime_arms_rz`, `reject_runtime_one_arm`, `reject_second_select_same_cmp`, `reject_state_prep`, `reject_tainted_arm`, `reject_tainted_both_arms`, `reject_theta_between`, `reject_two_consumers`, `reject_two_phi_consumers`, `reject_undef_arm`, `reject_undef_constexpr_arm` |
| `stale rail record read past a controlled Ry` | `classifyAngleSelect` S9 (Ry only) | **12** | `reject_lifted_phi_{clone_arg,invert,measure,ret,tape}`, `reject_record_read_on_side_path` (the SKIP-SET fixture), `reject_stale_chained_theta`, `reject_stale_diag_alias_{backward,forward,two_hop}`, `reject_stale_measure`, `reject_stale_ret` |
| `control flow inside a loop body` | `classifyAngleSelect` S7 (all three prongs) | **6** | `reject_in_loop`, `reject_in_loop_rz`, `reject_irreducible_cycle`, `reject_irreducible_cycle_rz`, `reject_loop_rail_exit_block`, `reject_loop_rail_exit_block_rz` |
| `condition predates a non-diagonal gate` | `SelectClassify` **gate 2c**, which runs BEFORE gate 3 | **3** | `reject_cond_alias`, `reject_cond_register`, `reject_theta_before_select` |
| `control flow` | TWO DIFFERENT OWNERS — `SelectClassify` gate 2 (`collectCondTree` off-grammar) for `reject_raw_i1_cond`, and **`AngleSelectEmit`'s step 0 / 0b plan-vs-IR re-ask, a different TU**, for `reject_datamux_qq_after_rauw` | **2** | `reject_datamux_qq_after_rauw`, `reject_raw_i1_cond` |
| `condition data use neither escaped nor measured` | the ziov `condDataUseDisposition`, from the `br` region that shares the compare | **1** | `reject_cmp_shared_with_region` |
| `rotation arm on a condition wire` | `classifyAngleSelect` S8 (Ry only) | **1** | `reject_inplace_alias_base` |

Sum: **50**, which is every decline fixture in the family (`grep -l 'RUN: not'
ir-pass/test/control_angle_select_*.ll | wc -l`); the CLEARANCE review's fourth
new decline, `control_swap_reject_switch_datamux_angle_runtime.ll`, prints
`rotation angle` too but sits outside this name prefix and so is outside this
table. All seven strings are
**pre-existing** — the diagnostic dialect gains nothing new from this increment,
and the clearance narrowing added none either,
which is why the whole-corpus stderr sweep is clean and why
`cq-opt-equivalence-full` stays at 0 mismatches.

> **A `DS_Error` diagnostic terminates the process** (`LLVMContext::diagnose`
> calls `exit(1)`), so exactly ONE message is ever printed and the FIRST guard to
> fire owns it. That is why the message ordering above is a fact about guard
> order, not a preference — and why every `CHECK-NOT: cqrt_*` in a decline
> fixture is vacuous (no IR is printed at all). The real assertion in a decline
> fixture is the string plus the non-zero exit.

---

## 3. THE WALKER / SET AUDIT (PRD §6, the F-1/F-3 obligation)

The standing lesson: **when you widen a set, ask what OTHER set was computed over
the same closure.** Increment 2b touches five sets. Each is enumerated below with
every reader and a verdict.

### (a) `taint.ThetaCalls` / `taint.PhiCalls` **GAIN a member after detection**

This is a genuinely new axis. Increment 2a only MOVED a call inside these
vectors (the hoist); 2b **inserts a call that did not exist when `propagate`
ran**. Every reader, from `grep -rn "ThetaCalls\|PhiCalls" ir-pass/src
ir-pass/include`:

| reader | verdict |
|---|---|
| `RotationLowering::lowerRotations` (both loops) | **THE reason the insertion POSITION is load-bearing.** It walks the vector in order and RAUWs each rotation's result to its i32 handle as it goes; the twin is the consumer's new arg-0, so the twin must lower FIRST. Appending at the end would leave the consumer reading a still-`double`/`i8`-typed operand and mint an ill-typed `cqrt_*`. The emitter inserts immediately BEFORE the consumer's slot; pinned at f64 and i8 (`control_angle_select_ry_{f64_fcmp,i8}.ll`) and mutation-verified (§5). |
| `LoopLowering::collectRailGates` (`GateCalls`) | **CORRECTED TWICE by the round-1 review (lenses L2-2, L5-8), and the correction is the reason S7 grew a rail prong.** The line cites were backwards: `:2802` is `collapseFlattenedLoopRails`, which runs at pipeline step 340, AFTER `lowerControlRegions` and therefore CAN see the twin; `:2837` is `lowerLoops`, which runs at step 310, BEFORE detection (:322) and emission (:323) and therefore CANNOT. And the question is not "can the twin be inside a loop BODY" but **"can the twin be ON A LOOP'S RAIL"** — the rail closure of a register rotated in a loop's EXIT block reaches into the loop, and the shipped `LoopInfo`-on-three-anchor-blocks S7 answered neither question. The second safety reason offered here (`collapseFlattenedLoopRails` returns early unless `InLoopFlattenedPreds` is non-empty) is likewise NOT unconditional: an 8h7d.5 rolled in-loop region in the SAME function makes it non-empty. All of that is now moot for the accept set, because S7 declines the whole family — but it is recorded because the ROW'S REASONING, not just its line numbers, was wrong. |
| `LoopUnrollPrepass`, `CtlzIdiomPrepass` | run BEFORE `detectControlRegions`; cannot see the member. |
| `SpecializeDetect` / `SpecializeReject` | run before detection (the Phase-6 pre-pass is the FIRST step of `run()`); cannot see it. |
| `TaintPropagation.cpp:533` | **Mislabelled (round-1 review, lens L5-3): it is a READER** (`IntrinsicCalls.insert`), not the producer. The producers are `:119`/`:123`. |
| `TaintPropagation.cpp:1107` — `declineClassicalMuxes`' `GateCalls` seed (pipeline step 399, POST-emission) | **OMITTED, and it is the one row here that is LOAD-BEARING** (round-1 review, lenses L2-3 / L5-3 / L6-N6). It seeds from `ThetaCalls`/`PhiCalls`, so it DOES see the twin — and it must: without `T0` in `ThetaCalls`, `resolveWireBase` would stop AT `T0` instead of peeling through it. Measured benign twice: `resolveWireBase` peels correctly, and the one-register lift clause (6) refuses chains containing `T`. |
| `TaintPropagation.cpp:1347`/`:1350` (`repropagateControlMerges`' `FnSet` rebuild) · `Specialization.cpp:1130` · the passthrough `empty()` reads at `:69`/`:527`/`:553` | **OMITTED, all harmless** (same lenses). Listed so the "every reader" claim is true. |
| `CQLoweringPass`'s `onlyInF` scoping | reads the vectors to decide whether a function has quantum content. A twin only ever exists in a function that already had a rotation, so membership cannot flip. |
| the emitters' `PC` scrubs (`RegionFlatten.cpp:40`, `SelectMergeEmit.cpp:65`, `AngleSelectEmit.cpp`) | these ERASE entries. The twin is never erased. **TWO CORRECTIONS from the round-1 review.** (i) "the sibling scrubs" was written over a set of TWO when there are ELEVEN scrub sites in the tree (lens L6-N6) — the comparison is with the two named, not with all of them. (ii) 2b's scrub removing from BOTH vectors was presented as the distinguishing feature; that block is **DEAD AS CALLED** (lens L5-5): `scrubTaint` is only ever passed a `SelectInst` and a `CmpInst`, neither of which is a `CallInst`. It is kept as defence in depth and is now commented as such. What IS distinguishing is that this TU also INSERTS into those vectors. |

**What ELSE is computed over the same closure:** `taint.Tainted` and
`taint.BirthOrder`, which the emitter also updates for the twin (mirroring
`RotationLowering`'s treatment of a freshly minted handle). `taint.HandleWidth`
is deliberately NOT written: it is keyed on a minted **alloc handle**, and the
twin is a chained rotation that mints none. Both of the two that ARE written were
**measured INERT** by the round-1 review (lens L5-4: dropping them gives 0 red
fixtures and 0 output diffs) and are kept as defence in depth, because
`BirthOrder.lookup` returns 0 for an absent key rather than failing — a future
birth-ordered reader would silently sort the twin first.

### (a2) `taint.DischargedFlagGates` gains a WRITER — the row §3 originally had none for

Added by the round-1 review (lens L5-9). 2b's step 5 inserts the `_unc` strip.

| reader | verdict |
|---|---|
| `ChainWalk.cpp:767` (`isInteriorConsumer` clause (c)) | membership test — the `_unc` strip is a pure READ of its slots ≥ 1, so a rail appearing there is not thereby a live forward consumer. |
| `ChainWalk.cpp:836` (`isInteriorTerminalHandle`) | membership test, same property. |
| `SwapRouteEmit.cpp:113` | scrubs the set. |

**And the JUSTIFICATION recorded at the write site was the wrong one** (lens
L1-2). The comment said "if S8 is ever widened, this recording must be
re-proved". The property the record buys is UNCONDITIONAL on the
`cq_template_<op>_<W>_hl_unc` symbol and has nothing to do with wires: the real
re-proof triggers are a change to what `_hl_unc` WRITES, or a SECOND minter of
that symbol with different effects. Corrected in source. Fenced by
`control_angle_select_ry_derived_cond.ll` (dropping the insert turns it red).

### (b) `taint.ControlledRotations` gains a **THIRD writer**

Writers: Inc-1's `emitInPlaceRotationRegion` (Ry arm), Inc-2a's `emitRegion`
(Rz arm), and now `emitAngleSelectRegion` (both stems). Readers:

| reader | verdict |
|---|---|
| `RotationLowering`'s theta loop | mints `cqrt_ry_<W>_controlled` — the intended path, unchanged. Its "classical arg-0 under control" loud bail is unreachable from 2b (S3 requires a tainted arg-0). |
| `RotationLowering`'s phi loop | mints `cqrt_rz_<W>_controlled` — the Inc-2a path, unchanged. Its `controlled phi operand` bail is likewise unreachable (S3). |
| `LoopLowering::isHoistedRegionArmGate` (:303-367) | narrowed to the `cq_phi` stem by the 2a round-1 review. **Unreachable for 2b: S7 declines every in-loop angle select**, so no 2b entry is ever in a loop body. Stated rather than assumed — the predicate exempts a gate from a fan-out count while `collectRailGates` would still COUNT it, which is the 8h7d.5 "two predicates over one closure" shape, and Inc 3 owns re-proving it. |

**It lives on `TaintSet`, and 2b is the increment where that is not hypothetical.**
`control_swap_reject_switch_datamux_angle.ll` is detected and emitted inside the
yn71 **onward-control fixpoint**, which builds a LOCAL `plan2`, emits it and
discards it, while `lowerRotations` is handed the FIRST plan. A plan-hosted map
would drop that entry and lower the gate **unconditionally** — a verify-clean
wrong unitary (Inc-1 finding G predicted this; here is a fixture that exercises
it).

### (c) `railWireClosure`'s exclusion parameter (`MergePhi` → `Exclude`)

The parameter's **contract** was never "a φ": it is "the ONE value the emitter
makes denote the post-gate register, whose users are therefore correct by
construction". Two callers, two spellings of that contract:

* `classifyArms` passes the region's merge φ (the emitter RAUWs it to the base);
* `classifyAngleSelect` passes the consuming rotation `T` (whose RESULT is the
  post-gate name — the emitter rewires `T`'s operands and leaves the call
  standing).

`T` is a chained-theta user of the base, so `forwardRailHop` admits it; without
the exclusion every legitimate post-gate consumer becomes a member's user and the
accept class collapses. **Three consumers are computed over this closure and all
three are affected identically by the rename — and by nothing else:** S8's
intersection, S9's member enumeration, and S9's skip set. Behaviour for regions
is unchanged (the Inc-1 call site still passes its merge φ); proved by the 55
`control_inplace_ry_*` fixtures and the whole-corpus sweep (§7).

### (d) `selReachesRotationArg1`'s decline set **NARROWS**

Nine sites say, in one wording or another, that an angle select "must keep
declining" or that "there is NO downstream backstop". Every one was re-read:

| site | verdict |
|---|---|
| `SelectClassify.cpp` gate-3 block | **FALSIFIED and rewritten.** The comment now states which single shape lowers, that everything else still lands on the unchanged decline, and why the `Declined` state exists (three refusals inside the accept class have their own precise strings that `rotation angle` would mislabel). |
| `ir-pass/test/control_swap_defer_select_angle.ll` header | **FALSIFIED — the fixture now ACCEPTS** and is rewritten in full (§5). |
| `ir-pass/test/control_swap_reject_switch_datamux_angle.ll` header | **FALSIFIED — now ACCEPTS**, rewritten in full (§5). |
| `TaintPropagation.cpp:459` (the arg-1 taint-edge exclusion) | **STILL TRUE and untouched.** It says an angle-derived value "must stay classical so it lowers as a rotation-angle CHOICE, not quantum data" — which is precisely what 2b does. The select itself IS tainted (it is a user of the tainted condition); the emitter erases it, and the angle slot ends up holding a `ConstantFP` or a classical `fsub`. |
| `CastLowering.cpp:119`, `OpcodeSupport.cpp:194/320`, `IntrinsicLowering.cpp:326/401`, `RotationLowering.cpp:79` (`declineTaintedAngle`) | **STILL TRUE.** They are about a TAINTED value in an angle slot. 2b never puts one there — S1 requires both select operands untainted, and the emitted difference is a classical `fsub` of two untainted values. `declineTaintedAngle` remains the backstop and remains un-fired on every accept fixture. |
| `SpecializeReject.cpp:165` | **STILL TRUE** (Phase-6 clone returns used as angles); untouched by this increment. |

### (e) The FREEZE — no new code, and it is PROBED, not argued

`ChainWalk::railCarriesControlledRotation` asks the question **structurally of
the emitted gate** (it derives the rail from the gate's own arg-1 USE), so it
applies to a 2b Ry with zero new code. Inc-1's round-1 review proved that a
recorded `Value *` would NOT — for a derived base (`p*5`) that value is an
instruction `lowerOps`, the very next stage, RAUWs and erases.

Measured on the finding-L shape (a mul-derived base with a late in-place use,
`control_angle_select_ry_derived_base_late_use_frozen.ll` and probe q12): **no
adjoint of the controlled Ry, no adjoint of the `mul`, no `cqrt_free` of the
register — exactly one free, the flag.** Strict stage 2b clean (2 rail mints, 2
left allocated, 1 free, 1 verified). The dead-register half is
`control_angle_select_ry_dead_base_frozen.ll`, same disposition.

**HOW FAR THE FREEZE REACHES, measured by the round-1 review (lens L3-3) and
worth knowing before reading a trace.** When the frozen register is a **QRAM
INDEX**, the freeze deletes the WHOLE 7.5 Shadow teardown — including adjoints on
registers the region never touches (the `h2` load index in that probe). That is
SOUND: everything it removes is a reversal, and not reversing leaves rails
ALLOCATED rather than dirty-freed (Rule 6's fallback). It is also IDENTICAL to the
manual twin on the oracle, so it is not a 2b behaviour. But "the freeze applies to
the rotated register" understates its blast radius, and a reader comparing a
QRAM trace before and after 2b will see far more missing than one controlled
rotation's adjoint.

### (f) `EmitInverse`'s controlled-rotation adjoint — an UNREACHABILITY claim, MEASURED

Inc-1 finding F's lesson: an unreachability claim is a measurement with named
checks, not a sentence.

* **Ry stem:** the register is FROZEN, so the whole-DAG spine never walks it into
  `D.Calls` and no adjoint is emitted. Checked by named assertions rather than by
  argument — both freeze fixtures carry `NOROUTE-NOT: double -3.000000e-01` and
  `NOROUTE-NOT: double 0xBFE3333333333334` (the negated-angle spellings the
  adjoint would use), and `..._derived_base_late_use_frozen.ll` ALSO carries
  `NOROUTE-NOT: cq_template_mul_i32_hl_unc`.
  **THAT LAST NEGATIVE IS ON ONE FIXTURE, NOT BOTH** (round-2 review, lens R2 N6 —
  the round-1 correction said "both … **and** `mul_unc`"): `ry_dead_base_frozen`
  has no `mul` at all, its base being a plain `cq_theta` result, so the assertion
  would be vacuous there and is deliberately absent. Harmless in effect, wrong as
  written, and corrected here rather than by adding a vacuous directive.
  **THAT SENTENCE WAS FALSE OF ONE OF THE TWO UNTIL THE ROUND-1 REVIEW FIXED IT**
  (lenses L6-N2 / L3-2): `..._derived_base_late_use_frozen.ll` carried
  `NOROUTE-NOT: double -6.000000e-01` — the negation of a number this lowering
  NEVER REALIZES (the difference is folded to `0x3FE3333333333334`, and 0.6 is not
  that). So the **half-reversal** mutation, which is exactly what a broken freeze
  produces because the unconditional twin IS an ordinary rotation the spine knows
  how to invert, stayed GREEN in that fixture while its sibling went red.
  Corrected to `-3.000000e-01`; verified against lens L3's `derived_mutA`.
* **Rz stem:** a `cqrt_rz_<W>_controlled` is not a DAG link at all (PRD §12.1
  Removal A), so it cannot be reached through `D.Calls`.
* The **twin** `cqrt_{ry,rz}_<W>` is an ordinary unconditional rotation and is
  handled by the existing spine exactly as any user rotation is — measured
  identical to the manual by-difference twin in all four C shapes (§6).

### (g) Instruments

* `tools/free_pairing_check.py` — **no new runtime symbol**, so `classify()` is
  untouched. Every accept fixture and every e2e slice runs it STRICT (no
  `--allow-unproven`).
* `tools/control_flag_order_check.py` — mint < gate < strip < free holds by
  construction (the emitter inserts the twin and the mint before `T`, the gate IS
  `T`, and the strip and free go after it). Run over the whole corpus in §7.
* `tools/golden_multiset_audit.py --all` — 2b **regenerates no golden**; it adds
  slices. Run in §7.
* `tools/loop_twin_matrix.py` — unchanged table (in-loop 2b declines). Run in §7.

### (h) M-A `warnLiveRecordRotations`

The new unconditional `ry(h, B)` on a register with a live derived record warns
exactly as the manual twin's does. Measured on q12: **two warnings from the 2b
form and two from the twin, same text, `opt` exit 0 in both** (it is a
`DS_Warning` since bd `lyyf`).

---

## 4. Findings made while building

### A. `control_swap_defer_select_angle.ll` and `control_swap_reject_switch_datamux_angle.ll` FLIP TO ACCEPT

Found by the whole-corpus disposition sweep, not by the fixture suite (both were
green throughout — they assert a decline that the increment legitimately
removes). Both are rewritten in full rather than edited, with headers that say
what changed and what did not.

The second one is the more interesting: its header claimed the shape was "a
Rule-3 f64/angle wrong unitary if lowered". **That was true of the lowering that
existed when it was written and is false of this one.** 2b never realizes the
angle as a number; it emits the controlled rotation the source describes, with
every angle in the stream classical (`%b` and a classical `fsub double %a, %b`).
Rule 3 forbids quantum data in the angle OPERAND, not a quantum CONTROL on the
rotation. The flag strip is valid because the only gate between mint and strip is
a diagonal controlled Rz on a DIFFERENT rail. Stage 2b clean.

### B. `LLVMContext::diagnose` EXITS on `DS_Error`

Only one diagnostic is ever printed per run, and no lowered IR is printed on a
decline. Consequences: (i) the FIRST guard to fire owns the message, which is why
gate 2c wins over S8 on the condition-register shapes; (ii) every
`CHECK-NOT: cqrt_*` in a decline fixture is **vacuous** — recorded here so nobody
quotes one as evidence that nothing was emitted; (iii) "every decline precedes
the first emitted instruction" is doubly important, since a half-emitted module
would never be visible.

### C. The Rz stem does NOT reverse a dead chain, and the twin that proves it is HAND IR

`control_angle_select_rz_dead_chain.ll` leaves the dead `mul` chain allocated.
PRD §12.1's "the Rz stem is transparent" invites the opposite expectation, so it
is worth stating what transparency means here: the emitted stream is
**byte-identical to the drbq Inc-2a in-place Rz DIAMOND over the same dead
chain** (measured against a hand-IR twin), and that is the claim. The wholly
UNCONTROLLED twin (no condition at all) DOES cancel its rotations, uncompute the
`mul` and free both rails — that difference is bd `wt3l`'s open cancel/leak/keep
question about a user Rz on a possibly-dead rail, which this increment does not
move in either direction.

The **C-source** manual by-difference twin of that shape declines for an
unrelated pre-existing reason: with the register dead, `clang -O1` leaves the
diamond with no merge φ and `recoverRegion` refuses it. So for this one shape the
select form ACCEPTS where the C twin DECLINES — a widening, in the direction the
2a diamond already sanctioned.

### D. The lazy `DominatorTree`/`LoopInfo` had to move

`detectControlRegions` built them on the first tainted **branch**. A function
with a tainted select and no tainted branch would have handed the angle hook a
null pair — a silent OVER-decline (`NotApplicable` ⇒ the pre-2b string), not a
miscompile, but one that would have made the accept depend on whether some OTHER
construct in the same function happened to build the tree. The trigger is now
"first tainted branch **or select**"; a function with neither still pays nothing.

### E. `ControlPlan.h` named a function that no longer exists — and the "never existed" framing was itself wrong

The `AnglePhi`/`AngleConsumers` comment said the orchestrator lowers those
consumers "via `reduceAngleDiamondPhi`". Corrected: both fields are populated by
**nothing**, and the pointer now goes to `AngleSelectEmit`, which implements the
by-difference idea for the `select` form.

**TWO CORRECTIONS FROM THE ROUND-1 REVIEW** (lenses L6-N4, L6-N5), because the
replacement text got two facts wrong of its own:

* "**`grep -rn` over the whole repo returns zero hits**" is FALSE — `.beads`'
  JSONL export carries hits — and, more importantly, **`reduceAngleDiamondPhi`
  WAS REAL SHIPPED CODE**, added in `f4c8684`/`b9b6a7a` and excised wholesale in
  `7cde677` along with the rest of the controlled-op generation. It was not
  "design vocabulary read as an implementation pointer"; it was a live pointer
  that the excision left dangling, which is a different and more ordinary
  failure. `ControlPlan.h:350` still named it in the PRESENT TENSE and is fixed.
* "**two reads exist**" is FALSE: there is **ONE** (`ArmClassify.cpp:1534`).
  `EqFoldArm` never reads `AnglePhi` at all. `ControlPlan.h:332-335` carried the
  same wrong count and is fixed.

### F. Detection and mint still derive the ABI width from TWO expressions — for Inc 1

Inc-1 notes §3d recorded this as latent. 2b asks the **mint's** expression
(`wd.abiWidthFor(suffixFromName(T, "cq_theta_"))`), which is why `suffixFromName`
is now exported. Inc-1's R4 still asks `abiWidthFromType(T->getType())`.
**Deliberately not unified:** changing R4's argument changes R4's accept set,
which is a Rule-13 change to Increment 1 and out of scope here. They agree for
every `CQ.h` suffix measured.

### G. (CORRECTED) The work-list insert POSITION is NOT load-bearing for the final IR

The emitter inserts the unconditional twin into `taint.ThetaCalls`/`PhiCalls`
immediately BEFORE the consumer, and the first draft of the comment said that
appending at the end "would mint an ill-typed `cqrt_*` call". **Mutation M15
measured otherwise: `Work.push_back(T0)` produces BYTE-IDENTICAL output on every
fixture, at i8, at f64 and at i32, `opt` exit 0.**

> **"BYTE-IDENTICAL ON EVERY FIXTURE" IS NOT TRUE OF THE `cq_phi` STEM** (round-1
> review, lens L5-2). On **13** Rz outputs the lazily-minted
> `declare void @cqrt_rz_i32` line MOVES; the `define` bodies are identical and
> FileCheck is green either way. The three widths named above (i8, f64, i32) are
> all THETA-stem cells, so the sentence was measured on a set that could not
> exhibit the difference. The CONCLUSION — the position is not load-bearing for
> the emitted stream — is unaffected; the WORDING was over-general.

The repair is accidental and comes from `lowerRotations` itself. Lowering the
consumer first DOES create `cqrt_ry_<W>_controlled(f, <T0, still i8/double>, θ)`
— a genuinely malformed instruction — but the next loop iteration lowers `T0`
and ends with `T0->replaceAllUsesWith(Handle)`, which rewrites that operand to
the i32 handle before the verifier ever runs. The emitted STREAM order is
unaffected either way, because each `cqrt_*` is inserted at its own rotation's
position, not in work-list order.

**The position is kept, for two reasons that are not "it would miscompile":**
appending creates a malformed instruction for the span of one loop iteration,
which an assertions-ON LLVM aborts on (this build is assertions-OFF, so the whole
difference is invisible here); and relying on a later RAUW to repair a mistyped
call is accidental correctness, which stops holding the moment a rotation is
lowered without that RAUW. Recorded — with the comments in `AngleSelectEmit.cpp`
and both width fixtures corrected — because an overstated justification is how a
real fence later gets deleted as redundant (the round-2 / 2a-round-1 pattern this
epic keeps producing).

### H. The MINT is protected from an in-place op on the condition rail BY ANOTHER SUBSYSTEM

This is §8 worry 1, probed rather than left as a worry, and the answer is the
uncomfortable kind: **right for a reason that lives in a different file.**

The hazard: this emitter mints its flag AT THE CONSUMER, so anything between the
source's compare and the consumer is inside the flag's staleness window. S6
scans that window for `cq_theta` only — it is deliberately wire-blind and
rotation-shaped. A NON-rotation in-place op on the condition's own rail (an M-C
`cqrt_addc_<W>` / `cqrt_xorc_<W>`) would relabel the condition register between
the source's compare and our mint, so the minted flag would encode
`(q+1) == 5` where the source means `q == 5` — a verify-clean wrong predicate,
and the Rz stem is exempt from S8 so nothing later would catch it.

**MEASURED on four plain-C reproducers, all correct** (`q = q + 1;`, `q ^= 3;`, a
value-arm region `if (p==3) q = q+1;`, and a rotation-arm region on `q`): the
arithmetic is lowered OUT of place every time, onto a FRESH
`cq_template_{add,xor}_i32_hl` rail, leaving the condition register untouched and
the mint reading exactly what the source read.

**WHY, and this is the part to carry:** `lowerOps` (where M-C decides in-place vs
out-of-place) runs AFTER `lowerControlRegions`, so by then OUR MINT AND STRIP ARE
ALREADY IN THE IR as later reads of the condition register — and M-C's G6/G7 pair
refuses the in-place conversion whenever a later read exists. The protection is
therefore a consequence of pipeline ORDER plus another subsystem's fence, not of
anything in S1–S10.

**The reason is STRONGER than "our mint and strip are later reads", and the
stronger form is what makes it hold for a DERIVED or ALIASED condition register**
(round-1 review, lens L1-3): `lowerRotations` runs BEFORE `lowerOps` and RAUWs
EVERY SSA alias of a rail onto ONE alloc handle, so by the time M-C walks
`P->users()` it sees our mint and strip on the handle regardless of which alias
the source named. Probed on three alias spellings (`p_b1`/`p_b2`/`p_b3`), all
lowered out of place, all correct.

**The obligation that creates, in TWO parts — the second was missing:** if M-C's
later-read test ever narrows — if it stops counting a `cq_template_icmp_*_hl` as a
read — S6 becomes the only fence and it cannot see a non-rotation in-place op.
**And the protection is equally lost if in-place conversion ever moves BEFORE
`lowerRotations`**, because then M-C would be walking pre-RAUW aliases and would
not see our mint at all. Widening S6 to the rail (asking S8's question of the
condition side for BOTH stems) is the fix for either, and it is a Rule-13
change.

### I. BLOCK LIFETIME — an `AngleSelectRegion` is inert to the pre-flight, and that is safe only because every OTHER region's arm is PURE

`AngleSelectRegion` leaves every block field null, so `lowerControlRegions`'
cross-region pre-flight treats it as inert (the `if (!Doomed) continue;` guard) —
exactly like `SelectRegion`. It therefore contributes no ordering constraint and
receives none. The question that raises, and that the bd `hcrg` history says must
be asked out loud: **can another region's flatten ERASE the block my select lives
in, before my emitter reads it?**

`flattenRegion` erases `{Arm, ArmFalse, MergeBB}` and SPLICES the merge's
surviving instructions into `Pred`. So:

* a select in a `Pred` — never erased;
* a select in a `MergeBB` — spliced into `Pred`, survives as an instruction (my
  emitter reads `Sel->getParent()` at emit time, which is live);
* **a select in an ARM — would be freed.** Plan order puts the region first (the
  terminator dispatch of `Pred` precedes the instruction scan of `Arm`, and
  blocks are visited in function order), so the arm's erase would happen BEFORE
  my emitter runs, and my "re-validate by SSA identity" would be reading freed
  memory rather than validating.

**Measured: unreachable at HEAD, and every one of the five reasons lives in a
different file.** Every region kind that erases an `Arm` requires arm-block
purity that a `select` cannot satisfy — `armBlockIsPureSpine` (phase),
`valueArmIsPureChain` (value), `inPlaceRotationArmTheta` ("NOTHING ELSE in the
arm block", drbq Inc 1), `classifyClassicalCallArm`'s
`Region.Arm->size() != 2 || &Region.Arm->front() != Call` (6.5), the
`GuardedStoreArm` gep-chain-plus-one-store shape, and `AbortPark`'s
sink-plus-`unreachable`. Probed with a hand-IR diamond whose arm holds a pure
classical call AND a tainted angle select AND its consumer: **declines
`control flow` — which means `opt` exits 1, NOT 0** (round-1 review, lens L6-N8:
the sentence as written contradicted §4-B two pages earlier, whose whole point is
that `DS_Error` calls `exit(1)`). **It is CLEAN under `libgmalloc`**, which is the
half that matters here: the decline happens before any block is freed.

**The obligation:** any future region kind that erases a block whose contents it
does NOT constrain to a fixed shape must either extend `lowerControlRegions`'
pre-flight to `AngleSelectRegion` (giving it a `Pred`-equivalent to protect) or
prove the same purity. This is the bd `hcrg` lesson from the other direction —
there the block-lifetime hazard was used to decline a shape that was actually
fine; here the shape is declined by six unrelated purity checks and nothing in
this increment.

---

## 5. Fixtures

**46 new** (`ir-pass/test/control_angle_select_*.ll`): **15 accept**, **31
decline**. Plus **2 rewritten** (the flips in §4-A). **Corpus 1361 → 1407** — the
base at `cb04d17` was **1361**, not 1358, so the first draft's "1358 → 1407"
credited +49 for +46 (round-1 review, lens L6-N9); `lit ir-pass/test` reports 1406
passed + 1 expectedly failed.

**Then the two Rule-13 review rounds added 20 more, and the split was MEASURED,
not estimated** (round-2 review, lens R2 N3 — the round-1 draft wrote "16 more (3
accept / 13 decline)" in this paragraph and in `CLAUDE.md`, and both were wrong):

| batch | files | accept | decline | corpus after |
|---|---|---|---|---|
| implementation hand-back | 46 | 15 | 31 | 1407 |
| round-1 Rule-13 review | +16 | **+2** | **+14** | 1423 |
| round-2 Rule-13 review | +4 | **+2** | **+2** | 1427 |
| Rule-13 CLEARANCE review (F-11, option (2)) | **+3 −1** | **−1** | **+3** | **1430** |
| **family total** | **68** | **18** | **50** | |

The round-1 accepts are `accept_rounding_flagship_bound` and
`accept_exact_difference_large`; the round-2 ones are `accept_rounding_at_bound`
and `forward_rail_cycle_frozen`. The clearance row is the constant-arms-only
narrowing: `control_angle_select_ry_arg_angles.ll` (accept) was **replaced** by
`control_angle_select_reject_runtime_arms.ll` (decline), joined by
`reject_runtime_arms_rz.ll` and `reject_runtime_one_arm.ll`; a fourth new decline,
`control_swap_reject_switch_datamux_angle_runtime.ll`, sits OUTSIDE the
`control_angle_select_*` name and so counts in the corpus (+3 net = 1430) but not
in the family total. Re-measure rather than trust:
`ls ir-pass/test/control_angle_select_*.ll | wc -l` = 68,
`grep -L 'RUN: not' … | wc -l` = 18, `ls ir-pass/test/*.ll | wc -l` = 1430.

**Every accept fixture is RED on the pre-2b oracle** (all 18 decline
`rotation angle under quantum control` there), which is the Rule-12 red-green
evidence; the two rewritten ones likewise. The four clearance DECLINE fixtures are
the other direction — they are red-green against the PREVIOUS state of THIS tree
(all four accepted before the narrowing, measured), and their diagnostic on the
pre-2b oracle is byte-identical to the one they produce now.

### Accept (15 at hand-back; 19 on disk — the four added by the two review rounds are listed under §9 and §10)

| fixture | what it pins |
|---|---|
| `ry_diamond` | the flagship stream as a `CHECK-NEXT` adjacency chain, with the folded difference pinned as BITS |
| `ry_ne_swapped` | `!=` arrives as `icmp eq` + swapped select operands; NO `cqrt_x`, negative difference |
| `ry_sgt` | a non-equality predicate — the mint carries no equality assumption |
| `rz_diamond` | the `cq_phi` stem |
| `rz_cond_register` | **the stem separator** — Rz on the condition's own register accepts |
| `ry_f64_fcmp` | width + the work-list ORDER pin (an `fcmp` condition, an f64 register) |
| `ry_i8` | the order pin at a sub-i32 width |
| ~~`ry_arg_angles`~~ | a real classical `fsub` in the angle slot — **REMOVED** by the clearance narrowing (run-time arms decline); replaced by `control_angle_select_reject_runtime_arms.ll` |
| `ry_derived_cond` | `q>5 && q<100` as `-O1` folds it: one compare on a derived rail, uncomputed and freed after the strip |
| `ry_derived_base_late_use_frozen` | **the freeze**, finding-L shape |
| `ry_dead_base_frozen` | the freeze with no live consumer — leaked, not freed |
| `ry_then_region` | composition with an Inc-1 diamond: reversed EMISSION order, source-order STREAM |
| `rz_dead_chain` | §4-C |
| `ry_lifted_phi_base` | the lifted one-register φ as the BASE — finding K's accept control |
| `ry_alias_pre_gate` | a diagonal alias READ BEFORE the gate |

### Decline — 31 at hand-back, **47 on disk**, ALL OF THEM NAMED

The round-1 heading said 28 where the §2 table already implied 31 (lens L6-N9);
the round-1 fix corrected the number but left the LIST at 31 names, so a reader
diffing it against disk found 16 missing (round-2 review, lens R2 N4). The list
below is the complete **50**, grouped by the batch that added it — re-derive with
`grep -l 'RUN: not' ir-pass/test/control_angle_select_*.ll`. (It was 47 until the
CLEARANCE review's constant-arms-only narrowing added three; a FOURTH new decline,
`control_swap_reject_switch_datamux_angle_runtime.ll`, is outside this name
prefix and so is not in this list — §11.)

**At hand-back (31):**
`tainted_arm` · `tainted_both_arms` · `state_prep` · `two_consumers` ·
`two_phi_consumers` · `second_select_same_cmp` · `nested_select` · `qq_compare` ·
`compound_cond` · `cond_register` · `cond_alias` · `inplace_alias_base` ·
`stale_measure` · `stale_ret` · `stale_diag_alias_forward` ·
`stale_diag_alias_backward` · `stale_diag_alias_two_hop` ·
`stale_chained_theta` · `record_read_on_side_path` · `lifted_phi_measure` ·
`lifted_phi_ret` · `lifted_phi_tape` · `lifted_phi_clone_arg` ·
`lifted_phi_invert` · `in_loop` · `in_loop_rz` · `cross_block_consumer` ·
`theta_between` · `raw_i1_cond` · `cmp_shared_with_region` · `cmp_data_use`.

**Added by the round-1 Rule-13 review (14)** — the S7 widening, the arm-value
fence, the rounding fence, the step-0b re-ask, and one coverage fixture:
`irreducible_cycle` · `irreducible_cycle_rz` · `loop_rail_exit_block` ·
`loop_rail_exit_block_rz` · `undef_arm` · `poison_arm` ·
`undef_constexpr_arm` · `inf_arm` · `nan_arm` · `overflow_difference` ·
`rounding_pi_1e16` · `rounding_one_1e300` · `datamux_qq_after_rauw` ·
`theta_before_select`.

**Added by the round-2 Rule-13 review (2)** — the link-time-constant arm clause
and the threshold's upper boundary:
`constexpr_arm` · `rounding_above_bound`.

**Added by the Rule-13 CLEARANCE review (3)** — clause (2c), the constant-arms-only
narrowing (blocker F-11, owner option (2); §11). The first REPLACES the deleted
accept fixture `ry_arg_angles`, which asserted the accepted run-time-arm stream
line for line:
`reject_runtime_arms` · `reject_runtime_arms_rz` · `reject_runtime_one_arm`.
Their sibling outside this prefix is
`control_swap_reject_switch_datamux_angle_runtime.ll`, the yn71 onward-fixpoint
cell with run-time arms — the constant-arm spelling of that same module stays an
ACCEPT (`control_swap_reject_switch_datamux_angle.ll`, arms changed to 0.9/0.3).

**Three of those (`two_phi_consumers`, `cmp_data_use`,
`record_read_on_side_path`) exist BECAUSE of the mutation table below** — their
clauses had no red fixture until they were written, and one of them
(`record_read_on_side_path`) is an over-decline kept on purpose.

### Shapes that are NOT fixturable, recorded rather than faked

* **`controlled rotation width`** — S5's refusal needs a `cq_theta_<sfx>` whose
  ABI width `abiWidthFromType` recognizes but `abiWidthHasControlledRotation`
  does not. No such `CQ.h` suffix exists, and a hand-written
  `declare i128 @cq_theta_i128` is refused earlier by the collection-time
  prototype validation (`cq taint escape: tainted value consumed by an unknown
  callee`). Same conclusion as **Inc-1 finding E**, for the same reason.
* **a `select float` in a `double` angle slot** — ill-typed; the reachable form
  is `select float … ; fpext … ; cq_theta(…)`, which is exactly the existing
  `control_swap_reject_select_angle_cast.ll` (verified unchanged by the sweep,
  §7). No duplicate written.
* the existing `control_swap_reject_select_fp_angle_fanout.ll`,
  `..._select_dualuse.ll`, `..._select_freeze.ll`, `..._freeze_phi_angle.ll` all
  keep their exact dispositions and strings (sweep, §7) — they are the carrier /
  fan-out arm of the decline partition and needed no new siblings.

---

## 5b. The MUTATION TABLE (Rule 12 — a clause with no red fixture is unfenced)

Each S-clause was stubbed out in turn, the plugin AND `cq-opt` rebuilt (never
`--target CQPass` alone), and the whole `control_angle_select|defer_select_angle|
switch_datamux_angle|control_inplace_ry` family re-run. **17 mutations.**

| # | clause stubbed | fixtures that turn RED |
|---|---|---|
| M1 | S1 `Sel->getType()->isDoubleTy()` | **none — see below** |
| M2 | S1 both operands untainted | `reject_tainted_arm`, `reject_tainted_both_arms` |
| M3 | S2 `Sel->hasOneUse()` | `reject_two_phi_consumers` |
| M4 | S3 arg-0 tainted | `reject_state_prep` |
| M5 | S4 `Tree.Nodes.empty()` | **none — see below** |
| M6 | S4 `Cond->hasOneUse()` | `reject_cmp_data_use` |
| M7 | S4 exactly one tainted compare operand | `reject_qq_compare` |
| M8 | S5 `abiWidthHasControlledRotation` | **none — unfixturable, see below** |
| M9 | S7 the loop clause | `reject_in_loop`, `reject_in_loop_rz` |
| M10 | S6 `comesBefore` ordering | **none — see below** |
| M11 | S6 the positional theta scan | `reject_theta_between` |
| M12 | S8 the R4 intersection | `reject_inplace_alias_base` |
| M13 | S9 the R6 user scan | **11** — `reject_stale_{measure,ret,chained_theta}`, `..._stale_diag_alias_{forward,backward,two_hop}`, `..._lifted_phi_{measure,ret,tape,clone_arg,invert}` |
| M14 | S10 "already claimed" | **none — see below** |
| M15 | emitter: the work-list insert POSITION | **none — measured, see §4-G** |
| M16 | S9's SKIP SET (member obligation applied to every user) | `reject_record_read_on_side_path` |
| M17 | the `Exclude = T` forward exclusion | **11 ACCEPT fixtures AT HAND-BACK** — 11 of the **12** `ry_*` ones then on disk, not "every" (round-1 review, lenses L5-7 / L6-N9: `ry_dead_base_frozen` stays green because its register is DEAD, so the exclusion has no post-gate consumer to protect — the mutation is vacuous there). **THE NUMBER IS AS-MEASURED-AT-HAND-BACK AND HAS NOT BEEN RE-MEASURED SINCE** (round-2 review, lens R2 N7): the two review rounds added four accept fixtures — `accept_rounding_flagship_bound`, `accept_exact_difference_large` (round 1) and `accept_rounding_at_bound`, `forward_rail_cycle_frozen` (round 2) — and the first three are Ry-stem accepts with a live post-gate consumer, i.e. exactly the shape this mutation should redden. Re-measuring needs a rebuild with the clause stubbed, which neither review round did. Read the cell as "11 of the 12 that existed when it was measured", never as a current count of the corpus it names. |

**M3, M6 and M16 had no red fixture on the first pass; three fixtures were
written because of that** (`reject_two_phi_consumers`, `reject_cmp_data_use`,
`reject_record_read_on_side_path`). M3's original candidate
(`reject_two_consumers`) stays green under the mutation because its two consumers
are a `cq_theta` and a `cq_phi`, so S6's positional scan sees the theta in the
window and declines anyway — the sibling with TWO `cq_phi` consumers is the one
that isolates the clause.

**The five clauses with NO red fixture, each with its measured reason** (Inc-1
finding C / finding E house style — a redundant clause is kept as defence in
depth, and the alternative to a redundant check is a silent fall-through):

* **M1** — `isDoubleTy` is IMPLIED by S2. `T->getArgOperand(1) == Sel` forces the
  select's type to be the callee's arg-1 type, and every `cq_*` rotation
  prototype takes a `double` angle. MEASURED rather than argued: a hand-written
  `declare i32 @cq_theta_si32(i32, float)` is refused earlier by the
  collection-time prototype validation
  (`cq rotation lowering: unsupported declared prototype for cq_theta_si32`).
* **M5** — `Tree.Nodes.empty()` is implied by `Cond != Sel->getCondition()`: with
  a tree, the select's condition IS the node and `Tree.Leaves.front()` is a leaf,
  so they differ. `Leaves.size() != 1` covers a multi-leaf tree; a one-leaf tree
  with a node is refused by `collectCondTree`'s self-operand fence.
* **M8** — no `CQ.h` suffix has an ABI width that `abiWidthFromType` recognizes
  and `abiWidthHasControlledRotation` refuses. Hand IR cannot reach it either.
  **The MECHANISM stated here was wrong** (round-1 review, lens L6-N7): a
  `declare i128 @cq_theta_i128` is not "declined by `declineTaintEscapes`" — an
  UNRECOGNIZED rotation suffix is a SILENT PASSTHROUGH (the collection walk simply
  does not classify it as a rotation, so nothing is tainted and nothing is
  lowered), which is a different disposition from a loud decline and would have
  read very differently to anyone probing it. The CONCLUSION — the clause is
  unfixturable — is unchanged. **Same conclusion as Inc-1 finding E, for the same
  reason.**
* **M10** — `comesBefore` is implied by SSA def-before-use inside one block: the
  select uses the compare and the consumer uses the select.
* **M14** — S10 is unreachable. `R.Merge == Sel` needs a second region on the
  same select (`classifySelectRegion` visits each select once and returns after
  the hook); `R.Condition == Cond` and a recorded `ControlledRotations[T]` both
  need another region that already claimed the compare or the gate, which S4's
  `Cond->hasOneUse()` and the arm-block purity checks forbid.

---

## 6. The e2e goldens, argued line by line

Seven new slices, ten new ctest entries (7 slices + 3 `compare_files` twin
gates). ALL STRICT stage 2b — no `--allow-unproven`.

### `slice_control_angle_select_ry.expected.log` (11 lines)

```
cqrt_alloc_i32(3) -> h0                                  ; q's rail
cqrt_ry_i32(h0, 0x1p-1)                                  ; q = cq_theta(3, .5)
cqrt_alloc_i32(7) -> h1                                  ; r's rail — DISJOINT
cqrt_ry_i32(h1, 0x1p-2)                                  ; r = cq_theta(7, .25)
cqrt_ry_i32(h1, 0x1.3333333333333p-2)                    ; THE TWIN: R(r, B=0.3)
cq_template_icmp_eq_i32_hl(h0, 5) -> h2                  ; flag mint, on q
cqrt_ry_i32_controlled(h2, h1, 0x1.3333333333334p-1)     ; R_c(f, r, fl(0.9-0.3)) != fl(0.6)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)                ; strip — reads q, unmoved
cqrt_free(h2)                                            ; the flag, provably |0>
cqrt_measure_i32(h0) -> 0
cqrt_measure_i32(h1) -> 0
```

(The annotation on line 7 used to read `A-B=0.6`, three lines above the paragraph
that retracts exactly that spelling — round-2 review, lens R2 N10. The emitted
constant is `0x1.3333333333334p-1 = fl(0.9 - 0.3)`, and `fl(0.6)` is
`0x1.3333333333333p-1`, one ulp BELOW it. The inline annotation is the copy a
skimming reader takes, so it now carries the inequality rather than the number it
is not.)

Line by line: two independent `cq_theta` sources give two rails, so the Ry on
`h1` cannot move `h0`'s basis and the strip on line 8 recomputes exactly the
predicate line 6 minted (S8). The twin on line 5 fires UNCONDITIONALLY at the
FALSE-arm angle; the controlled gate on line 7 adds the difference, so `f=0`
leaves `Ry(0.3)` and `f=1` composes to `Ry(0.9)`. `0x1.3333333333333p-2` is 0.3
and `0x1.3333333333334p-1` is the folded `0.9 - 0.3`; note they are NOT the same
mantissa. **THE REASON GIVEN HERE WAS FALSE** (round-1 review, lens L7-F4):
"0.6 is not 2×0.3 in binary64" is wrong — `2 × fl(0.3) == fl(0.6)` bit for bit,
because doubling is exact. The TRUE fact is
**`fl(fl(0.9) − fl(0.3)) ≠ fl(0.6)`**: the folded difference is
`0x1.3333333333334p-1` while `fl(0.6)` is `0x1.3333333333333p-1`, one ulp apart.
That is the SAME fact as the rounding finding (§9 item 3) seen from the golden's
side — the realized true-arm angle is `fl(0.3) + fl(fl(0.9) − fl(0.3))`, which
misses `fl(0.9)` by `2^-54` rad. Exactly ONE `cqrt_free` (the flag). Both registers are
left allocated: `h0` and `h1` are MEASURED, so `FreePoint` gives them to the
measurement.

### `..._ry_ne.expected.log`

Identical shape with two changes and no others: the twin fires at
`0x1.ccccccccccccdp-1` (0.9, the `q != 5` arm's own angle, because `clang`
canonicalized the test to `icmp eq` and swapped the select's arms), and the
controlled angle is `-0x1.3333333333334p-1` (0.3 − 0.9). **There is no
`cqrt_x` anywhere** — the `br`-diamond paths need a bracket for a
false-successor arm; a select has no polarity case at all.

### `..._rz.expected.log`

Line 5 becomes `cqrt_rz_i32` and line 7 `cqrt_rz_i32_controlled`; nothing else
differs, including the two folded constants. That is the whole content of "both
stems": the by-difference identity is the same because `Rz = diag(1, e^{iθ})`
composes entrywise.

### `..._ry_derived_base.expected.log` (13 lines)

Adds `cq_template_mul_i32_hl(h1, 5) -> h2` (the derived rail) before the twin,
and `cqrt_addc_i32(h2, 1)` (the post-gate in-place use) after the free. **The
FREEZE is the negative space:** no `cq_template_mul_i32_hl_unc`, no negated-angle
`cqrt_ry_i32`, and NO `cqrt_free(h2)` — one free in the whole trace, the flag's.
The rail is left allocated (Rule 6). Two `DS_Warning` M-A `live derived record`
warnings accompany it and `opt` exits 0.

### The three twin gates

`e2e-angle-select-{ry,ry-ne,rz}-twin-identical` are `cmp` over committed
goldens — no clang, no opt, no plugin, milliseconds. **All three pass, and the
twin goldens were additionally verified byte-identical when produced by the
PRE-2b binary**, which is what makes the twin an oracle rather than a second copy
of the subject. The `derived_base` slice has no ctest twin gate; its manual
by-difference twin was compared BY HAND and is byte-identical, warnings included.

---

## 7. What was RUN — counts, and only what was executed

> **THESE ARE THE IMPLEMENTER'S HAND-BACK FIGURES (2026-09-03, pre-review) and several
> are now STALE by construction — the round-1 Rule-13 review added 16 fixtures and two
> accept-predicate clauses, the round-2 one +4, and the clearance one +3 net. Do not
> quote a number from this table as current; §11's table is the newest.** In
> particular **`1407` is now `1430`** everywhere it appears below (the round-1 draft
> of this line said 1423, which was already stale by one round when written and by
> two when the clearance review re-measured it — non-blocking observation 6). The
> ITEMIZED SWEEP below is likewise a hand-back partition: it reads 17/15/16/3, the
> clearance review measured **21/20/27/3** on the pre-clearance corpus, and after
> the clearance narrowing it is **20/20/31/3**, RE-MEASURED over the full 1430 x 2
> sweep rather than derived: 20 fixtures flip DECLINE->ACCEPT (the 18 remaining
> `control_angle_select_*` accepts plus `control_swap_defer_select_angle` and
> `control_swap_reject_switch_datamux_angle`, which is STILL an accept, now with
> constant arms), 20 keep rc=1 on both with a SHARPENED message, 31 declines do not
> move at all (the previous 27 plus the three new `reject_runtime_*` files and
> `datamux_angle_runtime`), and 3 are the pre-existing `ogw2` eq-fold cells. Over
> the rest of the corpus: 704 both-decline with an IDENTICAL message, 683
> both-accept, **0 unexplained movers.** The twin matrix and golden audit were
> re-run: the golden audit unchanged, the matrix's 16 `angle=args` cells
> reclassified and its other 142 line-for-line identical.

| layer | result |
|---|---|
| `ir-pass-lit` (whole entry) | **1407 fixtures: 1406 passed, 1 expectedly failed** (the standing `lowering_invert_add_i32.ll` XFAIL) |
| `ctest -j6 -R '^e2e-'` | **295/295** (258 s) |
| `ctest -R runtime` | **7/7** |
| `ctest -R frontend-lit` | **1/1** |
| `cmake --build build --target cq-opt-equivalence-full` | **1407 fixtures, 0 mismatches** |
| `tools/control_flag_order_check.py` | 1407 files, **391 control flags, 0 violations** |
| `tools/free_pairing_check_test.py` | 26 fixtures, 69 named + 313 proof-targeted mutants, **0 failures** |
| `tools/golden_multiset_audit.py --all` | **280 goldens: 7 NEW-FILE (mine), 273 UNCHANGED**, 0 routes collapsed — no existing golden moved |
| `e2e-loop-twin-matrix` | **PASS** (160 s) — the 156-cell table is unchanged (in-loop 2b declines) |
| `tools/angle_select_twin_matrix.py --jobs 8 --oracle <pre-2b>` | **158 cells / 632 pipelines**: 116 BOTH-ACCEPT-IDENTICAL, 12 BOTH-DECLINE, 16 DEGENERATE-FOLD, 1 OVER-DECLINE, 13 SUSPICIOUS (all ONE annotated class), **0 MISMATCH / 0 ORACLE-MOVED / 0 RED-GREEN-MISS / 0 HARNESS-ERROR / 0 stage-2b failures** |
| whole-corpus disposition sweep vs the pre-2b oracle | **1407 fixtures, 35 moved** — every one accounted for (below) |
| mutation matrix | **17 mutations**, table in §5b |

**NOT run by this agent:** the full `ctest -j6` (the orchestrator owns it as
committer, Rule 19 moment 1/2/5). Everything above was executed and the numbers
are transcribed from the runs, not estimated.

### The disposition sweep, itemized

* **17 fixtures flipped DECLINE → ACCEPT**: the 15 new `control_angle_select_*`
  accepts (the Rule-12 red-green evidence, all of them `rotation angle` on the
  oracle) plus the two rewritten flips (§4-A).
* **15 fixtures kept rc=1 on both binaries but SHARPENED their message**: the new
  decline fixtures whose clause has its own string (`in_loop`, `in_loop_rz`,
  `inplace_alias_base`, the seven stale-record ones, the five lifted-phi ones).
  Oracle said `rotation angle`; the new build says the precise clause. That is
  itself red-green evidence for the three strings.
* **16 fixtures did not move at all**: every decline whose clause returns
  `NotApplicable`. Their diagnostic is byte-identical before and after — which is
  the claim "no existing decline churns", measured.
* **3 PRE-EXISTING and unrelated**:
  `control_swap_reject_eqfold_wrong_edge_{eq,ne,ifelse}.ll` accept on the oracle
  and decline here. The oracle was built from `24bb42d` and **lacks the bd `ogw2`
  eq-fold D8 polarity clause** that landed in `cb04d17`. Nothing to do with 2b.

---

## 8. What worries me

This epic's history is the reason this section is long: Increment 1 shipped
**three confirmed defects through a fully green suite**, two of them silent
miscompiles, and **every one was a CROSSED-AXIS shape**. Increment 2a's round was
clean and produced six falsified justifications instead. Assume this one hides
something and look here first.

1. **S6's positional scan is WIRE-BLIND, and nothing in S1–S10 is what makes
   that safe** — finding H. A non-rotation in-place op on the condition's rail
   between the compare and the consumer would mint a wrong predicate, the Rz stem
   is exempt from S8, and S6 only looks for `cq_theta`. It is CORRECT on all four
   reproducers I could build, **because `lowerOps` runs after this emitter and
   M-C refuses an in-place conversion when a later read exists — and our own mint
   and strip ARE later reads.** That is a dependency on pipeline order and
   another subsystem's fence. It held everywhere I probed; it is not something
   this increment proves.
2. **~~The Rz stem is exempt from S9 (stale records) with no fixture that could
   catch a mistake in that exemption.~~ DISCHARGED by the round-1 review.** The
   worry was that 2b's Rz gate is preceded by an UNCONDITIONAL `rz(h, B)` that
   2a's is not, and that the §12.1 exemption had not been re-derived in the
   presence of that extra gate. Two lenses did it: L1 §5f re-derived it
   analytically (the extra gate is DIAGONAL, so it commutes with every
   computational-basis projector and moves no label — the exemption's premise is
   about the gate class, and adding another gate of the same class cannot
   weaken it), and L2 measured it on FIVE shapes. Nothing to do.
3. **`use=none` is the one axis where the select form ACCEPTS and the manual twin
   DECLINES**, 13 cells of the matrix. **BOTH HALVES OF THAT WERE OFF** (round-1
   review, lens L3-4): in HAND IR with the merge phi kept, ALL 16 `use=none` cells
   are IDENTICAL — the twin's decline is a property of what `clang -O1` does to a
   DEAD register (no merge phi, so `recoverRegion` refuses), not of the shape. The
   genuinely twin-less hole is elsewhere: it is the **16 `_tape` cells**, whose
   diamond twin declines `tainted argument has continued lineage`. Say "16 of 120
   tape cells have no twin oracle". The twin declines for a structural reason
   (a dead register leaves no merge phi), and the hand-IR 2a diamond that DOES
   keep the phi emits the identical stream — so the identity holds where it can
   be posed. But it means the increment's headline witness has a hole exactly
   where the register is dead, which is also where the FREEZE matters most. The
   lit fixtures `ry_dead_base_frozen` and `rz_dead_chain` are what stand there
   instead.
4. **The `a_phi_eq_src_region2_consts` OVER-DECLINE is an interaction I did not
   fix and only partly understand.** An angle select whose consumer is the
   DERIVED BASE of a FOLLOWING phase region declines the whole module, because
   `taintedAngleGate` inspects the pre-region base `cq_phi`'s own angle at
   detection time and finds the still-present select there. The `cq_theta` twin
   of the same composition ACCEPTS (its second region is an in-place rotation arm
   whose R2 looks at the ARM's gate, not the base). That asymmetry is a scope
   fact today; widening it means touching `taintedAngleGate`, which is a Rule-13
   change I deliberately did not make.
5. **`ControlPlan`'s `Kind` enum is now read by TWO generations of vocabulary.**
   I rewrote `AngleSelectRegion`'s comment and corrected the
   `AnglePhi`/`AngleConsumers` one (which named a function that has never existed
   in this generation). The FIELDS are still there, still populated by nothing,
   and `ArmClassify`'s in-place R7 clause and `EqFoldArm` still read them as
   defence in depth. A future increment that populates them will have two
   different "angle" designs in one struct.
6. **The `select@old` red-green axis proves the SHAPE is new; it does not prove
   the shape was UNREACHABLE before.** Every accept fixture declined on the
   pre-2b binary, which is the Rule-12 obligation — but a shape that used to
   decline can still compose with something that used to accept, and the
   composition set is what §4-A's two flipped fixtures came out of. The
   whole-corpus sweep is the only instrument that found those; it should be run
   again after any widening.
7. **The block-lifetime protection is entirely other people's** — finding I. An
   `AngleSelectRegion` is inert to the cross-region pre-flight, and a select
   sitting in another region's ARM block would be freed before my emitter reads
   it. It cannot happen at HEAD because six unrelated arm-purity checks each
   refuse a select in an arm. Nothing in S1–S10 asks the question.
8. **Two clauses are shadowed rather than independent, and I only noticed by
   mutation.** S2's `hasOneUse` is shadowed by S6 for the mixed-stem consumer
   pair, and S4's `Cond->hasOneUse()` is shadowed by the ziov guard whenever a
   `br` region shares the compare. Both now have isolating fixtures, but the
   general lesson is that this ladder has more overlap than its clause list
   suggests, and a clause deleted as "redundant" may be the only one covering
   some third shape.


---

## 9. Round-1 Rule-13 review (2026-09-03) — 7 lenses, 4 accepted findings

> **READ §10 WITH THIS SECTION.** A SECOND Rule-13 round reviewed these FIXES and
> graded one **CONFIRMED-MISCOMPILE** against them — the arm-value/rounding fence
> below is `ConstantFP`-gated, so with RUN-TIME arms both residual classes stay
> reachable from plain C, including a controlled angle of `inf` from two FINITE
> arms. It is recorded verbatim as graded, with its disposition
> (runtime arms STAY ACCEPTED; the residual is documented in full), in **§10**.
> Every "runtime arms carry the bound" sentence in this section has been corrected
> to state BOTH halves. The OWNER-DESK item below is now the **three-way** form.


Seven independent read-only lenses ran against the built binary and a PRE-2b
ORACLE (`24bb42d` = HEAD, Inc 1 + 2a, without 2b), each with its own axis. What
they executed, from their own reports: **L1** 212 hand-IR probes ×2 + 13 C ×2 +
a whole-corpus strip check over 700/686 lowered fixtures; **L2** 50 probes ×2 +
a 1407×2 disposition sweep; **L3** 181 subjects ×2 + a 120-cell twin set + strict
stage-2b on 161 accepts; **L4** 187 probes (148 C / 39 `.ll`) ×2 + a 96-cell
composition matrix + a `libgmalloc` pass; **L5** 43 probes ×2 + an 18-width grid +
3 mutant rebuilds; **L6** 302 fixture mutations / ~2900 `opt` runs + e2e 295/295;
**L7** 26 C ×2 + 63 hand-IR ×2 + the twin matrix reproduced + 25 fp pairs measured
in an independent C program. **0 CRASH and 0 nondeterminism anywhere.**

**FOUR findings were accepted and fixed. None is a shipped wrong unitary on an
accepted input at HEAD — but two of the four (1 and 3) turned a shipped LOUD
DECLINE into silence, which is the same failure with a different symptom, and
finding 3 in particular was ranked CONFIRMED-MISCOMPILE by its lens on the
arithmetic rather than the algebra.**

### 1. S7 asked a NARROWER loop question than every sibling — TWO over-accepts (L3-1, L2-1)

S7 shipped spelled only as `LI->getLoopFor` of `Cond`/`Sel`/`T`'s blocks. Two
shapes walked through it:

* **(a) an IRREDUCIBLE cycle.** `LoopInfo` finds no natural loop, so the clause
  was VACUOUS and the angle select ACCEPTED — for BOTH stems — where the manual
  by-difference DIAMOND over the same cycle declines `control flow inside a loop
  body` (`ControlDetect`'s `regionEntryInLoop` is a reducibility-INDEPENDENT CFG
  successor walk) and the plain UNCONTROLLED rotation declines `tainted handle
  live range crosses a loop backedge`. Every downstream guard that adjudicates a
  cycle is `LoopInfo`-gated, and the freeze suppresses the spine's own
  diagnostics, so the net effect was a shipped Rule-6 reject becoming SILENCE.
* **(b) the ROTATED REGISTER'S RAIL in a loop, anchors in the EXIT block.**
  `lowerLoops` (`CQLoweringPass.cpp:310`) runs BEFORE detection (:322) and
  emission (:323); its `staleRailRecordRead` fence refuses the DIAMOND spelling of
  exactly this shape (probes `q34t`, `q34b`), but 2b's twin `T0` is inserted
  THIRTEEN pipeline steps later, so the fence structurally cannot see it. The
  8h7d.5 lesson verbatim: a fence that runs before the emitter is not a fence on
  what the emitter adds. **No proof of the emitted stream was ever available, and
  the twin witness cannot be posed here — the twin declines.**

**FIX.** S7 now ORs three questions and takes the first that fires:
`LI->getLoopFor`; `ControlShape.h`'s **`blockOnCycle`** (the walk
`regionEntryInLoop` is built from, de-anonymized rather than re-implemented —
Rule 14) over each of `Cond`/`Sel`/`T`'s blocks; and either question over EVERY
MEMBER of the base's rail closure. Message unchanged
(`control flow inside a loop body`), position unchanged (before S6, so the loop
message still wins).

**WHAT OTHER SET IS COMPUTED OVER THE SAME CLOSURE** — the 8h7d.5 F-1/F-3
discipline, asked because this change MOVES a closure computation rather than
adding one. `railWireClosure(RotBase, BothWays, Exclude=T)` was computed inside
S8, on the Ry path only. It is now computed at S7, for BOTH stems, and reused.
**THREE existing consumers read it and all three are unchanged**: S8's
intersection with `CondRails` (reads `BaseWireOrder`), S9's member enumeration
(reads `BaseWireOrder`), and S9's SKIP SET (reads `BaseWire`). Same seed, same
direction, same arm blocks (none), same `Exclude = T` — so those three see exactly
the set they saw before; only the number of times it is built changed (2 → 1) and
only one reader is new. The **Rz stem previously computed NO closure at all**, and
now computes one — used ONLY for the loop question, never for S8/S9, whose §12.1
diagonal exemptions are untouched.

Fixtures: `control_angle_select_reject_irreducible_cycle{,_rz}.ll`,
`control_angle_select_reject_loop_rail_exit_block{,_rz}.ll`. The two existing
`reject_in_loop*.ll` stay green (the `LoopInfo` prong still fires first there).

### 2. Nothing in S1–S10 inspected the ARM VALUES (L5-1, L7-F6, L7-F2)

S1 asked the arms' TYPE and TAINT and never their VALUE. Three families got
through:

* **undef / poison.** `select c, 0.9, undef` folds `fsub 0.9, undef` to a
  CONCRETE quiet NaN, so the emitted stream is `ry(h, undef); ry_c(f, h, NaN)` —
  and on the TRUE edge the source asked for `Ry(0.9)`, a fully defined angle, that
  no refinement of `undef` can recover. `select c, poison, 0.3` puts a raw
  `double poison` in a gate slot. **`LiteralIntegrity`'s guard 1 is CORRECT to be
  silent**: it counts ONE undef slot (the other holds the folded NaN, an ordinary
  `ConstantFP`), which is exactly why the neighbouring `0.9, poison` and
  `undef, undef` cells were loud and this one was not.
* **a non-finite CONSTANT arm** (`+inf`, `NaN`): the well-defined arm is destroyed
  by the composed `inf + (−inf) = NaN`.
* **a non-finite DIFFERENCE of two FINITE arms** (`DBL_MAX − (−DBL_MAX) = +inf`):
  not implied by the previous clause, and the source names no infinity at all.

**FIX.** `angleSelectArmsAdmissible` (`ArmClassify.cpp`, declared in
`ArmAnalysis.h`), asked by S1 and re-asked by the emitter's step 0. Returns
`NotApplicable`, so the caller's pre-existing `rotation angle` decline fires —
**no new diagnostic string**, and the pre-2b disposition is restored exactly.
Undef is asked through the SHARED `valueCarriesUndef` (Rule 14), never a bare
`isa<UndefValue>`, because an arm can be a `ConstantExpr` that CARRIES undef.
Fixtures: `reject_{undef_arm, poison_arm, undef_constexpr_arm, inf_arm, nan_arm,
overflow_difference}.ll`.

### 3. THE ALGEBRA IS EXACT AND THE ARITHMETIC IS NOT (L7-F1)

`R(A) = R(B)·R(A−B)` is an identity over the REALS. The emitted stream realizes
`B + fl(A−B)`, so the angle error is

    delta = A − (B + fl(A−B)),      |delta| <= 1/2 ulp(A−B) ~ |A−B|·2^-53

which is **2^-54 rad on the flagship `0.9/0.3` golden** (physically nothing, and
the shape this increment exists for) and **0.858 rad on `π/1e16`**, **1.0 rad on
`1.0/1e300`** — both of which the PRE-2b binary declined LOUDLY. Turning a loud
refusal into a silently wrong unitary is the one unforgivable outcome, so:

**FIX (structural half).** When BOTH arms are `ConstantFP`, S1 computes `delta`
EXACTLY at compile time with the TwoSum error-free transformation in APFloat at
`rmNearestTiesToEven` — the residual of the subtraction IS the angle error, with
no extended precision and no simulation — and declines above
**`kAngleSelectMaxRoundingRad = 2^-40 rad`**, a NAMED, DOCUMENTED PLACEHOLDER.
Exact differences (Sterbenz pairs, `±0.0`, equal arms, `2^60/2^59`) always pass.
The test is ABSOLUTE in radians, not relative: `1e-20 / 1.0` cancels totally
(100% relative error) and its 1e-20 rad absolute error accepts, correctly.
Verified against an independent C computation of the same six operations on the
lens's 25 measured pairs.

**RUNTIME arms carry BOTH RESIDUAL CLASSES, not a check — and the round-1 wording
"carry the bound" named only one of them.** *(Corrected by the round-2 review,
lens R1 item 1; the full record is §10.)* The `fsub` is real and no compile-time
fence is possible, so with a non-constant arm the emitted stream carries:
**(i) the ROUNDING residual** `|δ| ≤ ½ ulp(A−B)` — measured 0.858 rad from plain C
with `A = π`, `B = 1e16` as `double` parameters; **and (ii) a NON-FINITE
DIFFERENCE FROM FINITE ARMS** — measured `cqrt_ry_i32_controlled(f, h, inf)` from
plain C with `A = 8.98846567431158e307`, `B = −A`. Half an ulp does not describe
`inf`; (ii) is a different failure and must never be folded into "the bound".
Both are the SAME arithmetic the manual by-difference C twin performs — which is
also why **the twin byte-identity witness is blind to both by construction** (it
witnesses that 2b matches the by-difference PROGRAM, not that the program matches
the SOURCE), and why `tools/angle_select_twin_matrix.py`'s "what it cannot
witness" block now says so (its runtime pair `1.25/0.75` is Sterbenz-exact, so not
one cell in that table can exhibit the error even in principle).

Fixtures: `reject_rounding_{pi_1e16, one_1e300}.ll` (decline),
`accept_rounding_flagship_bound.ll` (0.9/0.3 accepts, δ = 2^-54, emitted constant
pinned as `0x3FE3333333333334`), `accept_exact_difference_large.ll` (2^60/2^59:
exact, huge, accepts — the fence is on δ, not on magnitude). **The 46 pre-existing
fixtures, the 7 e2e slices and all 158 twin-matrix cells were checked UNMOVED: every
constant pair in the tree has δ = 2^-54 or exactly 0.**

> ### OWNER-DESK ITEM — **THE ROUND-2 THREE-WAY FORM, VERBATIM.** It supersedes the round-1 two-way wording below and is the reason the constant above is called a PLACEHOLDER.
>
> ⚠ **RE-FRAMED BY THE CLEARANCE REVIEW — READ §11 FIRST.** The parenthetical
> "(shipped)" on option (1) below is the wording as the round-2 review left it and
> is **no longer true**: the Rule-13 clearance review ranked the run-time-arm
> accept a BLOCKER (finding F-11 / B1) and the orchestrator shipped **option (2)**
> instead. The item is kept VERBATIM rather than edited so the choice the owner is
> ruling on is the one that was put to them; §11 carries the shipped answer, the
> measured cost, and what each remaining option now costs.
>
> "(1) accept-with-residual (shipped): round-to-nearest angle arithmetic is IN the
> model, the runtime residual (both halves) is documented, the 2^-40 constant
> placeholder goes; (2) decline runtime arms (constant arms only) until (3);
> (3) the two-controlled form x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A) — no fsub, no
> rounding, no inf/NaN manufacture, no undef fold, existing symbols only, one
> extra controlled gate + an X pair, twin = two Inc-1 diamonds, exact for runtime
> arms too — a PRD §12.3 design change."
>
> **Why the choice had to grow a third leg.** The round-1 wording below offered
> only "(i) rounding is in the model" or "(ii) the two-controlled form", and it
> described the runtime residual as "the bound". The round-2 review (lens R1 item
> 1) measured that with RUNTIME arms the same accept class also manufactures
> `inf`/`NaN` from two finite arms, which no bound describes — so an owner reading
> (i) as "accept a half-ulp of angle error" would have been ruling on a smaller
> thing than what ships. Option (2) exists because the two are separable: constant
> arms ARE fenced today, and refusing only the runtime ones is a real, cheap
> intermediate that costs one committed accept fixture
> (`control_angle_select_ry_arg_angles.ll`) and the `args` axis of the twin matrix.
> It is not what shipped — see §10's disposition of R1-1 — but it is a live option.
> **[CLEARANCE UPDATE: option (2) IS now what shipped, and this cost estimate was
> right to within one file — the measured cost was TWO fixtures rewritten
> (`ry_arg_angles` replaced by `reject_runtime_arms`, and the datamux fixture's
> arms changed to constants), THREE new decline fixtures, ZERO e2e goldens, and 16
> twin-matrix `args` cells reclassified. §11.]**
>
> **The round-1 two-way wording, kept for the record, NOT the live item:**
>
> "IEEE rounding of the by-difference angle. The lowering is exact in real
> arithmetic. In double, the emitted true-arm angle is B + fl(A−B),
> |δ| ≤ ½ ulp(A−B) ≈ |A−B|·2^-53: 2^-54 on the flagship golden, 0.858 rad on
> π/1e16. Shipped: constant arms decline above a PLACEHOLDER 2^-40 rad; runtime
> arms carry the bound (it is the same arithmetic the manual by-difference C
> program performs). Ruling needed: (i) is round-to-nearest angle arithmetic IN
> the model (the fenv analogue) — then the placeholder can go; or (ii) if the
> emitted stream must denote the source's angle EXACTLY, the alternative is the
> two-controlled form x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A): no fsub, no rounding, no
> inf/NaN manufacture, no undef fold, existing symbols only, one extra controlled
> gate + an X pair, twin = two Inc-1 diamonds — a PRD §12.3 design change, NOT
> made this session."

### 4. The emitter's step 0 re-validated IDENTITY but not S4's SEMANTIC half (L4-1, L1-1, L7-F8)

`AngleSelectEmit.h` claimed "every bail precedes the FIRST emitted instruction".
It did not. S4's "exactly ONE tainted compare operand" was proven at DETECTION and
never re-asked, and a preceding 4.5 **SwitchDataMux** region in the SAME
`lowerControlRegions` loop RAUWs the compare's classical operand (the all-const
merge phi) to its freshly minted TAINTED `%out` rail. Step 0 passed (it checks
identity, not taint); steps 1–2 emitted the `fsub` and the unconditional twin, and
inserted the twin into `Tainted`/`BirthOrder`/`ThetaCalls`; step 3's
`lowerCompareToFlag` then returned null and bailed MID-STREAM with the
MISLABELLED `no template for opcode 'icmp i1' in tainted context`. It is loud
today ONLY because `DS_Error` calls `exit(1)` — i.e. because the process dies
before anyone can look at the half-emitted module.

**FIX.** A new **step 0b** re-asks EXACTLY what S4 asked — exactly one tainted
compare operand, `comparePredLowerable`, `compareFlagMintable` — and declines
`control flow` BEFORE `CreateFSub`. The `return`s in steps 3 and 5 are KEPT and
re-commented as UNREACHABLE (by the lockstep re-ask AND by process exit), not as
"pre-emission" bails; step 5's comment additionally records that its `cqrt_free`
would fire even on a null `Strip` — a dirty free on a path that cannot be taken.
`AngleSelectEmit.h:72`'s claim is corrected in place. Fixture:
`reject_datamux_qq_after_rauw.ll` — **the message CHANGING from the mislabelled
one to `control flow under quantum control` is the red-green.** Controls `Q3`
(same module, no select — still accepts) and `Q5` (genuinely classical second
operand — still accepts, intended stream) verified unmoved.

### OVER-DECLINES RECORDED, NOT FIXED — each is a Rule-13 change

* **L4-2, source-order-dependent, SAME UNITARY — bd `test_C_libtooling-aght`.**
  `if(q==5) r=cq_phi(r,.9); else r=cq_phi(r,.3); if(p==4) r=cq_phi(r,.7);`
  declines `rotation angle`, while the two statements in the OPPOSITE order
  ACCEPT, and the `cq_theta` twin of the same composition accepts. Cause:
  `ArmClassify::taintedAngleGate`'s trailing clause
  `isPhiCall(Base) && AngleTainted(Base)` inspects the FOLLOWING region's routed
  base at DETECTION time, i.e. before `lowerControlRegions` erases the select, and
  finds the still-present select in the base `cq_phi`'s angle. All the gates are
  diagonal, on one rail, under flags minted from DISJOINT condition rails, so both
  orders are the same unitary — this is §8 worry 4 seen on the source-order axis.
  **One-line fix shape, for whoever takes it:** treat a select already claimed by
  an `AngleSelectRegion` in `plan` as CLASSICAL-after-emission (i.e.
  `taintedAngleGate` should not count an angle whose select the plan is about to
  erase). Widening `taintedAngleGate` is a Rule-13 change and was not made.
  Reproducers `review2b/L4/run/x072_ASZ_DRZ_same_AS1st.c` vs `x074_..._AS2nd.c`
  (session-local scratch; the durable record is bd **`test_C_libtooling-aght`**,
  created 2026-09-03, which carries the shape and the one-line fix above —
  round-2 review, lens R2 N9: the round-1 draft cited only the scratch paths,
  which do not survive the directory).
* **L4-3, scope fact — AND ITS DATA-SELECT HALF IS FALSE AS ORIGINALLY WRITTEN**
  (corrected by the Rule-13 clearance review, non-blocking observation 2). The
  bullet said "an angle select followed by a VALUE arm **or a data select** on the
  same register declines (gate 5's coherence fence)". The **value-arm half is
  correct** (probe `x08` declines `control flow`; the ORACLE declines it too, so
  it is not a 2b regression). The **data-select half is NOT**: with NON-ALIASING
  operands it **ACCEPTS** — `clearance2b/x/x04_angle_then_dataselect.c` lowers,
  emitting the ordinary 4.4 controlled-XOR merge over a frozen rail, strict
  stage-2b clean. L4's own reproducer wrote `(p==4) ? r : (r^9)`, whose operands
  ALIAS, so it was declined by gate **6**, not gate 5, and the record generalized
  from one aliasing cell. Its manual twin (`x06`) declines for a **block-lifetime**
  reason (the diamond's merge block hosts the data select) — bd `hcrg`'s lesson
  from the other side: that twin is protecting the emitter's bookkeeping, not the
  unitary, so it is not evidence about the select form either.
* **L1-4 and its two subs, PRE-EXISTING on both binaries — bd `test_C_libtooling-nsvk`.** An angle-select
  consumer `T` (a `cq_theta`) sitting inside a FOLLOWING diamond's compare→branch
  window declines `condition predates a non-diagonal gate` from the diamond's own
  positional prong. `control_angle_select_ry_then_region.ll`'s `%c2`-after-`%t`
  ordering is therefore LOAD-BEARING and its header now says so. The window's
  OTHER half — a theta in `[Cond, Sel)` — is owned by gate 2c prong (c) and now
  has its own fixture (`reject_theta_before_select.ll`); the pre-existing
  `reject_theta_between.ll` pins only the `(Sel, T)` half (S6, `rotation angle`).
  Sub-item: a `5 − q` Ry base declines `rotation arm on a condition wire`, which
  is Inc-1's inherited no-`cqrt_subc` conservatism, not 2b's. The durable
  record is bd **`test_C_libtooling-nsvk`**, created 2026-09-03.

### OTHER FACTS THE ROUND RECORDED

* **L2-6 — the QRAM/alloca Shadow launder accepts, and it is sound for a reason
  S9 does not supply.** The proof comes from the STORE's position (S9 sees the
  store), not from S9 seeing the load. The structural gap is closed by a different
  clause than the one a reader would expect; recorded so nobody "simplifies" S9 on
  the assumption that it is what covers this.
* **L2-5 — S9 is now REACHABLE for a PURE OP via a lifted phi** (probe `q16`).
  bd memory `r6-closure-hole` says R6 never fired for a pure op; that is no longer
  true of this classifier and the memory needs the amendment.
* **L1 §5d — `c_d7` stays a 2a DIAMOND.** `if(q==5) q=cq_phi(q,.9); else
  q=cq_phi(q,.3);` on the register's OWN condition is NOT folded by `clang -O1`
  into an angle select; both binaries lower it as an in-place Rz diamond. The "2b
  is what makes the C if/else compile" claim is about the DISJOINT-register form.
* **L7-F7 — equal constant arms** emit a full mint/strip/free around
  `R_c(f, h, 0.0)`. Harmless (δ = 0, and the gate is the identity), reachable from
  runtime-equal arguments as well as from hand IR. Not fenced: an identity gate is
  a correct realization of "rotate by A on either edge".
* **L4-8 — a guarded Shadow store plus an angle select in one function drops the
  whole-DAG reversal** (the store's flag is never stripped or freed). **PRE-EXISTING
  and NOT 2b's**: a plain extra `icmp` consumer of the condition register
  reproduces it byte-identically on BOTH binaries. Recorded so it is not
  mis-attributed to this increment by the next reader.
* **L3-5 — `EmitInverse` CAN spell the controlled adjoint**; the unreachability
  holds STRUCTURALLY (`railCarriesControlledRotation` at the `DagTraversal` 1-of-3
  and `Uncomputation` sites, plus `isInPlaceGateOn`'s `_controlled` catch-all).
  §3(f) is accurate on that point.
* **L6 VERIFIED, listed because a verification is a result:** the counts
  1407/46/15/31/305/295/278/156; the twins ARE oracles (rebuilt on the pre-2b
  binary); the derived-base twin identical by hand; §4-C true; red-green on all 17
  accepts; the 35-mover sweep identical; the §2 string table exact.

### THE STANDING LESSON FROM THIS ROUND

**When a clause asks a question its SIBLINGS also ask, ask it the same way.** S7
and `regionEntryInLoop` were two spellings of "is this on a loop", and the two
disagreed on irreducible cycles — which is the failure mode bd `uow0` and bd
`1fim` already record from other pairs. The repair was not a new predicate; it was
deleting a second spelling. The same reading explains finding 2: S1 asked two of
the three questions that make an operand usable (type, taint) and not the third
(value), while `LiteralIntegrity` — which DOES ask about values — was asking a
COUNTING question over a different closure and was right to stay silent.

### WHAT THE ROUND-1 FIX AGENT RAN — counts, and only what was executed

| layer | result |
|---|---|
| `ctest -R ir-pass-lit` | **1423 fixtures: 1422 passed, 1 expectedly failed** (`ls ir-pass/test/*.ll \| wc -l` = 1423) |
| `ctest -j6 -R 'angle'` | **10/10** (7 slices + the 3 `compare_files` twin gates) |
| `ctest -j6 -R 'e2e-slice-control\|e2e-slice-loop\|e2e-loop-twin\|e2e-angle'` | **61/61**, including `e2e-loop-twin-matrix` (203 s) |
| `tools/angle_select_twin_matrix.py --oracle <pre-2b> --jobs 6` | **UNMOVED: 116 BOTH-ACCEPT-IDENTICAL / 12 BOTH-DECLINE / 16 DEGENERATE-FOLD / 1 OVER-DECLINE / 13 SUSPICIOUS, 0 MISMATCH** — no cell moved under the rounding fence, as predicted (every constant pair in it has δ = 2^-54 or 0) |
| `cmake --build build --target cq-opt-equivalence-full` | **1423 fixtures, 0 mismatches** |
| `tools/golden_multiset_audit.py --all` | **280 goldens: 7 NEW-FILE, 273 UNCHANGED**, 0 routes collapsed |
| `tools/control_flag_order_check.py` | 1423 files, **393 control flags, 0 violations** |
| semicolon detector (`grep -rn '^; *[A-Z0-9]*-\?NOT: .*;$' ir-pass/test/*.ll`) | **empty** |
| fixture MUTANT re-validation of the two hardened files | `control_swap_reject_switch_datamux_angle.ll`: **13 of 13 mutants RED** (was 8 of 13 — blind to `dblfree`, `freerail`, a CONSISTENTLY wrong rail, a tail rotation after the free and a tail `cqrt_x`); 10 of the 13 are lens L6's committed mutants, 3 were built for this check; all 17 accept fixtures: **17 of 17 catch an injected tail rotation** (was 0 of 17) |

**NOT run by this agent:** the full `ctest -j6` — the orchestrator owns it as
committer (Rule 19 moments 1/2/5).

---

## 10. Round-2 Rule-13 review (2026-09-03) — 2 lenses over the round-1 FIXES

Round 1 reviewed the increment; round 2 reviewed **the round-1 fixes**, which is a
different subject and found a different class of defect. Two lenses, read-only,
each running the fixed binary against the pre-2b oracle.

| lens | scope | what it ran |
|---|---|---|
| **R1** | the widened S7, the arm-value + rounding fences, the emitter step-0b re-ask — as CODE | **170 subjects** (168 hand `.ll` + 2 plain-C programs through `clang -O1`) × 2 binaries = **340 `cq-opt` invocations**; 6 accepted outputs stage-2b-checked, linked and run to a trace; **1,000,000 floating-point pairs** through an INDEPENDENT exact-rational δ oracle (`fractions.Fraction`) — 400k TwoSum-equivalence fuzz with **0** mismatches and **0** NaN/∞ residuals, 600k threshold characterisation with **0** counterexamples to the 16384-rad claim; **22/22** agreement on boundary pairs generated FROM that oracle; `lit ir-pass/test` 1422+1; `ctest -R angle` 10/10; twin matrix **UNMOVED** |
| **R2** | fixture and doc TRUTH of the fixes | **361 fixture-mutation cells** on real lowered output (342 kit cells from lens L6's 18 mutation kinds × 19 accept fixtures + 19 `condrail_consistent` cells + 4 hand-built positional mutants), ≈1200 FileCheck invocations, ≈150 pass runs, the twin matrix reproduced cell-for-cell, every headline count re-measured |

**R2's headline is the one to carry about round 1's quality:** regenerated from the
CURRENT binary's output, **19 of lens L6's 20 green-on-mutant cells are now RED** —
the round-1 fixture hardening did what it claimed. What it did NOT close is one
NEW blindness class R2 constructed (N1 below), and one file that fell through a
counting gap (N2).

### THE ONE GRADED FINDING — R1 item 1, **CONFIRMED-MISCOMPILE**, disposition ACCEPT-WITH-RESIDUAL

**Recorded verbatim as graded. The grade is not softened, and the disposition is
recorded next to it rather than in place of it.**

> **R1, item 1 — CONFIRMED-MISCOMPILE.** "The A2/A3 fence is `ConstantFP`-gated,
> so it closed only the CONSTANT half of L7-F1/L7-F2. Both halves are still
> reachable from PLAIN C through RUNTIME angle arms, which are inside the shipped
> accept class. … I grade this CONFIRMED-MISCOMPILE by the same standard round 1
> applied to L7-F1 (wrong unitary on an ACCEPTED input, reachable from plain C,
> loud decline on the pre-2b binary). The orchestrator may re-grade the (B) half
> as 'knowingly deferred'; the **(A) half (∞/NaN from finite runtime arms) was
> ruled FENCE-NOW and is not fenced**, and the docs assert a bound that is false
> for it."

Reproducers (plain C, `clang -O1`, full pipeline to a linked trace):
`review2b_r2/R1/probes/c/rt_pi.c` and `review2b_r2/R1/probes/c/rt_ovf.c` — the
canonical 2b source shape with the two angles as **function parameters** instead
of literals, `if (q == 5) r = cq_theta(r, a); else r = cq_theta(r, b);`.

| reproducer | NEW | ORACLE |
|---|---|---|
| `rt_pi` (a = π, b = 1e16 — both ordinary finite doubles) | **ACCEPT**, exit 0, strict `free_pairing_check` clean | DECLINE `rotation angle under quantum control` |
| `rt_ovf` (a = +8.98846567431158e307, b = −a — both FINITE) | **ACCEPT**, exit 0, strict fpc clean | DECLINE `rotation angle under quantum control` |

Emitted traces, linked and run:

```
rt_pi :  cqrt_ry_i32(h1, 0x1.1c37937e08p+53)                      <- B = 1e16
         cq_template_icmp_eq_i32_hl(h0, 5) -> h2
         cqrt_ry_i32_controlled(h2, h1, -0x1.1c37937e07ffep+53)    <- fl(A-B)
rt_ovf:  cqrt_ry_i32(h1, -0x1p+1023)
         cq_template_icmp_eq_i32_hl(h0, 5) -> h2
         cqrt_ry_i32_controlled(h2, h1, inf)                       <- !!
```

On the true edge the device realizes `Ry(B)·Ry(S) = Ry(B+S)` in reals: `rt_pi`
gives **4.0 rad where the source wrote `Ry(π)`** — 0.858407 rad wrong, the same
number lens L7-F1 measured for the constant spelling that now declines; `rt_ovf`
gives a controlled angle of **+∞** where the source named a finite one.

**DISPOSITION (orchestrator, at the time of the round-2 review): RUNTIME ARMS
STAY ACCEPTED.**

> ⚠ **SUPERSEDED — the disposition below is NOT what shipped. Read §11.** The
> independent Rule-13 CLEARANCE review ranked this same item a **BLOCKER** (F-11 /
> B1) and the orchestrator ruled **option (2): the accept narrows to CONSTANT
> arms**, so run-time arms DECLINE. The three numbered reasons are kept verbatim
> because a future reader re-opening the question deserves the argument that was
> made; each is answered in §11. In short: (1) is true but the fixture it names
> has been DELETED and replaced by a decline fixture; (2) is true and is precisely
> why the Prime Directive says to refuse the class — an unfenceable precondition
> that is DISPROVEN on reachable input is a decline, not a residual; (3) rests on
> "it is the same arithmetic the manual twin performs", and the clearance review
> measured that **the manual twin of this shape does not compile at all**, on
> either binary — so declining it is not declining something we could build, and
> the residual was reachable only through 2b.

The
reasons, recorded because a future reader must be able to re-open this on the
argument rather than on the absence of one:

1. They are **inside the PRD §12.3 shape** — "A, B classical" has always included
   a classical run-time value; `control_angle_select_ry_arg_angles.ll` is a
   committed accept fixture for exactly this path and has been since hand-back.
2. **No compile-time fence can exist for them.** The `fsub` happens at run time.
   The only fences available are "decline every runtime arm" or the two-controlled
   redesign — neither of which is a fence, both of which are option changes.
3. Declining them is **Rule 17's "decline of the very thing we aimed to build"**,
   and the exact alternative that removes the residual outright (option (3), the
   two-controlled form) is already on the owner's desk in §9.

**What is owed instead, and was done in this commit:** every sentence that
described the runtime residual as "the bound" now states **BOTH halves** — the
`|δ| ≤ ½ ulp(A−B)` rounding AND the non-finite difference from finite arms — at
all eight sites (`ArmClassify.cpp`'s block comment and its in-clause comment,
`AngleSelectEmit.h`, `ROADMAP.md`, PRD §12.3, both `CLAUDE.md` 2b paragraphs, §9
here, and the two fixtures that actually have runtime arms). **No warning is
emitted, and the accept set for runtime arms is unchanged.** *(That last sentence
was true of the round-2 commit and is false of the shipped one — §11: run-time
arms are no longer in the accept set at all. The eight-site both-halves wording
survives, re-pointed: at every one of those sites the two halves are now the
stated REASON for the refusal.)*

### R1's other items — all NOTEs, all acted on

| item | what it is | what was done |
|---|---|---|
| **R1-2** | S7's `Exclude = T` leaves a cycle strictly FORWARD of the consumer outside BOTH new prongs; the comment claimed S7 "asks all three questions, ORed, over-declining by construction" and that "nothing about the consumer's position is lost". **Both sentences are false of the rail past `T`.** R1 explicitly did NOT grade it an over-accept: the manual by-difference twin is byte-identical on the ORACLE, so the "loud decline becomes silence" property is **Inc-1's structural freeze**, not 2b's. Second asymmetry, same clause: prong (iii) asks the ROTATED register's closure only, never the CONDITION register's. | Both comments **rewritten to say exactly that**, with both asymmetries and the byte-identity argument spelled out; NEW ACCEPT FIXTURE `control_angle_select_forward_rail_cycle_frozen.ll` pinning the gap, the frozen rail (no twin adjoint, no `cqrt_free` of the rail) and the soundness argument; the condition-rail asymmetry stated in both `reject_loop_rail_exit_block{,_rz}.ll` headers. Re-derived without the reviewer's scaffolding block: select-on-NEW vs twin-on-ORACLE `diff` of the emitted body is **empty**, and the plain uncontrolled program declines `tainted handle live range crosses a loop backedge` on **both** binaries. |
| **R1-3** | prong (iii)'s coverage of the L2-1 family is **CONTINGENT** on `lowerLoops`' Case-A rail collapse (`:310`, before detection) having re-anchored the in-loop gate onto the base — `oa1_var_seed_t.ll` declines only because the header phi was rewritten, while `nat_sel_rz.ll` (same forward read, no rail header phi) accepts. | Stated in the S7 comment as a CONTINGENCY, with the two measured shapes and the warning that a future change to Case-A's collapse silently NARROWS S7; also in both `loop_rail_exit_block` headers. |
| **R1-4** | `reject_undef_constexpr_arm.ll` did NOT separate `valueCarriesUndef` from `isa<UndefValue>` — LLVM-19's **parser folds** `bitcast (i64 undef to double)` to plain `double undef`. Re-measured here with `llvm-as \| llvm-dis`: **confirmed**. | Fixture body **replaced** with `bitcast (i64 ptrtoint (ptr @gu to i64) to double)` where `@gu`'s initializer carries `undef` — a shape that survives LLVM-19 folding. Header rewritten to say honestly what it now pins (the CLAUSE ORDER), because clause (1b) below subsumes it. |
| **R1-5** | a `double` `ConstantExpr` arm took the `!CA \|\| !CB → return true` "runtime arm" path and bypassed clauses 2a/2b/3 entirely. It is a **link-time** constant, not a run-time value, and the comment was false for it. Hand-IR-only. | **CODE FIX, clause (1b):** an arm that `isa<Constant>` but not `ConstantFP` is refused (`NotApplicable` → `rotation angle`). Fixture `control_angle_select_reject_constexpr_arm.ll`, RED before / GREEN after. The `!CA \|\| !CB` comment is rewritten to say the split is by **EVALUABILITY**, not constness, and to state both runtime residual halves. |
| **R1-6** | **no fixture pinned the threshold VALUE or the `>` boundary.** The suite stayed green for any threshold in `(2^-54, 0.858]` — 33 binary orders — and for a `>=` re-spelling. | Two fixtures: `accept_rounding_at_bound.ll` (δ = **exactly** −2^-40, accepts) and `reject_rounding_above_bound.ll` (δ = −2^-39, declines). δ values verified with an **independently written** TwoSum C program (`fix2b_r2/twosum.c`), not by trusting the reviewer's. **Three mutations measured, each reddening exactly one file:** `2^-40 → 2^-41` reddens the accept cell; `→ 2^-39` reddens the decline cell; `!= cmpGreaterThan → == cmpLessThan` (a strict boundary) reddens the accept cell alone. |
| **R1-7** | `blockOnCycle` is O(V+E) per block, the memo is per-select ⇒ O(S·(V+E)); the `LoopInfo` short-circuit never helps a straight-line function. Measured 0.42 s at 200 selects × 4,200 blocks. | One paragraph by the memo, with the measurement and the warning not to hoist the memo to module scope on a wrong reading of its purpose. |

### R2's eleven notes — all acted on

| note | what it is | what was done |
|---|---|---|
| **N1** | the round-1 `%[[QC]]` repair pinned mint↔strip IDENTITY but bound `%[[QC]]` **on the mint line itself**, so a CONSISTENTLY wrong condition rail (both mint and strip rewritten to read the ROTATED register) stayed green on **7** accept fixtures. On the Ry stem that mutant is also a Rule-6 hazard: the controlled Ry between mint and strip relabels the rail being compared, so the flag never returns to \|0⟩ and its `cqrt_free` is a hidden measurement. | `%[[QC]]` **anchored at the condition register's own `cqrt_alloc`** in all 7 (`ry_alias_pre_gate`, `ry_arg_angles`, `ry_dead_base_frozen`, `ry_derived_base_late_use_frozen`, `ry_lifted_phi_base`, `ry_sgt`, `rz_dead_chain`), with the note at the mint rewritten. Re-measured with the reviewer's own generator, regenerated from the CURRENT output: **19 RED / 0 GREEN / 2 N/A** over the 21 accept files (was 10 RED / 7 GREEN / 2 N/A). |
| **N2** | `control_swap_defer_select_angle.ll` was still blind to a rotation in the **[measure, ret]** window — including the HALF-REVERSAL adjoint of the unconditional twin — while both the fix report and §9 claimed "17 of 17". The number 17 meant two different sets in the two documents and this file fell through the gap. It is the ONLY lit exercise of the flipped 4.4 defer shape and of the flat Rz-on-the-condition-register stem, and it has **no e2e slice**. | Trailing `CHECK-NOT: call void @cqrt_rz_` / `@cqrt_ry_` added, plus whole-body `NOROUTE-NOT: double -7.500000e-01` / `-9.000000e-01` for the half-reversal spellings. Mutants regenerated from the current output: `tail_extra_rot` and `adjoint_twin` are now **RED on CHECK** (adjoint also RED on NOROUTE); both were GREEN on all three prefixes before. |
| **N3** | "the round-1 review then added 16 more (3 accept / 13 decline)" is wrong in BOTH places it appears; measured **2 accept / 14 decline**. | §5 now carries a **measured batch table** (46 → +16 → +4, 19 accept / 47 decline, corpus 1427) with the re-measure commands; `CLAUDE.md`'s sentence corrected the same way. |
| **N4** | §2's string↔fixture map was stale in 4 of 7 rows, misattributed a fifth (`reject_datamux_qq_after_rauw` is emitted by `AngleSelectEmit`, a different TU), and its opening "three strings of its own" no longer describes the pass; §5's Decline list named 31 of 45. | §2 **rewritten as the measured partition over ALL 47 decline fixtures**, generated by script (`fix2b_r2/strmap.py`) rather than by hand, with the two-owner `control flow` row split; §5's Decline list now names **all 47**, grouped by the batch that added each. |
| **N5** | the new IEEE paragraph in `control_swap_defer_select_angle.ll` is FALSE of that fixture (its arms are the constants 0.25/0.75, δ = 0, Sterbenz-exact) and contradicted its own next sentence; the one file whose arms really are runtime carried no caveat at all. | The defer fixture's paragraph corrected (with the retraction recorded in place); the runtime-arm caveat — **both halves**, per the R1-1 disposition — added to `control_swap_reject_switch_datamux_angle.ll` **and** `control_angle_select_ry_arg_angles.ll`. |
| **N6** | §3(f)'s corrected sentence claimed both freeze fixtures carry `NOROUTE-NOT: cq_template_mul_i32_hl_unc`; `ry_dead_base_frozen` does not (it has no `mul`). | §3(f) corrected to name the one fixture that carries it and to say why the other's would be vacuous — rather than adding a vacuous directive. |
| **N7** | §5b M17's "11 of the 12 `ry_*`" is stated over a corpus that has since grown. | The cell now says the figure is **as-measured-at-hand-back**, names the four accept fixtures added since, and says re-measuring needs a rebuild neither review round did. |
| **N8** | `ControlPlan.h` cited `ArmClassify.cpp:1534`, a closing brace. | Corrected to **`:1538`**, the `if` itself. (The COUNT — exactly one read — was re-verified true.) |
| **N9** | the two bd follow-ons exist but neither id appears anywhere in the tree; §9 cited session-local scratch paths that will not survive. | §9's two OVER-DECLINE bullets now name **`test_C_libtooling-aght`** (L4-2) and **`test_C_libtooling-nsvk`** (L1-4). |
| **N10** | §6's golden annotation still wrote `A-B=0.6` three lines above the paragraph retracting that spelling. | Annotation changed to `fl(0.9-0.3)) != fl(0.6)` with the bit patterns spelled out beneath it. |
| **N11** | `reject_stale_chained_theta.ll:11` prose began `; QUESTIONS:` — an all-caps token plus colon at line start, the bd `test_C_libtooling-45fd` shape, inert only because no RUN line declares that prefix. | Re-wrapped, with the reason recorded in place. **Mechanical re-scan of all 68 files in this family (every `; PREFIX:` / `; PREFIX-NOT:` shape whose prefix no RUN line declares, minus the lit directive names): 1 hit before, 0 after.** The same scan over all 1427 `ir-pass/test/*.ll` reports 128 further hits in OTHER families (`; ARM:`, `; SOURCE:`, `; MEASURED:` …) — a tree-wide house style, out of this commit's scope and recorded here so the next reader does not re-discover it as new. |

### WHAT ROUND 2 COULD NOT REFUTE (re-measured, not inherited)

* **The δ arithmetic.** R1 wrote its own TwoSum and an exact-rational oracle and
  found **0 mismatches over 400,000 pairs**, **0** NaN/∞ residuals, and **22/22**
  agreement at the boundary. This agent re-derived the seven load-bearing δ values
  independently again (`fix2b_r2/twosum.c`): 16384/2^-40 → −2^-40; 32768/2^-39 →
  −2^-39; 0.9/0.3 → −2^-54; π/1e16 → −0x1.b7812aeef4bap-1; 1.0/1e300 → 1.0;
  2^60/2^59 → 0; 8192/2^-41 → −2^-41.
* **The Rule-17 bound.** `|δ| ≤ ½ ulp(A−B) = 2^(e−53)`, so `|δ| > 2^-40` forces
  `e ≥ 14`: the fence **cannot** decline any constant pair whose difference is
  below 16384 rad (~2607 full turns). R1 measured 0 counterexamples over 600,000
  pairs drawn from ±20000.
* **A1's refactor is a pure extraction** (`blockOnCycle`'s body byte-identical to
  the old `regionEntryInLoop` body; no second reachability exists).
* **The twin matrix is UNMOVED** by everything either round did — reproduced
  cell-for-cell twice by R1 and once by R2.
* **19 of 20 L6 green-on-mutant cells closed** by the round-1 hardening.
* **Strict stage 2b on all 19 accept outputs** (R2): 39 rail mints, 39 left
  allocated, 23 free sites, 23 verified, **0 violations, 0 unproven**. Re-run by
  the fix agent over the **21** accept outputs that exist after this round
  (the same 19 plus `accept_rounding_at_bound` and
  `forward_rail_cycle_frozen`): **21 pass / 0 fail**, all STRICT (no
  `--allow-unproven`).

### THE STANDING LESSON FROM ROUND 2

**A fence written with `dyn_cast<X>` splits the world into X and NOT-X, and the
`else` branch inherits whatever sentence you wrote about the case you had in
mind.** R1-5 is that exactly: `dyn_cast<ConstantFP>` was written to separate
"constant" from "runtime", and the `else` silently acquired a third population —
link-time constants — for which the comment ("no compile-time difference exists")
was simply false. R1-1 is the same shape one level up: the `else` branch *is* the
runtime population, the comment described one of its two residuals, and the
missing one was the worse one. Neither is caught by asking whether the code is
right; both are caught by asking **what else lands in the branch you did not name.**

### WHAT THE ROUND-2 FIX AGENT RAN — counts, and only what was executed

| layer | result |
|---|---|
| `lit ir-pass/test --filter 'angle_select\|control_swap_defer_select\|datamux_angle'` | **68 / 68 PASS** |
| `ctest -R ir-pass-lit` | **PASS** (83.3 s); `lit ir-pass/test` reports **1427 discovered, 1426 passed, 1 expectedly failed**, and `ls ir-pass/test/*.ll \| wc -l` = **1427** |
| `ctest -j6 -R 'angle'` | **10 / 10** (7 slices + the 3 `compare_files` twin gates) |
| `tools/angle_select_twin_matrix.py --oracle <pre-2b> --jobs 6` | **UNMOVED: 116 BOTH-ACCEPT-IDENTICAL / 12 BOTH-DECLINE / 16 DEGENERATE-FOLD / 1 OVER-DECLINE / 13 SUSPICIOUS, 0 MISMATCH** (158 cells) — identical to both review rounds' tables |
| `cmake --build build --target cq-opt-equivalence-full` | **compared 1427 fixtures, 0 mismatch(es)** (the accept predicate changed again — Rule 19 moment 5) |
| `tools/golden_multiset_audit.py --all` | **280 goldens: 7 NEW-FILE, 273 UNCHANGED**, 0 routes collapsed, PASS |
| `tools/control_flag_order_check.py` | **1427 files, 395 control flags, 0 violations** (393 → 395: the two new accept fixtures) |
| semicolon detector (`grep -rn '^; *[A-Z0-9]*-\?NOT: .*;$' ir-pass/test/*.ll`) | **empty** |
| dead-prefix scan over the 68 family files | **1 hit → 0** (the N11 line); the same scan over all 1427 finds 128 hits in other families, pre-existing house style |
| `ctest -N` | **305 — UNCHANGED** (4 lit fixtures added, no ctest entry) |
| R2's L6 mutant kit, regenerated from the CURRENT output, 21 accept files × 18 kinds | **372 RED, 0 GREEN-ON-MUTANT, 6 N/A** (378 cells; R2 measured 334/2/6 over 19 files) |
| R2's `condrail_consistent` mutation, regenerated | **19 RED, 0 GREEN, 2 N/A** (R2 measured 10/7/2) |
| the two hand-built `defer_select_angle` positional mutants | **2 / 2 RED** (both were GREEN on all three prefixes) |
| R1's whole probe corpus (`s7`, `ce2`, `delta`, `arm2`, `arm`, `bnd`, `fx`, `r1repro`, `s89`), diffed against its recorded `.NEW.err` | **168 subjects compared, 3 MOVED** — `ce_addr_{A,B,gepinf}.ll`, i.e. exactly the C1 class and nothing else |
| the threshold mutation triple (rebuild each) | `2^-40 → 2^-41` reddens `accept_rounding_at_bound` ONLY; `→ 2^-39` reddens `reject_rounding_above_bound` ONLY; `<=` → strict `<` reddens `accept_rounding_at_bound` ONLY |
| STRICT `free_pairing_check.py` on all **21** accept outputs | **21 pass / 0 fail**, no `--allow-unproven` |

**NOT run by this agent:** the full `ctest -j6` — the orchestrator owns it as
committer (Rule 19 moments 1/2/5).

---

## 11. Rule-13 CLEARANCE review (2026-09-03) — the BLOCK verdict, and the narrowing that answers it

Rounds 1 and 2 were *reviews*. This was the **clearance**: one independent
read-only agent, its own physics write-up produced BEFORE anything was run, a
per-consumer code audit, 131 subjects × 2 binaries (262 `cq-opt` invocations, 90
linked traces), a 1427 × 2 whole-corpus sweep, an independently re-implemented
mutation kit, a `libgmalloc` pass over 71 subjects, and one mutant build in a
scratch copy of the repo. It re-verified findings F-1 … F-10 and F-12 … F-17 as
FIXED and returned **one** blocker.

### THE VERDICT, VERBATIM

> **VERDICT: BLOCK — F-11: with RUN-TIME angle arms the shipped accept class emits
> a proven-wrong unitary from plain C (`Ry(π)` → `Ry(4.0)`; two finite arms → a
> controlled angle of `inf`) with no diagnostic, where the pre-2b compiler declined
> loudly; the safe state is a measured one-line change costing 2 fixtures and 0
> goldens, so the owner's pending three-way ruling should precede the commit, not
> follow it.**

> **B1 — F-11, runtime angle arms (CONFIRMED-MISCOMPILE, reachable from plain C).**
> *Reproducers* (the reviewer's own, independent of round 2's):
> `clearance2b/p3/r01_rt_pi_sel.c` (A=π, B=1e16 as `volatile double`),
> `r02_rt_ovf_sel.c` (±8.98846567431158e307), `r03_rt_nan_sel.c` (a run-time NaN
> arm), `r04_rt_rz_pi_sel.c` (the **Rz** stem), `r05_rt_ovf_mul_meas_sel.c`
> (mul-derived base × `sgt` × overflow), and `clearance2b/rt/t_param_sel.c`
> (function parameters, no `volatile`). Each: NEW **rc=0**, strict stage-2b clean,
> links and runs; ORACLE **rc=1** `rotation angle under quantum control`.
> *Emitted (r01)*: `cqrt_ry_i32(h1, 0x1.1c37937e08p+53)` then
> `cqrt_ry_i32_controlled(h2, h1, -0x1.1c37937e07ffep+53)` ⇒ true-arm angle
> **4.0 rad** for a source that wrote `Ry(π)`. *Emitted (r02)*:
> `cqrt_ry_i32_controlled(h2, h1, inf)`.
> *Why it is wrong in physics terms*: the by-difference identity
> `R(A) = R(B)·R(A−B)` is exact over the reals; the device composes `B + fl(A−B)`,
> and `δ = A − (B + fl(A−B))` is unbounded in absolute radians. On this input the
> emitted gate is a different rotation, and on `r02` it is not a rotation the ABI
> can denote at all.

*There were no other blockers*: 0 CRASH, 0 nondeterminism, 0 `libgmalloc` aborts
over 71 subjects, 0 dirty frees, 0 use-after-frees, and every accepted probe with
a compilable twin byte-identical to it on both binaries.

### THE FACT THAT DECIDED IT — the twin oracle does not exist for this class

Neither review round recorded this, and it removes the strongest argument the
round-2 disposition rested on. **"It is the same arithmetic the manual
by-difference C twin performs" is true of the ARITHMETIC and false of any PROGRAM
CQ will compile.** The natural twin `r = R(r,B); if (c) r = R(r, A−B);` with
run-time arms **DECLINES `control flow under quantum control` on BOTH binaries** —
measured five ways (`r01_twn`, `r06` with the `fsub` hoisted before the branch,
`r07_twn` even at δ = 0, `rt/t_param_twin`, `c30/c31_twn`) — because `clang -O1`
sinks the `fsub` into the arm block and `inPlaceRotationArmTheta` refuses a stray
op there. The only compilable "twin" is `tools/angle_select_twin_matrix.py`'s
`args` cells, which take the difference in as a **parameter** and therefore
perform no subtraction at all (the tool's own generator says so). **So the
residual was reachable ONLY through 2b; it was not inherited from a shape the
compiler already accepted.** (Clearance observation 1.)

### THE DECISION (orchestrator, on that verdict)

**Ship option (2): the angle-select accept narrows to CONSTANT arms** — both arms
`ConstantFP`. A non-constant arm (a parameter, a load, a call result, an `fpext`
of a `float`, a run-time `fsub`) returns `NotApplicable` from S1, so the
pre-existing `rotation angle` decline fires. **No new diagnostic string, and no
warning.**

**The reason, stated as it is written into the code and the docs:** the
by-difference identity is exact over the reals, but for RUN-TIME arms the compiler
**SYNTHESIZES an `fsub` the source never wrote**, and (i) `|δ| ≤ ½ ulp(A−B)` is
unbounded in absolute radians (π/1e16 → 4.0 rad), (ii) two finite arms can produce
a non-finite gate angle. NEITHER is fenceable at compile time, the pre-2b binary
declined the shape loudly, AND the manual by-difference twin with run-time arms
declines on both binaries — so the residual was reachable only through 2b. Prime
Directive: **a disproven precondition declines.** Widening back is the owner's
call and is one line; options (1) and (3) stay on the desk.

### THE MEASURED COST — the whole change, in numbers

| | |
|---|---|
| code | ONE returned value: `angleSelectArmsAdmissible` clause (2c), `return true` → `return false` (`ArmClassify.cpp`). Everything else in this section is comments, fixtures and docs. |
| clauses (1), (1b), (2a), (2b), (3) | **unchanged** — they still govern the constant case, in the same ORDER |
| accept fixtures whose lowered output changed | **0 of 19** — all 19 constant-arm outputs BYTE-IDENTICAL before/after (saved and diffed) |
| accept fixtures that moved to DECLINE | **2**: `control_angle_select_ry_arg_angles.ll` (REPLACED by `reject_runtime_arms.ll`) and `control_swap_reject_switch_datamux_angle.ll` (kept as an accept by giving it CONSTANT arms 0.9/0.3, with the run-time spelling split into a new decline fixture) |
| existing fixture HEADERS corrected (no assertion, arm or stream change) | **7** — `ry_diamond`, `ry_ne_swapped`, `ry_sgt`, `rz_diamond`, `rz_cond_register` each carried the live sentence *"constant arms are fenced … and runtime arms carry the bound"*; `reject_rounding_pi_1e16.ll` carried *"RUNTIME arms cannot be fenced … the bound is documented rather than checked; that is the same arithmetic the manual twin performs"* (and its own pair, spelled as run-time values, USED TO ACCEPT at 4.0 rad — the fence depended on how the angle was spelled); `control_swap_defer_select_angle.ll`'s round-2 retraction paragraph re-pointed. Each retracted wording is quoted in place rather than deleted |
| new decline fixtures | **4** — `reject_runtime_arms{,_rz}.ll`, `reject_runtime_one_arm.ll`, `control_swap_reject_switch_datamux_angle_runtime.ll` |
| e2e goldens changed | **0** — all 7 slices have CONSTANT arms; `ctest -j6 -R angle` 10/10 against the unmodified goldens, `golden_multiset_audit --all` 280 (7 NEW-FILE / 273 UNCHANGED) |
| twin-matrix cells moved | **16** — every `angle=args` cell, into a new `EXPECTED-DECLINE-RUNTIME-ARMS` verdict class; the other **142 line-for-line identical** |
| corpus | 1427 → **1430** (+4 new, −1 deleted); family 66 → **68**, 19 accept → **18**, 47 decline → **50** |

### WHAT OTHER SET IS COMPUTED OVER THE SAME CLOSURE (the 8h7d.5 F-1/F-3 question)

**This narrows the ACCEPT set only, and it narrows it at a clause that reads
nothing but the two arm `Value*`s.** `angleSelectArmsAdmissible` takes `(A, B)`
and consults no closure, no dominator tree, no loop info and no plan; its result
is used at exactly two sites (S1 and the emitter's step-0 re-ask), both of which
already treated `false` as "decline". So there is no second set computed over the
same closure to widen in step: **S7's rail closure, S8's `CondRails`
intersection, S9's member set and S9's SKIP set are untouched**, and the `Exclude
= T` contract is untouched. Measured, not asserted: the **55**
`control_inplace_ry_*` fixtures are green, every non-run-time-arm angle-select
fixture's disposition AND lowered output is unchanged, and the full 1430 × 2
disposition sweep shows **0 unexplained movers**.

The one place a *reason* rather than a disposition moved is inside the predicate
itself, and it is recorded at each clause: (1) and (1b) now decide only which
REASON is recorded for a class (2c) would refuse anyway, and (2a)'s `CA &&` /
`CB &&` guards are kept so that owner option (1)'s one-line widening cannot
silently unfence the non-finite-arm class along with the run-time one.

### THE OWNER-DESK ITEM, RE-FRAMED

**Shipped: (2), constant arms only.** The three-way item in §9 is kept verbatim
(its "(shipped)" tag on option (1) is the round-2 wording and is now wrong; §9
says so in place). What each remaining option costs from HERE:

* **(1) widen back to run-time arms — ONE line.** `angleSelectArmsAdmissible`
  clause (2c) returns `true` again; the three `reject_runtime_*` fixtures and
  `control_swap_reject_switch_datamux_angle_runtime.ll` flip to accepts; the twin
  matrix's 16 `args` cells leave `EXPECTED-DECLINE-RUNTIME-ARMS`. **It requires a
  ruling that round-to-nearest angle arithmetic AND non-finite angle arithmetic
  are BOTH in the semantic model.** The clearance review's closing note is the
  reason both halves must be named: option (1) is worded as "round-to-nearest
  angle arithmetic is IN the model", which reaches the ROUNDING half and **does
  not reach** `inf`/`NaN` from two finite arms — that is not a rounding of
  anything. A ruling that adopts (1) on its stated reasoning would leave half (A)
  un-ruled.
* **(3) the two-controlled form** `x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A)` — no `fsub`,
  no rounding, no `inf`/`NaN` manufacture, no undef fold, existing symbols only;
  one extra controlled gate + an X pair; twin = two Inc-1 diamonds. **Exact for
  run-time arms too**, so it is the option that reopens the shape rather than
  merely re-accepting it. A PRD §12.3 design change.

### THE CLEARANCE'S NON-BLOCKING OBSERVATIONS — every one recorded

| # | observation | disposition |
|---|---|---|
| **1** | the twin oracle does not exist for the run-time-arm class at all (five measured spellings) | **acted on** — it is the deciding fact above, and it is written into `ArmClassify.cpp` clause (2c), `AngleSelectEmit.h`, the twin matrix's docstring and `reject_runtime_arms.ll`'s header |
| **2** | §9's L4-3 bullet is **wrong** on its data-select half: with NON-ALIASING operands an angle select followed by a 4.4 data select **ACCEPTS** (`x04`), soundly; L4's reproducer aliased and was declined by gate **6**, not gate 5. Its manual twin (`x06`) declines for a BLOCK-LIFETIME reason (bd `hcrg` from the other side) | **corrected in place in §9** — the value-arm half stands, the data-select half is retracted with the measurement |
| **3** | `c09` (a TAPE write) is a SECOND select-accepts / twin-declines cell, distinct from the recorded `_tape` class: the select form emits `cqrt_tape_write_i32(t0, h2)` on a subsequently-measured register (correct), while the C twin declines `tainted argument has continued lineage` because its taped value is a MERGE PHI | recorded — sound, but another place the headline twin witness cannot be posed. §8 worry 3's hole, measured |
| **4** | `c13` is a NEW over-decline (safe): the flagship shape inside a classical `if(k){…}` declines `stale rail record read past a controlled Ry`, because the classical join phi is a user of the pre-gate SSA name, while the manual twin accepts on both binaries | recorded — over-decline, no action; but it means the flagship shape does **not** compile inside a classical `if` |
| **5** | in `control_swap_reject_switch_datamux_angle.ll`, mutating the **4.5 data mux's OWN** mint *and* `_unc` strip to read the rotated rail stays GREEN on all four prefixes, while 2b's own mint/strip pair is RED under the same mutation | recorded **in that fixture's header**; the blind spot belongs to the 4.5 datamux assertions this increment inherited, not to 2b, and closing it is out of scope |
| **6** | §7's header said "1407 is now 1423"; the corpus was 1427 and its itemized sweep partition was stale | **corrected in §7** — 1430, partition **20/20/31/3** re-measured over the full 1430 × 2 sweep |
| **7** | `cq_invert` + 2b does not LINK (`__cq_invert_begin/_end` have no runtime body) — **pre-existing on both binaries**, control `s08` reproduces it with a plain rotation | recorded — Phase 8's, not 2b's |
| **8** | `angleSelectArmsAdmissible` uses the NON-global-skipping `valueCarriesUndef`, so a `double` arm that is a relocatable ADDRESS whose global's initializer contains `undef` is refused as "carries undef" although the address is well defined | **one sentence added at clause (1)** — the disposition is right either way ((1b) refuses the class as a link-time constant), but the recorded REASON is the weaker of the two; left as-is because over-declining is safe |
| **9** | the clause ORDER (2b) before (3) is load-bearing and was pinned by no fixture: `APFloat::compare` on a NaN δ returns `cmpUnordered`, which is `!= cmpGreaterThan` and would ACCEPT | **comment added at (2b)** naming the mechanism, the finding it would re-open (F-2) and the one fixture that reddens on the swap |
| **10** | the reviewer did not run the full `ctest -j6`, and did not run `inplace_twin_matrix.py` (subsumed by its own 1427 × 2 sweep) | noted; the committer owns the full suite (Rule 19 moments 1/2/5) |

### THE STANDING LESSON FROM THIS ROUND

**A fence that is gated on a `dyn_cast` fences only the side you cast to — and
round 2 said exactly that about R1-5 without applying it one level up.** §10's own
closing lesson reads: *"the `else` branch **is** the runtime population, the
comment described one of its two residuals, and the missing one was the worse
one."* It stopped at the comment. The clause was `if (!CA || !CB) return true;`,
so the ENTIRE value fence — undef, non-finite arm, non-finite difference, rounding
— was `ConstantFP`-gated, and every one of those four checks was silently skipped
for a run-time arm. Round 2 wrote the sentence and did not ask what the branch
*did*. **When you find that a comment on an `else` branch is wrong, check what the
`else` branch SKIPS, not only what it says.**

Second, smaller, and worth carrying: **a mitigating argument that names an
arithmetic equivalence must be checked against a compilable program.** "The
manual twin performs the identical `fsub`" survived two review rounds and a
committed accept fixture; it took a reviewer actually *compiling* the twin to find
that the twin does not compile at all.

### WHAT THE CLEARANCE FIX AGENT RAN — counts, and only what was executed

| layer | result |
|---|---|
| the 4 new decline fixtures, BEFORE the code change | **4 / 4 FAIL** (all four lowered, so `RUN: not` failed) — Rule-12 red |
| the same 4, after | **4 / 4 PASS** — green |
| `ctest -R ir-pass-lit` | **PASS**, three times (78.8 s; 74.4 s after the final rebuild; 61.1 s after the fixture-header corrections); `lit ir-pass/test` = **1430 discovered, 1429 passed, 1 expectedly failed**; `ls ir-pass/test/*.ll \| wc -l` = **1430** |
| the 19 constant-arm accept fixtures' lowered output, saved before the rebuild and diffed after | **19 / 19 BYTE-IDENTICAL**; exactly **2** files changed disposition (`ry_arg_angles`, `switch_datamux_angle`), both intended |
| the clearance's 6 plain-C select reproducers (`r01`–`r05`, `t_param_sel`) | before: **6 / 6 ACCEPT (rc=0)**; after: **6 / 6 DECLINE (rc=1)**, and their **stderr is BYTE-IDENTICAL to the recorded pre-2b ORACLE stderr** in all six |
| the 2 twin controls (`r01_rt_pi_twn`, `t_param_twin`) | `control flow under quantum control` before AND after — unmoved, as the clearance measured |
| `ctest -j6 -R 'angle'` | **10 / 10** (7 slices + the 3 `compare_files` twin gates) |
| e2e goldens | `git diff` over all tracked `*.expected.log` **EMPTY**; the 7 untracked 2b goldens **not rewritten** (mtimes unchanged) and matched byte-for-byte by the 10 passing entries |
| `tools/golden_multiset_audit.py --all` | **280 goldens: 7 NEW-FILE, 273 UNCHANGED**, 0 routes collapsed, PASS |
| `tools/angle_select_twin_matrix.py --oracle <pre-2b> --jobs 6` | **158 cells: 102 BOTH-ACCEPT-IDENTICAL, 11 BOTH-DECLINE, 16 DEGENERATE-FOLD, 1 OVER-DECLINE, 12 SUSPICIOUS, 16 EXPECTED-DECLINE-RUNTIME-ARMS; 0 MISMATCH / 0 ORACLE-MOVED / 0 RED-GREEN-MISS / 0 HARNESS-ERROR / 0 stage-2b**. The 16 came from THREE classes (14 BAI, 1 BOTH-DECLINE, 1 SUSPICIOUS), and the **other 142 cells diff line-for-line clean against the clearance's own table** |
| `tools/control_flag_order_check.py` | **1430 files, 394 control flags, 0 violations** (395 → 394: the one deleted accept fixture) |
| semicolon detector + the dead-prefix scan over all **71** family files | **empty / 0 hits** |
| the L6+R2 mutant kit (18 kinds) regenerated from the CURRENT output, 20 accept files | **356 RED, 0 GREEN-ON-MUTANT, 4 N/A** (360 cells; was 372/0/6 over 21 files — the delta is exactly the deleted file's 17 RED + 1 N/A, plus `negangle` moving N/A → RED on the datamux fixture, whose angle is now a constant) |
| the same kit on the rewritten `control_swap_reject_switch_datamux_angle.ll` alone | **18 / 18 RED, 0 GREEN** — strictly stronger than the 13/13 it carried with run-time arms |
| `condrail_consistent` regenerated | **18 RED, 0 GREEN, 2 N/A** (was 19/0/2 — the deleted file) |
| STRICT `free_pairing_check.py` over the 20 accept outputs | **20 files, 41 rail mints of which 41 left allocated, 24 free sites: 24 verified, 0 violations, 0 unproven** — no `--allow-unproven` anywhere |
| whole-corpus disposition sweep, `ir-pass/test/*.ll` × BOTH binaries | **1430 × 2 = 2860 invocations: 20 DECLINE→ACCEPT, 20 message-sharpened, 3 ACCEPT→DECLINE (the pre-existing `ogw2` cells), 704 both-decline identical, 683 both-accept — 0 unexplained movers** |
| `cmake --build build --target cq-opt-equivalence-full` | **compared 1430 fixtures, 0 mismatch(es)** (the accept predicate changed — Rule 19 moment 5) |

**NOT run by this agent:** the full `ctest -j6` — the orchestrator owns it as
committer (Rule 19 moments 1/2/5).
