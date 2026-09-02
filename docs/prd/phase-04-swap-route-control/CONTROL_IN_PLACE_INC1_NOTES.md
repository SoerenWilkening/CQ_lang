# Control-in-place Inc 0 + Inc 1 — implementation notes, walker audit, goldens

> Companion to `control-in-place-PRD.md`. Covers bd `test_C_libtooling-drbq.1`
> (Inc 0, the runtime/ABI surface) and `.2` (Inc 1, the flat in-place Ry arm).
> **Reviewers start here.** Written 2026-09-02.

---

## 0. What shipped, in one paragraph

`if (q == 5) r = cq_theta(r, .9)` — a tainted-control **Ry** on a register whose
**physical wire** is disjoint from every condition wire — now lowers. The whole
emitted stream per arm is

```
cq_template_icmp_eq_i32_hl(q, 5)          ; flag mint, byte-identical to the phase path
[cqrt_x(f)]  cqrt_ry_i32_controlled(f, r, 0.9)  [cqrt_x(f)]
cq_template_icmp_eq_i32_hl_unc(f, q, 5)   ; flag strip, byte-identical
cqrt_free(f)
```

No `cqrt_alloc`, no `cqrt_cswap`, no work rail, no reverse-play. That is forced,
not chosen: the route's premise is that the arm gate is a no-op on the inactive
`|0⟩` work rail, which is true for `Rz = diag(1, e^{iθ})` and **false** for
`Ry(θ)|0⟩ = cos|0⟩ + sin|1⟩` (PRD §2). Everything outside PRD §4 R1–R7 declines
loudly.

---

## 1. Files changed

### Increment 0 — surface

| File | Change |
|---|---|
| `runtime/cq_runtime.h` | New `void cqrt_ry_<W>_controlled(int32_t, int32_t, double)` block, 9 widths, beside the controlled-Rz block. The old comment "There is NO plain `cqrt_ry_<W>_controlled` twin" is rewritten (it now says there IS one, minted only by the in-place rotation-arm emitter) and the `_controlled_inv` block's comment says explicitly that it is a **separate, older** family (npu.6 MUX-EXCH prep-uncompute, 7 widths) that the forward gate's adjoint never resolves to. |
| `runtime/cq_runtime.c` | The 9 bodies, trace `"cqrt_ry_<W>_controlled(h%d, h%d, %a)\n"`. |
| `runtime/test_trace.c` + `.expected.log` | One `cqrt_ry_<W>_controlled` **and** one `cqrt_rz_<W>_controlled` per width, 9 each, appended last so every existing handle id is unchanged. Both stems, deliberately — see §5. |
| `ir-pass/include/ControlledSymbols.h`, `.cpp` | `controlledRotationFn` gains a `RotStem { Ry, Rz }` parameter (defaulted to `Rz`, so the one existing call site is unchanged). `(Ry, inverse=true)` returns a **null** callee: that spelling names a different family and only 7 widths exist. The width gate moved from `Wd.llvmWidthType` to the new `abiWidthHasControlledRotation` (a tightening on a path no caller reaches today). |
| `ir-pass/include/OpcodeSupport.h`, `src/OpcodeSupport.cpp` | New `abiWidthHasControlledRotation(StringRef)` — the 9 declared widths. Asked by **both** the detection-time fence and the minter, so accept and emit cannot drift. |
| `ir-pass/src/EmitInverse.cpp` | `isInverseEmittable` + `emitInverseCall` admit `cqrt_{ry,rz}_<W>_controlled(f, h, θ)`: VOID, arity **exactly 3**, inverted as the SAME symbol with `CreateFNeg(angle)`, control threaded verbatim through arg 0, a `CurHandle` relabel applied to **arg 1**. `ends_with("_controlled")`, never `contains`, so `_controlled_inv` stays out. |
| `tools/free_pairing_check.py` | `classify()` models `cqrt_ry_<W>_controlled` as `Effect("gate", reads=(0,), writes=(1,), adjoint_of="negate-arg2", controls=(0,))` and `cqrt_rz_<W>_controlled` as the same **plus `diagonal=True`**. Both leave the "unmodelled reserve" list; the header count is re-measured (163 of 182 modelled, was 145 of 173). |
| `tools/free_pairing_check_test.py` | 2 new positives (`ctl-ry-negated-angle-pair`, `ctl-rz-unpaired-is-diagonal`), 4 new named mutants (angle-sign, wrong-flag, adjoint-deleted, `ry`-unpaired-is-not-diagonal), 1 new record mutant (`ctl-ry-recorded-rail` → `R1-recorded-rotated-rail`) and 1 new record positive control (`ctl-rz-recorded-diagonal`). |

`runtime/cq_link_smoke.c` and `runtime/CMakeLists.txt` needed **no** change:
`cq_link_smoke.c` is generated from the YAML `cq_template_*` rows only, and the
hand-written `cqrt_*` half is covered by `runtime_core_abi_link` /
`core_abi_link_check.py`, which extracts declarations from the header by regex
and diffs them against `nm` on the archive. Both gates pass with the 9 new
symbols.

### Increment 1 — the flat in-place Ry arm

| File | Change |
|---|---|
| `ir-pass/include/ControlPlan.h` | `ArmClass` gains `InPlaceRotation` (a third class, neither phase nor value — Rule 7). |
| `ir-pass/include/TaintPropagation.h` | ONE new `TaintSet` member: `ControlledRotations` (theta → flag, the hoist-and-defer record), documented at length in place. Inc 1 also added `ControlledRotationRails` (the frozen registers); the round-1 review REMOVED it — see finding L. Its slot now carries a ⚠ note saying why there is no such member. |
| `ir-pass/src/ArmClassify.cpp` | New TU-local `railWireClosure` + `forwardRailHop` (the ONE rail closure R4 and R6 both read — `WireDir::BackwardOnly` for the condition side, `BothWays` for the base; **finding J** rewrote this from the backward-only `railRootClosure` Inc 1 first shipped), `cannotFollowGate` (R6's position obligation for an alias HOP), the R7 loop clause moved in front of R6 (finding J), `rotationAngleIsTainted` (one spelling, now also used by `taintedAngleGate`'s lambda), `inPlaceRotationArmTheta` (R1's shape half), and the R1–R7 clause inside `classifyArms`. Plus `SawRotationArm` read at **all four** other accept sites (see §4, finding B). |
| `ir-pass/src/SwapRouteEmit.cpp` | `ArmInfo` lifted out of `emitRegion` so the new emitter can take it; `emitInPlaceRotationRegion` (the hoist-and-defer recipe); the dispatch in `emitRegion` before the phase-stream collection. |
| `ir-pass/src/RotationLowering.cpp` | The theta loop mints `cqrt_ry_<W>_controlled` for a `ControlledRotations` member (recording NOTHING — the freeze is structural, finding L) and bails loudly on a classical-operand controlled theta or an unsupported width. The M-A live-record guard's structural re-check admits the controlled spelling and reads its wire from **arg 1**. |
| `ir-pass/src/ControlDetect.cpp` | In-loop scope fence **part 3**: an `InPlaceRotation` arm inside a loop declines `control flow inside a loop body` (Inc 3 owns it). **Finding J** demoted it to a BACKSTOP — `classifyArms` now fires the same string first, because R6's position predicates are flat — and its comment says so. |
| `ir-pass/src/ChainWalk.cpp` | `isInPlaceGateOn` admits `cqrt_{ry,rz}_<W>_controlled` with the handle at arg 1 (VOID + arity 3). `preservesBasisUnderRecord`'s `cqrt_rz_` prefix is documented as covering the controlled twin **on purpose**, and (round-1 review, L5 §6) now carries the bd 1fim VOID+arity-3 fence on the `_controlled` spelling, for symmetry with `isInPlaceGateOn`. |
| `ir-pass/src/Uncomputation.cpp` | The freeze subtracted at terminal selection and in the interior partition — via `railCarriesControlledRotation(H)` (finding L), not a recorded set. |
| `ir-pass/src/DagTraversal.cpp` | The freeze subtracted in the DAG closure scan, via `railCarriesControlledRotation(R)` (finding L). This is the site finding A's measured defect went through, and the site finding L's did too. |
| `ir-pass/test/control_inplace_ry_*.ll` | **53** fixtures (17 accept, 35 decline, 1 warn) — 28 as first shipped, +9 from finding J, **+16 from the round-1 Rule-13 review** (findings K/L/M and the L1/L6 coverage gaps). Plus `control_swap_eqfold_classical_between.ll` in the `control_swap_*` family (finding M's crash pin). |
| `tests/e2e/slice_control_inplace_ry{,_negated,_derived_base}.c` + goldens + `tests/e2e/CMakeLists.txt` | **3** strict-stage-2b e2e slices (the third added by the round-1 review, finding L). |
| `CLAUDE.md`, `ROADMAP.md` | The Correctness-Risk sentence and the three frozen-designate lists. |

---

## 2. Exact new diagnostic strings

All go through `diagnoseUnderControl`, so the emitted text is
`cq controlled lowering: <What> under quantum control`, `!dbg`-anchored,
`DS_Error`, `opt` exits non-zero.

| `What` | Fence | Mirrored by |
|---|---|---|
| `rotation arm on a condition wire` | R4 — the rail closure of the rotated base intersects the condition's | `control_inplace_ry_reject_inplace_alias_base.ll` (the TRUE POSITIVE, + its M-C premise witness `..._inplace_alias_witness.ll`), `..._reject_derived_base.ll` and `..._reject_derived_base_sub.ll` (both deliberate OVER-declines) |
| `stale rail record read past a controlled Ry` | R6 — a user of any member of the base's RAIL ALIAS CLOSURE that is not provably before the region (an alias HOP: that cannot follow it). Widened from the base's DIRECT users by finding J, and again to cross φ/select/freeze FORWARD by finding K | `control_inplace_ry_reject_stale_measure.ll`, `..._stale_ret.ll`, `..._stale_diag_alias_{forward,backward,ret,two_hop}.ll`, `..._stale_chained_theta.ll`, and finding K's seven `..._reject_lifted_phi_{measure,ret,tape,clone_arg,invert,switch,chained_theta}.ll` |
| `rotation arm shares the condition flag` | R7 — the ziov `ShareCondFlag` path | `control_inplace_ry_reject_share_cond_flag.ll` |
| `controlled rotation width` | the ABI-width fence, at detection time | (no fixture — see §6, finding E) |

Two new `diagnoseUnsupported` strings in `RotationLowering` (spelled
`cq rotation lowering: <What>`), both **structurally unreachable** on a
plan-consistent module and kept as loud last resorts rather than a silent
fall-through to the uncontrolled gate:

* `controlled theta operand` — a `ControlledRotations` entry on a
  classical-operand theta (controlled state prep is Inc 4).
* `controlled theta suffix/width` — the minter returned null after detection
  gated on the same predicate.

**Reused, unchanged strings** (so no negative fixture churned): `rotation angle`
(R2), `mixed phase/value arm` (R3 homogeneity), `control flow` (base mismatch,
untainted base, AnglePhi, missing anchor), `control flow inside a loop body`
(R7 loop).

---

## 3. The walker audit (PRD §6, mandatory)

Every name-test on `cqrt_ry_` / `cqrt_rz_` / `_controlled` / `cq_theta_` in
`ir-pass/src`, `ir-pass/include`, `tools/free_pairing_check.py` and
`tools/loop_twin_matrix.py`. **33 name-test sites**, of which **17 are
pre-`lowerRotations`** (they see `@cq_theta_`, which the hoist-and-defer recipe
deliberately keeps alive) and **16 are post-`lowerRotations`**. **Three were
extended**; the rest are listed with the reason they are correct as they stand.

### 3a. PRE-`lowerRotations` — all correct unchanged, by construction

The hoist moves the `cq_theta` **call**; it does not lower it. Every walker below
therefore still sees a `@cq_theta_` with the wire at arg 0 where one **will**
fire, i.e. it over-approximates a CONTROLLED gate as UNCONDITIONAL — the safe
direction for every staleness fence.

| file:line | what | verdict |
|---|---|---|
| `WireWalk.cpp:76,77,108,147,410,411,468` | the shared forward/backward wire walk | unchanged — sees the theta |
| `ArmClassify.cpp:61,723` | `isThetaCall`, the compare→branch positional scan | unchanged |
| `ArmClassify.cpp` `railWireClosure` / `forwardRailHop` | R4's + R6's rail alias closure (finding J) | PRE-lowering by construction, and that is what makes it correct: it keys on the `@cq_phi_`/`@cq_theta_` spelling with the wire at ARG 0, which is exactly the IR the hoist-and-defer recipe keeps alive. It never sees `cqrt_ry_<W>_controlled` and must not — the closure is an ANALYSIS of the source's wires, computed before any region is emitted. |
| `ArmHomogeneity.cpp:39`, `RegionTreeDetect.cpp:41,368`, `SwitchArmProve.cpp:48`, `SwitchClassify.cpp:49`, `SelectClassify.cpp:46,703` | the other classifiers' `isThetaCall` / theta scans | unchanged (those shapes decline for this class anyway) |
| `PredMuxFlatten.cpp:632` | PredMux's rotation test | unchanged — PredMux runs before detection |
| `LoopLowering.cpp:690` | `collectRailGates`' gate test | unchanged **and load-bearing for Inc 3**: it keys on `cq_theta_` at arg 0. In-loop rotation arms decline in Inc 1 precisely so this is not silently wrong. |
| `RotationLowering.cpp:205`, `WidthDispatch.cpp:110,546-551` | suffix parsing / the intrinsic name table | unchanged |

### 3b. POST-`lowerRotations` — the three that were extended

| file:line | what it decides | why it had to change |
|---|---|---|
| `ChainWalk.cpp:119-129` (`isInPlaceGateOn`) | which gates belong to a handle's DAG link | **EXTENDED.** Added BEFORE the generic `_controlled` bail, with VOID + arity-3 + `argOperand(1)==H`; `railOf` is derived from it, so without the change the gate would be attributed to the FLAG at arg 0 (the bd `uow0` mis-attribution, one family over). **THE STATED CONSUMER WAS WRONG AND IS CORRECTED (round-1 review, L5 §5):** the shipped comment named `DagTraversal`'s `D.Calls` as "the sharp end", but with the freeze working `DagTraversal`'s freeze cut fires BEFORE its users loop, so that path is unreachable. MEASURED by deleting the row and re-running the 53-fixture family: **exactly one** reddens, `..._warn_live_record.ll` — the freeze fixtures stay green because a gate this predicate cannot see becomes an UNRECOGNIZED consumer, which marks the DAG `NotClosed` and leaks it, a SECOND route to the same Rule-6-safe outcome. The row's real consumers are `railCarriesControlledRotation` (the freeze itself is derived from it), `Uncomputation`'s moved-anchor scan, `ChainWalk::isInteriorConsumer` and `warnLiveRecordRotations`. |
| `EmitInverse.cpp:47-72, 192-222` | which calls have an adjoint recipe | **EXTENDED** (Inc 0). Same symbol, negated angle, control threaded through arg 0, `CurHandle` → arg 1. |
| `RotationLowering.cpp:1409-1424` (M-A `warnLiveRecordRotations`) | which recorded user rotations get the live-record warning | **EXTENDED.** Its structural re-check was `arg_size()==2 && starts_with("cqrt_ry_")`, so it skipped every controlled Ry silently; reading arg 0 instead would have run the whole guard against the FLAG. Both spellings admitted, each reading its own wire slot. Pinned by `control_inplace_ry_warn_live_record.ll` (measured: the module lowered silently before). |

### 3c. POST-`lowerRotations` — examined and deliberately NOT changed

| file:line | what | decision |
|---|---|---|
| `ChainWalk.cpp:~300` (`preservesBasisUnderRecord`) | is this gate a basis permutation (⇒ the rail is not frozen under the bd 261j(a) record rule)? | `starts_with("cqrt_rz_")` **already** covers `cqrt_rz_<W>_controlled` and that is CORRECT (diagonal on both branches of the flag). `cqrt_ry_<W>_controlled` is deliberately not matched — a rail carrying one stays frozen, the Rule-6 direction. Comment added so the coverage is on purpose rather than incidental. **AMENDED by the round-1 review (L5 §6):** `true` here is the UNSAFE direction (basis-preserving ⇒ not frozen ⇒ FREED) and a bare prefix was a proxy for the property, not the property — the exact bd 1fim shape. The `_controlled` spelling now carries `isVoidTy() && arg_size()==3`. It was not a live hole (membership in `D.Calls` goes through `isInPlaceGateOn`, which fences both axes), but resting on a DERIVATION from another predicate's fence is what bd 1fim showed goes stale. |
| `Uncomputation.cpp:597` (`preservesBorrowedParent`) | is this user of a borrowed parent PROVEN read-only? | Left refusing every `_controlled` rotation. For Ry that is required (it mutates); for the controlled Rz it is an over-decline that costs only a positional test. Refusing is the conservative branch. |
| `Uncomputation.cpp:110` (`isDataProducer`), `ChainWalk.cpp:210` (`isTemplateProducer`) | is this a fresh-rail producer? | A controlled rotation is VOID, so it is not a producer at any spelling. Unchanged. |
| `ChainWalk.cpp:59-64, 92` (`isAbiQramStore`) | the frozen QRAM store shape | Gated on `starts_with("cqrt_qram_store_")` before any rotation could reach it. Unchanged. |
| `ChainWalk.cpp:437` (`isCopyOutSink`), `BreakReversePlay.cpp:175`, `EmitInverse.cpp:111,157,263,283`, `Uncomputation.cpp:110`, `TemplateName.cpp:92,123` | `cqrt_copy_` / `cq_template_` families | A rotation never matches those prefixes. Unchanged. |
| `RotationLowering.cpp:681` (`isTeardownUse`) | is this rotation the spine's adjoint or a user gate? | The `starts_with("cqrt_ry_")` prefix **already** matches the controlled spelling, and the minted call is inserted into `taint.UserChainedRotations`, so `isRecordedUserRotation` answers "user gate". Correct unchanged. |
| `RotationLowering.cpp:1208` | the observing-sink walk's "a USER rotation observes nothing" | Prefix already matches; a controlled rotation is not an observing sink. Correct unchanged. |
| `RotationLowering.cpp:1042,1046` (`isQramStoreGate`) | Shadow-store arg positions | Prefix-gated on `cqrt_qram_store_`. Unchanged. |
| `ArithLowering.cpp:831` | the M-C late-reassignment owner-set subtraction | Keys on the **template call site**, not on the parent rail, so `ControlledRotationRails` does not belong there. A late M-C conversion on a frozen register still only changes the FORWARD program (out-of-place template → in-place `addc`), which the freeze is not about. Left alone; recorded because it is the one owner-set site that does **not** get the new member. |
| `WidthDispatch.cpp:351,367,393,406`, `ControlledSymbols.cpp:125,146,168` | symbol MINTERS, not tests | n/a |
| `tools/free_pairing_check.py:1803` (rule R1) | is the freed rail carrying a non-diagonal rotation AND recorded onto a kept carrier? | `w.sym.startswith("cqrt_ry_")` over the rail's WRITE history — and the write lands on the rail only because `classify()` puts `writes=(1,)` on the controlled twin. Correct by construction; pinned by the new `ctl-ry-recorded-rail` mutant and its `ctl-rz-recorded-diagonal` control. |
| `tools/loop_twin_matrix.py:111,126,144,159` | generates **C source** containing `cq_theta` | Not a consumer of lowered symbols. **Inc 3 must add the Ry-arm shape as an axis FIRST** (PRD §7). Unchanged for Inc 1, where in-loop rotation arms decline. |

### 3d. Sites the shipped §3 table OMITTED (round-1 review, lens L5 §4)

L5 re-enumerated the surface independently and found **seven** post-`lowerRotations`
sites §3b/§3c do not list, plus the naming error corrected above. None is a
defect; all seven are recorded here because "the audit enumerated the sites it
listed" is not the same claim as "the audit enumerated the sites".

| file:line | what | verdict |
|---|---|---|
| `Uncomputation.cpp:~510` | moved-anchor clause-(d) scan; `isInPlaceGateOn(CI, Op)` over every non-DAG call | **the genuinely reachable consumer of the ChainWalk extension** (together with `isInteriorConsumer`). Correct *because of* the extension — and unlisted, so nobody argued it. The shipped in-source justification named `DagTraversal` instead, which the freeze makes unreachable; corrected in §3b and in the source. |
| `ChainWalk.cpp:~658` (`isInteriorConsumer`) | `!isInPlaceGateOn(CI,Handle) && !DischargedFlagGates` → forward-consumer count | derived from the extension; correct; unlisted |
| `ChainWalk.cpp:~484` (`isTerminalHandle`) | derived from the extension | correct; unlisted (§3b listed `railOf` as derived but not this) |
| `ArithLowering.cpp:~481` (`priorUseIsSettled`, arms (a)+(c)) | (a) `isInPlaceGateOn(CI,P)` settles a WRITE of `P`; (c) `void && cqrt_ && !qram_store` settles a READ of `P` in the control slot | correct unchanged. §3c listed only `ArithLowering.cpp:831`. |
| `LiteralIntegrity.cpp:~129` (`isEmittedRuntimeCallee`) + `:~248` (the arg loop) | the undef/poison LITERAL-slot count | **correct unchanged, and it answers a question §3 never asked: the ANGLE slot IS counted.** The scan is name-agnostic (`cqrt_` prefix) and iterates `CB->args()`, so arg 2 of `cqrt_ry_<W>_controlled` is a counted literal slot. The comment's enumeration ("`cqrt_ry/rz_<W>(handle, angle)`") is now incomplete; its CLAIM ("at most ONE non-handle operand") still holds. |
| `BreakReversePlay.cpp:~165` (`isInPlaceRailGate`) | `cqrt_xorc_`/`cqrt_addc_` + arity 2 | does not match a rotation; in-loop declines anyway. §3c listed only `:175`. |
| `RotationLowering.cpp:~1195` | `cqrt_tape_write_` CTRL-slot hop, arity-gated | unaffected; unlisted |

Two further L5 observations, recorded rather than acted on:

* **`RotationLowering.cpp:~1208`** (the observing-sink walk's "a user rotation
  observes nothing") now also matches the CONTROLLED spelling, where arg 0 is a
  read of a DIFFERENT rail. Two rows away, the `cqrt_tape_write_<W>_controlled`
  CTRL slot and the `cqrt_cnot`/`cqrt_toffoli` control slots ARE modelled as HOPS
  to the target. The asymmetry is unargued; the consequence today is at most a
  MISSING WARNING (`warnLiveRecordRotations` is `DS_Warning` since bd `lyyf`),
  never a miscompile, and §3c's verdict is right for the TARGET slot. Left as a
  follow-on rather than widened without a Rule-13 round.
* **Detection and mint derive the ABI width from two different EXPRESSIONS.**
  `ArmClassify` asks `abiWidthHasControlledRotation(abiWidthFromType(T->getType()))`;
  `RotationLowering` asks `wd.abiWidthFor(suffixFromName(Theta,"cq_theta_"))`. The
  §1 claim that the predicate is "asked by BOTH … so accept and emit cannot
  drift" is true of the PREDICATE and not of its ARGUMENT. They agree for every
  `CQ.h` spelling checked (`si32`, `f80`, `i1`, `c`, `sl`, `ull`, `f16`), so this
  is latent, not live; if they ever diverge the mint hits the loud
  `controlled theta suffix/width` — but AFTER the hoist, the mint, the strip and
  the flatten, i.e. a decline after mutation, which is the thing the
  detection-time fence exists to prevent. Left as a follow-on.


---

## 4. Findings made while building this increment

### A. (FIXED) The whole-DAG uncompute emitted a use-after-free of the control flag, then a dirty free

MEASURED, not hypothesized. For

```c
int q = cq_theta(0,.5); int r = cq_theta(0,.3);
if (q > 5) r = cq_theta(r, .9);
int s = r + 1;                 /* reads the merge (post-region) name */
return cq_measure(q);          /* r and s dead */
```

the first working build emitted (verbatim):

```
cq_template_icmp_sgt_i32_hl_unc(%f, %h, 5)
cqrt_free(%f)                            <-- the flag is reclaimed here
cqrt_addc_i32(%h1, 1)
cqrt_addc_i32(%h1, -1)
cqrt_ry_i32_controlled(%f, %h1, -0.9)    <-- USE AFTER FREE
cqrt_ry_i32(%h1, -0.3)
cqrt_free(%h1)                           <-- and then a DIRTY free
```

`opt` exit 0, `opt -verify` clean. A `cqrt_free` is a hardware reset, so the
adjoint's control is `|0⟩` and the adjoint never fires: the register is still
carrying `Ry(.9)` entangled with `q` when the spine frees it — a hidden
measurement (Rules 6/8). Stage 2b **did** catch it
(`VIOLATION F2-use-after-free`, then `A-not-reducible`), which is how it was
found; a second gate catching the pass's mistake is not the pass being right.

**Root cause, stated generally:** a controlled gate's adjoint needs its control,
and the flag lives and dies inside the region's own stream. The whole-DAG spine
runs LAST and places a rail's reversal after that rail's final user, so for any
register with a post-region consumer that point is after `cqrt_free(flag)`.

**Fix:** `TaintSet::ControlledRotationRails` — the register a controlled rotation
fired on is FROZEN: never reverse-played, never freed by the spine (Rule 6's
documented fallback, "left allocated"). Subtracted at **both** spine sites; the
measured defect went through the `DagTraversal` **closure** site (the register is
reached as a DAG ancestor via its in-place `addc`), so subtracting only at
terminal selection would not have been enough.

**Frozen uniformly, not conditionally.** With no post-region user the reversal
happens to land before the flag free and would be sound (`t_dead_base` probe);
that is a property of where `dagInsertPoint` puts things, not an invariant anyone
proved. Cost: one leaked rail on a DEAD register — a measured or escaped one was
never freed anyway. Pinned by `control_inplace_ry_dead_base_frozen.ll` and
`control_inplace_ry_dead_base_late_use_frozen.ll`.

**Re-opening condition:** if a later increment wants the register reversed, the
right fix is a positional one — constrain the reversal point to precede the flag
free, and leak only when it cannot — not a relaxation of the freeze.

### B. (FIXED) Homogeneity was one-directional

The rotation clause's own `SawPhaseArm || SawValueArm` test only fires when the
rotation arm is processed **second**. A rotation arm **first**, followed by a
phase / value / eq-fold arm, is the same mixture. Measured:
`if(c) r=cq_theta(r,·) else r=cq_phi(r,·)` did decline — but on **R6's**
stale-record string, by luck, because the sibling arm's `cq_phi` is a
post-region user of the base. Luck is not a fence. `SawRotationArm` is now read
at all four other accept sites; the pair
`control_inplace_ry_reject_mixed_ifelse{,_rz_first}.ll` pins both orders.

The same round also made R6 skip users that live in the region's **own** arm
blocks, so the mixed case declines on the mixture rather than on a
stale-record message that mislabels it.

### C. (recorded, not a defect) The R1 fan-out clause is unreachable in valid IR

`T->hasOneUse() && T->user_back() == MergePhi` cannot be violated by a
well-formed module with a one-instruction arm: a second user must live either in
the arm block (then it is a stray op, which the same recognizer already refuses —
`control_inplace_ry_reject_stray_op.ll`) or after it, where the arm does not
dominate the merge and the module fails `opt -verify`. Kept as defence in depth;
the stray-op fixture's header records the argument so nobody writes an
unwritable fixture for it.

### D. (recorded) `clang -O1` makes two PRD shapes unreachable from their C spelling

* **S2 with `==`** (`if (q == 5) q = cq_theta(q,.9)`): `-O1` const-folds the arm's
  `q` to the literal `5`, so the arm theta has a CLASSICAL arg-0 and reads as
  state prep. The `>` spelling is the reachable one and declines on the
  pre-existing stale-condition wire guard.
* **The two-arm if/else**: `-O1` merges both `cq_theta` calls into ONE call with
  a `select` on the ANGLE, which declines `rotation angle under quantum control`
  and never reaches this classifier. `control_inplace_ry_ifelse.ll` is therefore
  **hand-constructed IR**, and its header says so.

### E. (recorded) The `controlled rotation width` fence has no fixture

`CQ.h` exposes no `cq_theta` spelling at a width outside the 9
(`i80`/`i128`/`f128` are intermediate-only), and a hand-written
`@cq_theta_<bogus>` is refused by the collection-time prototype validation before
detection runs. The fence is detect-before-mutate defence in depth and is
mechanically tied to the minter through the one shared
`abiWidthHasControlledRotation` predicate. Recorded rather than faked.

### F. (recorded) The `EmitInverse` controlled-rotation adjoint has NO reachable caller at HEAD

The task suggested exercising it through a Phase-6 clone-on-taint Bennett wrap.
That is **structurally impossible**: a specialization clone body is ROTATION-FREE
by construction (`SpecializeReject::scanBody` rejects every `cq_theta`/`cq_phi`;
see `spec_clone_theta_free.ll`). The 7.4 break reverse-play only runs on claimed
loop bodies, where this arm class declines. And finding A's freeze closes the
top-level whole-DAG path deliberately.

So the Inc-0 adjoint is a **reserve for Inc 2/3** (`Rz` regions inside the rolled
loop, where the reverse-play does run) and is exercised today only by
construction review plus the two freeze fixtures, which pin that the path it
would have taken is closed. Stated rather than papered over.

> **⚠ THIS FINDING WAS FALSE AS SHIPPED, AND WAS RE-ESTABLISHED BY MEASUREMENT —
> see finding L.** Its third leg ("finding A's freeze closes the top-level
> whole-DAG path") did not hold: the freeze silently did not apply to a DERIVED
> base, and the whole-DAG spine reached `EmitInverse`'s controlled-rotation
> adjoint through exactly that path — which is how the defect manifests. Finding
> F was the STATED GROUND for shipping a new adjoint recipe with no fixture, and
> the recipe was live on the one path that was also wrong. After the structural
> freeze the claim is true again, and it is now a CHECKED claim with its checks
> named (five `CHECK-NOT: double -9.000000e-01` fixtures, `emitRz`'s single
> `controlled=false` caller, rotation-free clone bodies, and the in-loop
> decline) rather than an argument.
> **The general lesson: an unreachability claim about a code path is a
> MEASUREMENT, and it goes stale the moment any of its legs moves.**

### G. (deviation, recorded) `ControlledRotations` lives on `TaintSet`, not `ControlPlan`

PRD §6 suggests `plan.ControlledBy`. There is **not one `ControlPlan` per
compilation**: `TaintPropagation::detectAndLowerOnwardControl` (the yn71
onward-control fixpoint) builds a LOCAL `plan2`, emits its regions and discards
it, while `lowerRotations` is later handed the FIRST plan. A `ControlPlan`-hosted
map would silently lose an onward region's entries and lower its hoisted theta
**unconditionally** — an unconditional Ry where a controlled one was meant.
`TaintSet` is the one object every emitter and `lowerRotations` share.

### H. (deviation, recorded) R4 is stricter than PRD §3's letter

PRD §3 says an out-of-place derived value (`a = q + 1` into a fresh rail) is a
different wire and the strip stays valid. True — but **whether an `add`/`sub`/
`xor` lowers in place is decided by the M-C fence in `lowerOps`, which runs long
after detection**, so nothing at classification time can know. `railRootClosure`
therefore admits both roots for those three opcodes and the region declines.
Everything else (mul, casts, compares, template producers) mints a fresh rail
unconditionally and correctly stops the walk. The over-decline is pinned and
explained in `control_inplace_ry_reject_derived_base.ll`.

### I. (pre-existing, reported, NOT fixed) `condWireDisposition` is what actually rejects S2/S8

Three of the PRD's named negatives (the condition register, the SSA alias, the
diagonal alias) never reach R4: the pre-existing stale-condition wire guard
declines them first, on `condition predates a non-diagonal gate`. That is
correct and safe — but it means **R4 has exactly one fixture that exercises it**
(`..._reject_derived_base.ll`). If a future change narrows
`condWireDisposition`, R4 becomes the only fence for those shapes and its
coverage is thin. Recorded as a standing obligation for Inc 2, which widens the
same classifier to `cq_phi`.

### J. (FIXED — a CONFIRMED silent miscompile in this increment) R6 was written over the CHAIN when the object it protects is the RAIL

**The finding to carry out of Inc 1, above any of the others.** R6 shipped
ranging over the **direct users of the SSA value `R`**. A diagonal alias ONE HOP
out evaded it in **both** directions, and the emitted circuit measured the
post-Ry register where the source names the pre-Ry record: a wrong VALUE,
`opt` exit 0, `opt -verify` clean, stage-2b (`free_pairing_check.py`) clean, and
green against all 28 committed fixtures of the class.

**Probe 1 — FORWARD alias** (`p1_diag_alias_after.c`):

```c
int q = cq_theta(0,.7); int r = cq_theta(0,.3);
int mark = cq_phi(r, .1);
if (q == 5) r = cq_theta(r, .9);
return cq_measure(mark) + cq_measure(r) + cq_measure(q);
```

MEASURED BEFORE (`build/ir-pass/cq-opt`, `clang -O1` output, verbatim shape):

```
rz(h1,.1); icmp_eq_i32_hl(h,5)->f; ry_i32_controlled(f,h1,.9);
icmp_eq_i32_hl_unc(f,h,5); free(f); measure(h1); measure(h1); measure(h)
```

`cq_phi` is `Rz` and ALWAYS lowers in place on its arg-0 handle, so `mark` and
`r` are two SSA names for ONE physical rail. R6 saw `mark` — a *user*, but not a
*read* — and stopped; `cq_measure(mark)` sat one hop out. MEASURED AFTER: `cq
controlled lowering: stale rail record read past a controlled Ry`.

**Probe 2 — BACKWARD alias** (`p15_backward_alias.c`): the same three lines with
the arm rotating `mark` instead, and `cq_measure(r)` after the region. `R` is
`mark`, whose own direct users (the arm theta, the merge φ) all pass R6, while
the stale read hangs off `mark`'s arg-0. Same emitted stream, same fix.

**Two more of the family, found by widening the probe rather than the code:** a
TWO-HOP chain (`m1 = cq_phi(r); m2 = cq_phi(m1); measure(m2)` — a one-hop fence
would still have missed it, which is why the closure is a fixed point), and a
CHAINED-Ry alias (`r2 = cq_theta(r,.5)` before the region, `measure(r2)` after —
`RotationLowering`'s chained branch mints no alloc, so `r2` is the same rail).
Both were accepting; both now decline.

**This is the bd 8h7d.5 F-1/F-3 lesson verbatim, one epic later** (`bd memories
rail-record-set-is-the-rail-not-the-chain`, `offchain-forward-ry-is-a-rail-gate`):
the fence was written over the CHAIN — one SSA name — when the object it protects
is the RAIL, every SSA name of one physical wire. Inc 1 quoted that history in
its own PRD §10 and then reproduced the defect.

**The fix — ONE walk, TWO questions.** `railRootClosure` became
`railWireClosure(V, Taint, WireDir, ArmA, ArmB, Out, Order)`. The backward hop
list is unchanged; a forward extension mirrors hops 1, 2 and 5 (`cq_phi(M,·)`, a
CHAINED `cq_theta(M,·)`, an `add`/`sub`/`xor` whose sole tainted operand is `M`)
and is taken only from TAINTED members and only outside the region's own arm
blocks. R4 and R6 read the SAME set. Three exclusions carry their reasons in
place: ~~φ/select/freeze are crossed backward but NOT forward~~ (**SUPERSEDED —
finding K. They ARE crossed forward now, with the region's OWN merge φ as the
one exclusion. The reason given here named that one φ and was then applied to the
whole CLASS, and the gap was a CONFIRMED silent miscompile one round later.** The
part that was right and is kept: admitting the region's own merge φ forward makes
every legitimate post-region consumer a member's user and collapses the accept
class); the arm
blocks are skipped (region-internal, and crossing them reaches the arm theta and
through its sole use the merge φ — the same collapse); and forward-walking an
untainted value is refused outright (the degenerate `cq_phi(0,θ)` backward hop
can put a CONSTANT in the set, and a constant's user list is the whole module).

**And the second half of the fix is the half that matters — the SKIP set is not
the MEMBER set.** Widening the members must not widen the users that are exempt
from a position proof, and it does not:

* a genuine READ (measure / ret / store / call / φ / select / pure op) keeps the
  SHIPPED `provablyBefore(U, BI)` verbatim;
* an ALIAS HOP is a GATE on the wire, not a record read, and owes only
  `cannotFollowGate` — `!isPotentiallyReachable(BI, U)`, i.e. the SECOND conjunct
  of `provablyBefore` alone.

Getting that wrong in the other direction was measured too: with `provablyBefore`
required of members as well, `control_inplace_ry_sequential.ll` **regressed** —
region 2's wire closure reaches region 1's ARM THETA (backward through region 1's
merge φ, which is region 2's base, then forward off the shared root), and an arm
block dominates nothing. Dominance answers "did `U` definitely execute", which R6
never asks. **A hop that CAN follow the gate still declines** (`j4`, a dead
`cq_phi(r_pre,·)` written after the region: accepted-then-declined, measured).

**The one shape this widens** — the only place an Inc-1 decline became an accept
— is an alias hop on a classically-branched path that cannot follow the region
(`control_inplace_ry_alias_pre_region_branch.ll`, measured: the `rz` stays in its
own conditional block, the controlled Ry is hoisted into the region's pred,
source order intact). Pinned deliberately rather than left invisible.

**Fence ownership moved for the in-loop shape, and the notes say so where a
reader will look.** R6's position predicates are FLAT — neither has the 8h7d.5
per-activation reading — so a loop-carried register's own header φ, reached as a
member around the BACK EDGE, reads as a stale record when it is simply the next
activation's value. Measured: `control_inplace_ry_reject_in_loop.ll` began
declining on the stale-record string, correctly but for a reason that mislabels
the region. `classifyArms` now asks R7's loop question ITSELF, immediately before
R6 and nowhere earlier (so every other clause's message ordering is
byte-identical), firing the same `control flow inside a loop body`;
`handleBranchRegion`'s part-3 fence is kept as the backstop and its comment says
which is which. **Inc 3 must restore R6 with `provablyBeforePerActivation` and
the region's own branch as the barrier BEFORE it lifts either.**

### J′. Shapes probed after the fix that still deserve a reviewer's eye

Recorded because this epic's own history says the second hole is one hop from the
first, and because none of these is *pinned* by a fixture today.

1. **`declineStaleRecordOps` owns every PURE-op spelling, and it runs first.**
   `mark * 7`, `mark ^ 3`, and every other tainted pure op on an alias decline at
   `CQLoweringPass.cpp:282` (`operand predates a non-diagonal gate`) before
   `detectControlRegions` at :322 ever sees the module — measured, before and
   after this fix. R6 covers them structurally as defence in depth and is never
   the fence that fires. `..._reject_stale_diag_alias_pure.ll` records the
   ownership. **If anyone narrows that guard, R6 becomes the only fence for a
   whole consumer kind that has never been exercised through it.**

   **The full consumer-kind ownership table, completed by the round-1 review
   (L6 §12) — two kinds this list omitted never reach R6 at all:**

   | consumer kind | actual owner | pinned by |
   |---|---|---|
   | `cq_measure` | **R6** | `..._reject_stale_measure.ll`, `..._reject_lifted_phi_measure.ll` |
   | `ret` | **R6** | `..._reject_stale_ret.ll`, `..._stale_diag_alias_ret.ll`, `..._reject_lifted_phi_ret.ll` |
   | pure op (`mul`, cast, …) | `declineStaleRecordOps` (`operand predates a non-diagonal gate`) | `..._reject_stale_pure.ll`, `..._reject_stale_diag_alias_pure.ll` |
   | **`store`** | **`declineTaintEscapes`** (`tainted value stored to memory`) | recorded here; no dedicated fixture — the escape guard is not this class's, and R6 never sees it |
   | **opaque `call`** | **`declineTaintEscapes`** (`consumed by an unknown callee`) | recorded here; a SPECIALIZABLE callee IS R6's and is pinned (`..._reject_lifted_phi_clone_arg.ll`) |
   | `phi` / `select` | **R6** | the seven `..._reject_lifted_phi_*.ll` (since finding K a φ is a member HOP, and what R6 refuses is its USERS) |
   | 7.6 tape write | **R6** | `..._reject_lifted_phi_tape.ll` |
   | `cq_invert` | **R6** | `..._reject_lifted_phi_invert.ll` (and §4b probe a5, straight-line) |
2. ~~**The forward walk deliberately does not cross φ / select / freeze**~~ —
   **MEASURED FALSE AND FIXED; see finding K.** The worry was right and the
   assessment ("strict by accident of who checks it, not by a proof") was
   exactly right: a classical join φ was a plain USER that passed
   `provablyBefore` HONESTLY, so its own users were never enumerated, and
   `liftOneRegisterMergePhi` then RAUW'd it to the base. Seven accepting
   reproducers, `opt` exit 0, verify- and stage-2b-clean. The walk now crosses
   φ / select / freeze FORWARD with the region's own merge φ as the ONE
   exclusion, and seven negatives pin the split.
3. **The `add`/`sub`/`xor` hop is conservative in the M-C direction only.** It
   admits both roots because `lowerOps` decides in-place-ness long after
   detection (finding H). If Inc 2/3 ever teaches detection the M-C answer, the
   closure narrows and every member that disappears loses its R6 obligation —
   that narrowing is a Rule-13 change, not a cleanup.
4. **R4's condition side stays BACKWARD-ONLY.** The argument is that two names of
   one wire share a root, so a base member on the condition's wire is already in
   the condition's backward closure. That is true of the hops as written; it
   would stop being true if a forward-only hop were ever added (one with no
   backward mirror). There is no such hop today and the code does not enforce the
   invariant. **The round-1 review turned this into a recorded PROOF rather than
   an observation (§8.3), and the φ-crossing widening of finding K PRESERVES it:
   the φ/select/freeze hop is a forward MIRROR of the backward hop that was
   already there, not a new forward-only one.** A separate, undocumented and
   load-bearing fact the same review surfaced: the condition side's own
   `railWireClosure(Region.Condition, …)` seed contributes exactly ONE element
   (a `CmpInst` is not a `BinaryOperator`), so `condProvenance`'s cone IS R4's
   condition reach — noted at both ends in source (L1 §2).
5. **A member with many users is walked in `Value::users()` order.** The member
   set itself is iterated in worklist-discovery order (`BaseWireOrder`) so the
   diagnostic anchor is deterministic, but the *use list* order is LLVM's and a
   module that trips two R6 violations reports whichever comes first in it. Only
   the anchor varies, never the accept/decline.
6. **`Region.InLoop` is read inside `classifyArms` now.** ~~nothing enforces that
   ordering~~ — **REFUTED by four reviewers independently in the round-1 round
   (L1 §7, L2 §3, L4 §4, L5 §11).** `classifyArms` has exactly ONE caller
   (`handleBranchRegion`), which sets `R.InLoop` 30 lines earlier on the only
   path, and the yn71 fixpoint does NOT build a region by hand — it re-enters
   through the same `detectControlRegions`, hence the same setter. L4 also
   measured a round-2 onward rotation region lowering correctly
   (`cqrt_ry_i32_controlled` minted), which is the positive control for finding
   G's `TaintSet`-hosted map surviving the local `plan2`. Safe by
   single-caller, not by construction — the one-line assertion is still worth
   having before Inc 3 lifts the loop clause.

### K. (FIXED — a CONFIRMED silent miscompile, round-1 review lens L2 §1) R6 was laundered by a liftable one-register CLASSICAL merge φ

Finding J widened R6 from the CHAIN to the RAIL. It left a door open one hop
further out, and the round-1 reviewer walked through it with plain C.

```c
int m; if (c) { m = cq_phi(r, 0.1); } else { m = r; }   /* a CLASSICAL diamond */
if (q == 5) { r = cq_theta(r, 0.9); }                   /* the in-place Ry     */
return cq_measure(m) + cq_measure(r) + cq_measure(q);
```

MEASURED ACCEPTING: `opt` exit 0, `opt -verify` clean, `free_pairing_check.py`
STRICT clean, zero diagnostics, zero warnings, green against all 37 fixtures —
and the emitted stream measures `m` AFTER the controlled Ry relabelled the rail
`m` names (`cq_phi` is Rz, always in place, so `m` and `r` are two SSA names for
ONE wire). Six accepting reproducers over five consumer kinds: `cq_measure`,
`ret`, the 7.6 output tape, a Phase-6 clone argument, a `cq_invert` bracket —
plus the N-way classical `switch` lift and a chained-Ry (non-diagonal) arm gate.

**Root cause, and it is J′ #2 measured false.** `railWireClosure` crossed
`PHINode`/`SelectInst`/`FreezeInst` BACKWARD but not FORWARD. The in-source
justification was *"the region's OWN MERGE φ is a user of the base"* — which
names ONE φ, not the class, and J′ #2 already flagged the exclusion as *"strict
by accident of who checks it, not by a proof"*. The classical join φ was
therefore a plain USER of a member; it passes `provablyBefore(φ, BI)` **honestly**
(it dominates the branch and the branch cannot reach it), so R6 stopped there and
**its own users were never enumerated**. `liftOneRegisterMergePhi`
(`TaintPropagation.cpp`) then RAUW'd the φ to the base — AFTER the region was
emitted — and the compensating re-sweep `declineLiftedStaleRecordOps` re-runs only
`declineStaleRecordOps`, whose scope is binary/unary/cast/data-compare/curated-
intrinsic. None of the six consumers is in it.

**The straight-line twin declined all along**, which is what makes the classical
diamond the launder rather than the defect, and the Rz twin of the same launder
is BENIGN (diagonal — same basis, same distribution). Other launder spellings
were refuted: a classical-condition `select` declines (`declineClassicalMuxes`
refuses selects categorically), a `freeze` is folded away in `propagate` before
detection, and a two-gate φ collapses under `-O1` to one call with a `select` on
the ANGLE.

**Fix.** Cross φ / select / freeze FORWARD from a tainted member, with ONE
exclusion — the region's own `MergePhi`, passed in beside `ArmA`/`ArmB`. A
crossed φ's result becomes a member, so ITS users owe the position proof. A
select is crossed only on its DATA operands (as the CONDITION its result is a
fresh merged register, the 4.4 path).

**THE SKIP SET MOVED TOO, AND THAT IS THE ANSWER, NOT AN OVERSIGHT.** `BaseWire`
feeds THREE consumers — R4's intersection, R6's member enumeration, and R6's
`BaseWire.count(UI)` skip set — and this widening grew all three. For the skip
set the relaxation is `provablyBefore` → `cannotFollowGate` (dropping the
DOMINANCE conjunct) on a newly-admitted φ/select/freeze, and it is sound because
none of the three is a RECORD READ: a `PHINode` and a `freeze` emit no gate at
all, and a `select` that survives to lowering is a CNOT-class copy OFF the wire.
For all three the only thing that can go wrong is EXECUTING AFTER the hoisted
controlled Ry, which is exactly what `cannotFollowGate` refuses. (Contrast bd
8h7d.5 F-3, where the two sets had to move APART. Ask the question every time;
the answer is not always the same.)

**The accept that keeps it a fence and not a ban:** `l_base_is_liftedphi` — the
region rotates the φ ITSELF, so every consumer reads the region's own merge φ.
Committed as `control_inplace_ry_lifted_phi_base.ll`, measured accepting both
before and after.

**Scope, stated honestly (the reviewer's own note).** The same launder with an
UNCONDITIONAL `r = cq_theta(r,0.9)` instead of a region also accepts and emits the
same wrong stream, through no code this epic touches — that shared root is
pre-existing bd `0njv`/`2qyz` and is NOT introduced here. What Inc 1 introduced
is (a) a new, quantum-controlled way to reach it and (b) a written claim in the
PRD and in the source that it is unreachable. The claim is now true.

### L. (FIXED — a CONFIRMED silent miscompile, round-1 review lenses L3 §1 AND L5 §1, independently) The finding-A freeze was keyed on a pointer `lowerOps` erases

**Finding A's defect, verbatim, from plain C, on an accept shape §4b's own probe
`a1` measured and did not commit as a fixture.**

```c
int q = cq_theta(3,.5), p = cq_theta(7,.25);
int r = p * 5;                       /* an OUT-OF-PLACE DERIVED base */
if (q == 5) { r = cq_theta(r, 0.9); }
int s = r + 1;                       /* a POST-REGION user           */
```
emitted `cqrt_free(%h_cmp); … cqrt_ry_i32_controlled(%h_cmp, %h_op, -0.9)`
(USE AFTER FREE) `… cqrt_free(%h_op)` (DIRTY FREE) — `opt` exit 0, verify-clean,
37/37 fixtures green. Stage 2b reports `VIOLATION F2-use-after-free` +
`T3-rail-written-before-reversal`, but stage 2b runs only on e2e slices and no
slice had a derived base under a rotation arm.

**Root cause.** `RotationLowering` did `taint.ControlledRotationRails.insert(Handle)`
where `Handle` is the theta's arg-0 AT THAT MOMENT. `lowerRotations` is pipeline
step N; `lowerOps` is step N+1. For a derived base `Handle` is the raw LLVM
instruction (`mul`/`add`/`xor`/`and`/`shl`/`zext`/`@llvm.sqrt`), which `lowerOps`
RAUWs to the `cq_template_*` result and ERASES — through **five** separate
`promote()` copies (`ArithLowering`, `CastLowering`, `CompareLowering`,
`IntrinsicLowering` and their drivers), each of which migrates `Tainted` /
`BirthOrder` / `HandleWidth` and **none of which knew about the freeze**. The set
then held a DANGLING pointer; all three query sites answered "not frozen".
Second consequence: a later-minted rail landing on the freed address would be
spuriously FROZEN — the `RegionFlatten::scrubTaint` hazard, which
`ControlledRotationRails`' own header cited and applied to the theta but not to
the theta's OPERAND.

**Breadth, measured:** `mul`, `and`, `or`, `shl`, `udiv` — 5 of 5 out-of-place
opcodes; `add`/`xor` too, where M-C makes the base in place so the DIRTY FREE
lands on the SOURCE rail; i32 through `ArithLowering` and f64 through
`IntrinsicLowering`. Both reviewers reached it independently, from different
lenses, within the same round.

**Fix — STRUCTURAL, and the `Value *` set is REMOVED, not repaired.**
`ChainWalk::railCarriesControlledRotation(H)`: does `H` have a user `G` with
`isInPlaceGateOn(G, H)` and a `cqrt_{ry,rz}_*_controlled` callee? The rail is
DEFINITIONALLY `G->getArgOperand(1)` at query time, so no RAUW or erase can move
it and there is no set for an address to be reused in. Derived from
`isInPlaceGateOn` so the two cannot disagree about which slot is the rail (Rule
14, the bd `uow0` discipline). Restricted to the ROTATION stems: that predicate
also admits the iw81.7 guarded QRAM store at arg 1, which is NOT frozen (its
`_unc` runs while its flag is still live). Covers BOTH stems, so **Inc 2's Rz
peephole inherits the freeze rather than finding A one stem over** (L3 §2 — Inc 1
had already widened `isInPlaceGateOn` and `EmitInverse` to `rz`, so the trap was
armed). Migrating the member through all five `promote()` copies was considered
and rejected: five places to forget, and `promote()` is not the only RAUW.

Red→green measured mechanically: with the predicate stubbed to `false`, **5**
fixtures fail (the 3 new derived-base ones, `..._dead_base_late_use_frozen.ll`
and `..._warn_live_record.ll`); with it, 53/53 pass.

**FINDING F IS CORRECTED, NOT RESTATED.** Inc 1 recorded that the `EmitInverse`
controlled-rotation adjoint has "NO reachable caller at HEAD". That was FALSE as
shipped — the whole-DAG spine reached it through exactly this unfrozen
derived-base path, which is how the defect manifests. **After the fix it is true
again, and this is what "true" means here:** the two `_dead_base_*` fixtures and
the three `_derived_base_*` ones assert (`CHECK-NOT: double -9.000000e-01`) that
no adjoint is emitted for a frozen rail; spec clones are rotation-free by
construction; the 7.4 break reverse-play only runs on claimed loop bodies, where
this class declines; and `emitRz`'s single caller still passes
`controlled=false`, so `cqrt_rz_<W>_controlled` is unemittable. The adjoint recipe
remains a RESERVE for Inc 2/3 — stated as a checked claim with its checks named,
rather than as an argument.

### M. (FIXED — a CONFIRMED crash + an introduced OVER-DECLINE, round-1 review lens L4 §1-2) `ControlRegion::RoutedBase` dangled across emission order

`RoutedBase` is recorded at DETECTION and read at EMISSION. Between those two
moments `lowerControlRegions` may emit ANOTHER region, which does
`MergePhi->replaceAllUsesWith(base); MergePhi->eraseFromParent()`. A raw
`Value *` is not a USE, so the RAUW does not update it and the erase leaves it
DANGLING.

* **The crash (pre-existing).** `if (q==5) q=cq_phi(q,.2); if (cc) g(); if (q==6)
  q=cq_phi(q,.3);` — two eq-fold PHASE regions with a CLASSICAL branch between.
  Region 2's `RoutedBase` IS region 1's merge φ; the phase emitter dereferences
  it (`emitRoute` → `IRBuilder::CreateCall` reads `Q->getType()`). **SIGSEGV**
  under `DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`, from `clang -O1` C.
* **The over-decline (INTRODUCED by Inc 1).** Inc 1 made the field non-null on
  EVERY in-place accept, where before it was written only by the two const-fold
  re-anchors. `emitInPlaceRotationRegion` COMPARES it against the RAUW-updated
  theta operand, so the same CFG with Ry arms declined `control flow` — the
  increment's headline shape, whenever a classical branch sat between two
  regions. Three controls isolate it: delete the classical branch → accepts;
  `cq_theta` → `cq_phi` → accepts; **same CFG, blocks re-laid-out → accepts**.
  Detection is pure SSA + DominatorTree analysis and cannot see textual block
  order, so a verdict that flips with it is emission order.

**Why the bd `hcrg` pre-flight does not catch it, which is the lesson.** That
precedence graph reasons about **BasicBlock** identities (`doomedBlocks`,
`sequentialChainAlias`, the Kahn sort). The classical `if` makes region 2's pred a
THIRD block rather than region 1's merge block, so it correctly finds no block
alias and orders nothing — while the dependency it does not model is a **VALUE**
one. Blocks were protected; values were not.

**Fix.** `RoutedBase` is a `llvm::WeakTrackingVH` — it FOLLOWS the RAUW (so it
names region 1's base, the correct routed handle for both readers) and NULLS on
erase. Because null now means two different things, a `RoutedBaseRecorded` bit is
written only through the new `setRoutedBase` setter: **never recorded** ⇒ derive
`Q` as before (byte-identical for every non-eq-fold, non-rotation region);
**recorded and since erased** ⇒ LOUD `diagnoseUnderControl`, never a fall-through
to the φ derivation (for an eq-fold if/else that derivation bottoms at the folded
constant `k` and routes a CONSTANT — the exact miscompile the field exists to
prevent).

#### `ControlRegion` field audit — every field read at emission, asked the same question

| field | kind | read at emission? | can another region's emission invalidate it? | verdict |
|---|---|---|---|---|
| `RoutedBase` | `Value *` | yes (phase + in-place) | **YES** — it is the ONLY field that names a value belonging to ANOTHER region (the previous region's merge φ) | **CONVERTED** to `WeakTrackingVH` + `RoutedBaseRecorded` |
| `Condition` | `Value *` | yes | no — **and the ground is STRUCTURAL, not a measurement** (rewritten after the round-2 review, lens C §1). `classifyArms` calls `condWireDisposition` unconditionally for EVERY `BranchRegion`, whose FIRST line is `if (Cond->getParent() != R.Pred) return DeclineNow` (`ArmClassify.cpp` ~:896). An `Instruction` has exactly one parent block and a block exactly one terminator, so two regions sharing a `Condition` would have to share a `Pred`, hence share the tainted `br`, hence **be the same region**. Two accepted `BranchRegion`s therefore CANNOT share this field, whatever any wire guard does. For a `Condition` shared across region KINDS, every site that erases a condition compare is `use_empty`-guarded (`RegionFlatten.cpp:91`/`:174`/`:178`, `AbortParkEmit.cpp:421`, `SelectMergeEmit.cpp:313`/`:318`), so a surviving `br` user keeps the compare alive in either emission order | unchanged, recorded |
| `CondA` / `CondB` | `Value *` | yes (compound) | no — the region's own sub-compares, in `Pred` or `Mid` | unchanged |
| `Merge` | `Instruction *` | yes | no — a merge node belongs to exactly one region, and the block it lives in is the `hcrg` pre-flight's business | unchanged |
| `Shadow` / `ShadowFalse` | `Instruction *` vec | yes | no — the region's own arm-block contents; `flattenRegion` erases only its OWN arm blocks | unchanged (block-protected) |
| `AnglePhi` / `AngleConsumers` | `PHINode *` / `Instruction *` vecs | yes (cwk angle path) | no — same argument as `Merge`; and this class declines for an `InPlaceRotation` arm (R7) | unchanged |
| `Pred` / `Arm` / `ArmFalse` / `MergeBB` / `Mid` | `BasicBlock *` | yes | yes in principle — **and that is precisely what the `hcrg` pre-flight already models and orders** (`doomedBlocks` + Kahn, declining loudly on an unresolvable alias or a cycle) | unchanged; the pre-flight IS the protection |
| `Flag` / `FlagA` / `FlagB` / `ParentFlag` / `ParentRail` | `Value *` | yes | no — all are WRITTEN at emission time and read within the same region's emission; there is no detection→emission gap | unchanged |
| `SwitchArms[].Block` / `.Shadow` | block + instrs | yes (4.5) | no — same as `Shadow`; a switch region declines for this class | unchanged |
| `ParentIdx` | `unsigned` | yes | n/a — deliberately an INDEX, not a pointer, "the region list is a `SmallVector` that may reallocate" | unchanged — and it is the precedent this fix follows |


---

## 4b. Self-adversarial probe round on the accept surface

Run against the finished build before hand-back. Five probes aimed at the ACCEPT
class rather than at the declines; **two became fixtures**, and for the other
three the disposition is the interesting part.

| probe | shape | result |
|---|---|---|
| `a1` | base is an OUT-OF-PLACE derived rail (`r = p * 5`), condition on a third register | **ACCEPTS**, emitting `cqrt_ry_i32_controlled(f, %h_op, .9)` on the fresh `mul` rail with the strip on `%h` — correct, because a `mul` always mints a fresh rail, so `railWireClosure` stops there and the wires really are disjoint. Also raises the M-A live-record WARNING (the mul's source is a live ancestor record that dephases the answer — the user's circuit, the user's call, bd `lyyf`). **⚠ THIS PROBE WAS NOT COMMITTED AS A FIXTURE, AND THAT IS EXACTLY WHERE FINDING L LIVED.** The accept is right; the FREEZE on the accepted rail was not, because a `mul`-derived base is precisely the case whose key `lowerOps` erases. This probe was run WITHOUT a post-region user, so the spine's reversal landed before the flag free and the module was sound — the two axes were probed separately and never crossed. Now pinned by `control_inplace_ry_derived_base_mul_late_use_frozen.ll` and the `slice_control_inplace_ry_derived_base` e2e slice. **A probe that only lives in a markdown table is not a fixture.** |
| `a2` | TWO rotation regions in sequence on ONE register | **ACCEPTS**; each mints/strips/frees its own flag, in source order, no work rail. Rides the bd `hcrg` precedence graph unchanged. → fixture `control_inplace_ry_sequential.ll`. |
| `a3` | a rotation region THEN a swap-routed phase region on the same register | **ACCEPTS**; the phase route CSWAPs the register the controlled Ry relabelled and hands it back (its join is the adjoint of its split); 3 frees. → fixture `control_inplace_ry_then_phase_region.ll`. |
| `a4` | Q+Q condition (`if (q > p)`) | Declines. The flag mint returns null BEFORE any hoist, so nothing is mutated; the surviving `icmp` then draws `no template for opcode 'icmp i1' in tainted context`. **Verified identical for the `cq_phi` twin** — pre-existing behaviour, not something this class introduces. |
| `a5` | `cq_invert_*` of the pre-region base, after the region | Declines on R6 (`stale rail record read past a controlled Ry`) — the escape spelling R6 exists for. |

---

## 5. Why `test_trace.c` grew BOTH stems

`cqrt_rz_<W>_controlled` has been declared and defined since Phase 4 and was
exercised by **nothing** — its trace format was unpinned, in the file whose whole
job is to pin trace formats before a consumer depends on it. Inc 0 mints the `ry`
twin and turns on its first consumer; Inc 2 of the same epic turns the `rz` twin
into an emitted symbol on the same path. Adding them together means the pair
acquires its golden together rather than one inheriting the other's gap.

---

## 6. The e2e goldens, argued line by line

### `tests/e2e/slice_control_inplace_ry.expected.log`

```
1  cqrt_alloc_i32(3) -> h0
2  cqrt_ry_i32(h0, 0x1p-1)
3  cqrt_alloc_i32(7) -> h1
4  cqrt_ry_i32(h1, 0x1p-2)
5  cq_template_icmp_eq_i32_hl(h0, 5) -> h2
6  cqrt_ry_i32_controlled(h2, h1, 0x1.ccccccccccccdp-1)
7  cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
8  cqrt_free(h2)
9  cqrt_measure_i32(h0) -> 0
10 cqrt_measure_i32(h1) -> 0
```

1–2. `q = cq_theta(3, 0.5)` — the sole taint source: allocate `q`'s rail at the
classical seed 3 and apply `Ry(0.5)`. `0x1p-1` is exactly 0.5 (`%a`, bd `ni15`).

3–4. `r = cq_theta(7, 0.25)` — a **second, independent** rail. Two `cqrt_alloc`
lines is the whole basis of R4 for this slice: `h0` and `h1` are different
physical wires, so nothing the arm does to `h1` can change `h0`'s basis.

5. The flag mint, at the compare, on `h0` — byte-identical to what the phase path
emits for the same condition. The returned `h2` is the flag rail, holding
`[q == 5]`.

6. **The arm gate.** `cqrt_ry_i32_controlled(h2, h1, 0.9)`: control `h2`, target
`h1`, classical angle. Exactly one line, on the user's own register. There is no
`cqrt_alloc_i32(0)` before it and no `cqrt_cswap` around it, and the *absence* of
those three lines is the increment: a route here would have left the inactive
work rail dirty and entangled (PRD §2). `0x1.ccccccccccccdp-1` is `0.9`.

7. The flag strip. `icmp_eq_i32_hl_unc(h2, h0, 5)` recomputes `q == 5` from `h0`
and XORs it onto `h2`. Line 6 touched only `h1`, so `h0` still holds what line 5
read, and `h2` is back to `|0⟩` — this is the pairing bd `8txa` moved onto the
void out-first `_unc` precisely so a golden can witness it: the rail the strip
names is the rail the next line frees.

8. `cqrt_free(h2)` — a clean reset of a proven-`|0⟩` ancilla, not a measurement
(Rule 6). **Exactly one free in the slice**, against the phase diamond's two
(work rail + flag), because there is no work rail.

9–10. The two measurements read `h0` and `h1` — the merge φ was RAUW'd to the
base register, so the source's `cq_measure(r)` measures the rail the controlled
Ry relabelled. `-> 0` is the trace-only runtime's fixed return.

**Not in the golden, deliberately:** no `cqrt_ry_i32(h1, -0.9)` adjoint and no
`cqrt_free(h1)` — the register is frozen (finding A), and it is measured anyway.

### `tests/e2e/slice_control_inplace_ry_negated.expected.log`

Identical except lines 6–8 become

```
6  cqrt_x(h2)
7  cqrt_ry_i32_controlled(h2, h1, 0x1.ccccccccccccdp-1)
8  cqrt_x(h2)
```

`if (q != 5)` canonicalizes to `icmp eq` with **swapped successors** (Rule 9), so
the gate arm is the FALSE one and must fire on `¬flag`. The bracket is the
self-inverse `cqrt_x` pair the swap route already uses, so the two spellings of
"fires on ¬f" cannot drift. **The pair is what the golden witnesses**: a stray
single `cqrt_x` would leave `h2` inverted when the strip recomputes `q == 5`, so
the strip would XOR onto the complement and `cqrt_free(h2)` would reset a rail
holding `|1⟩` — a hidden measurement of an entangled ancilla. Both slices run
stage 2b **strict** (no `--allow-unproven`).

---

## 7. Fixtures

**55 files in the `control_inplace_ry_*` family, split 19 accept / 35 decline /
1 warn** (was 53 = 17/35/1 after the round-1 Rule-13 review; 37 = 11/25/1 before
it; 28 = 8/19/1 as first shipped, +9 from finding J). Plus ONE in the
`control_swap_*` family — `control_swap_eqfold_classical_between.ll`, finding M's
crash pin, which lives there because it contains no rotation arm at all.
Counts re-measured on disk 2026-09-02
(`ls ir-pass/test/control_inplace_ry_*.ll | wc -l`); re-measure rather than
trust them.

**Accept (17).** The eleven from Inc 1 — `control_inplace_ry_diamond.ll` (S1,
exact stream + exact alloc/free counts), `..._diamond_negated.ll` (Rule-9
polarity, exact `cqrt_x` count), `..._ifelse.ll` (two arms, hand-constructed —
finding D), `..._f64.ll` (non-i32 width, fcmp flag), `..._dead_base_frozen.ll`
(finding A, the case where reversal would have been sound and is frozen anyway),
`..._dead_base_late_use_frozen.ll` (finding A's regression pin), `..._sequential.ll`
and `..._then_phase_region.ll` (the §4b composition shapes), and finding J's
`..._alias_chain_consumed.ll`, `..._alias_after_region.ll`,
`..._alias_pre_region_branch.ll` — plus **six from the round-1 review**:

* `..._derived_base_mul_late_use_frozen.ll`, `..._derived_base_add_late_use_frozen.ll`,
  `..._derived_base_f64_late_use_frozen.ll` — **finding L**, three because the
  stale key's blast radius depends on WHICH lowering claims the derived op
  (`ArithLowering` out-of-place, `ArithLowering` in-place-via-M-C so the dirty
  free lands on the SOURCE rail, and `IntrinsicLowering` at a non-i32 width).
* `..._lifted_phi_base.ll` — **finding K**'s accept control (the base IS the
  classical join φ), so the φ-crossing widening is a fence and not a ban.
* `..._sequential_classical_between.ll` — **finding M**'s over-decline pin.
* `..._inplace_alias_witness.ll` — the L1 §1 M-C premise witness (no region at
  all; it MEASURES that `q ^ 2` lowers in place, which is what makes its sibling
  a true positive).

— plus **two from the round-2 review**:

* `..._clone_base_frozen.ll` — **round-2 lens A §1**: the rotated base is a
  Phase-6 `@__cq_q_<callee>_<mask>` SPECIALIZATION-CLONE RESULT, the one shape in
  `D.Calls \ D.Rails` that the freeze was never asked about. ⚠ Its header says
  plainly that it does NOT distinguish the fix — the stream is byte-identical
  with and without the new step-1 query, because the caller's spine already
  refuses this DAG on the clone call's unrecognized-consumer route. It pins the
  accept; the freeze query itself is pinned by a CODE READ.
* `..._ifelse_classical_between.ll` — **round-2 lens C §6**: the two-gate IF/ELSE
  hoist (the `Negated` `cqrt_x` bracket around the second gate) IN COMPOSITION
  with a classical branch between two regions — i.e. finding M's exact geometry
  with two gates instead of one. Before this the two-gate branch had exactly one
  standalone fixture and no composition test, and cross-region value lifetime is
  the axis both round-1 crash/over-decline defects lived on.

**Decline (35).** The twenty-five from Inc 1 (`..._reject_` + `cond_register`,
`ssa_alias`, `diagonal_alias`, `derived_base`, `two_thetas`, `theta_phi_arm`,
`tainted_angle`, `stray_op`, `raw_i1_cond`, `state_prep`, `stale_measure`,
`stale_ret`, `stale_pure`, `in_loop`, `nested`, `switch`, `mixed_ifelse`,
`mixed_ifelse_rz_first`, `share_cond_flag`, and finding J's
`stale_diag_alias_{forward,backward,ret,two_hop}`, `stale_chained_theta`,
`stale_diag_alias_pure`) — plus **ten from the round-1 review**:

* `..._reject_lifted_phi_{measure,ret,tape,clone_arg,invert,switch,chained_theta}.ll`
  — **finding K**, all seven MEASURED accepting before the fix, one per consumer
  kind (and `switch` / `chained_theta` because the launder is any classical CFG
  join and any in-place gate, not "a diamond" and not "`cq_phi`").
* `..._reject_inplace_alias_base.ll` — **L1 §1**, R4's only TRUE-POSITIVE.
* `..._reject_derived_base_sub.ll` — **L1 §1**, the third spelling (the two wire
  walkers are ASYMMETRIC across `add`/`sub`/`xor`).
* `..._reject_two_bases.ll` — **L6 §4**, R3's "one base" clause, reachable and
  unpinned until the review measured it.

**Warn (1):** `..._warn_live_record.ll` — the M-A guard extension, and (measured,
§3b) the ONLY fixture in the family that reddens if `isInPlaceGateOn`'s
controlled row is deleted.

---

## 8. Round-1 Rule-13 review — what changed, and what deliberately did not

Six lenses (L1 flag-strip/R4 · L2 stale-record/R6 · L3 freeze/spine · L4
polarity/order/plan-lifetime · L5 walker audit/adjoint/ABI/checker · L6 fixture +
doc truth). **All 37 committed fixtures and both e2e slices were GREEN
throughout** — every defect below shipped through a green suite. PRD §11 is the
summary of record; findings K / L / M above are the detail.

### 8.1 Fixed
| # | what | severity |
|---|---|---|
| K (L2 §1) | R6 laundered by a liftable one-register classical merge φ — 7 consumer kinds | CONFIRMED SILENT MISCOMPILE |
| L (L3 §1 = L5 §1) | the freeze keyed on a pre-`lowerOps` `Value *` `lowerOps` erases; finding A returns for every derived base | CONFIRMED SILENT MISCOMPILE (found independently by two lenses) |
| M (L4 §1-2) | `RoutedBase` dangles across emission order: SIGSEGV on the eq-fold phase path, over-decline on the in-place path | CONFIRMED CRASH (pre-existing) + introduced OVER-DECLINE |
| L1 §1 | R4's only fixture was a self-declared over-decline; no true positive, no `sub` spelling | Rule-12 coverage gap |
| L1 §2 | `condProvenance` silently carries R4's whole condition side (a `CmpInst` is not a `BinaryOperator`, so the closure's own seed stops dead) | undocumented, load-bearing — now noted at BOTH ends |
| L5 §4 | 7 unlisted audit sites + `basisPermutationGate` (no such symbol; it is `preservesBasisUnderRecord`) | audit hygiene — §3d |
| L5 §5 | the `isInPlaceGateOn` extension's stated consumer is unreachable under the working freeze | false justification — corrected and RE-MEASURED |
| L5 §6 | `preservesBasisUnderRecord`'s `_controlled` arm had no VOID/arity fence while `isInPlaceGateOn`'s did | bd 1fim symmetry — fenced |
| L5 §7 | `free_pairing_check.py`'s docstring premise ("no symbol with that adjoint has controls") is now FALSE | restated; conclusion was and is correct |
| L5 (mutants) | ctrl/handle SLOT SWAP was untested — on real emitted IR, and in the adjoint only | 2 mutants added; both fire |
| L6 §1 | the flagship accept fixture's stated assertions were not the ones FileCheck evaluated (injected `cqrt_x` / `cqrt_cswap` passed GREEN) | `CHECK-NEXT` chain + a bounded `NOROUTE` prefix; both L6 mutants now caught |
| L6 §2 | the frozen-ABI header named `ControlPlan::ControlledBy`, a design deliberately NOT built for a silent-miscompile reason | corrected, with the reason |
| L6 §3/§6/§7 | CLAUDE.md's "gated only on" enumeration, four counts, and the unqualified "diamond + if/else" claim | corrected; counts re-measured (295 ctest / 1347 lit / 285 e2e of which 271 slices). **L6's fifth sub-claim was WRONG and is recorded as such:** the "1 XFAIL" sentence is CORRECT — `grep -l XFAIL` returns 9, but 8 of those only mention the directive in prose, and `lit` reports `Expectedly Failed: 1`. CLAUDE.md now names the instrument to trust |
| L6 §4 | R3's "one base" clause reachable and unpinned | `..._reject_two_bases.ll`; the sibling untainted-base clause is unreachable and now SAYS so in source |
| L6 §5 | two decline fixtures used `error{{.*}}under quantum control`, which matches every diagnostic in the family | exact strings |
| L6 §8/§9/§10/§11 | PRD drift: `plan.ControlledBy`, "do NOT write a new alias walker", pre-finding-J R6 wording, the unrecorded §9.1 sweep | PRD §6/§4/§9 amended; §11 added |

### 8.2 Deliberately NOT fixed — over-declines and pre-existing behaviour
Recorded as follow-ons. Over-declining is always safe (Prime Directive); none is
correctness debt.

1. **"Rotate, then branch on the rotated register" declines while its `cq_phi`
   twin compiles.** `if (q>5) r=cq_theta(r,.9); if (r>2) s=cq_theta(s,.4);` →
   `condition predates a non-diagonal gate`. Found by THREE lenses independently
   (L1 §5, L2 §2, L3 — the natural Grover-ish composition "apply a controlled
   rotation, then test the register you rotated"). The owner is the PRE-EXISTING
   `condWireDisposition`/`wireGainsNonDiagonalGate`, which cannot tell "the
   condition reads the POST-gate name" from "the condition reads a PRE-gate
   record": the arm theta lives in a conditional arm and dominates nothing, so
   the position-aware skip cannot certify it. Belongs on the Inc 2/3 scoping list.
   **⚠ WIDER THAN THIS HEADLINE SAYS (round-2 review, lens B §2), and the extra
   half is the one someone will actually write.** The region does not have to be
   incomplete: a non-diagonal gate on the CONDITION register *after* a FULLY
   EMITTED region — mint, gate, strip and `cqrt_free(f)` all already in the
   stream — declines on the same string, while its `cq_phi` twin accepts. Three
   measured spellings: `if (q==5) r=cq_theta(r,.9); q = cq_theta(q,.2);`; the
   same with the later gate inside a classical `if`; and, most naturally,
   `if (q==5) r=…; if (p==4) q=cq_theta(q,.3);` — a second region that rotates
   the FIRST region's condition register, which is an ordinary Grover-ish
   composition. All three are sound to accept: the flag's whole life ends before
   the offending gate can run, so the condition's basis at the strip is the basis
   the mint read, which is exactly R4's premise. Same pre-existing owner.
2. **Two in-place regions on DIFFERENT registers under the SAME condition**
   (`if (q==5) r=…; if (q==5) s=…;`) declines on the same guard (L3 §4). Both
   rotated rails are disjoint from `q`'s and from each other, so it is sound;
   §4b's composition matrix does not list it and a reader may expect it to work.
   **⚠ NARROWER THAN IT READS (round-2 review, lens B §2): it is TWO REGIONS ON
   DIFFERENT REGISTERS UNDER THE SAME LITERAL COMPARISON, not "two regions on one
   condition register".** The natural composition WORKS and is measured:
   `if (q==5) r=cq_theta(r,.9); if (q==6) r=cq_theta(r,.3);` — two regions, SAME
   condition register, different literals — ACCEPTS and is prefix-identical to
   its `cq_phi` twin, and so does the two-independent-register interleaving. Do
   not quote L3 §4 as "one condition register cannot carry two regions".
3. **`cq_invert_begin/_end` AROUND a region is a silent no-op** (L3 §5). Verified
   identical for the PHASE-region twin, so it is Phase-8-not-implemented, not
   something this arm class introduces.
   **⚠ AND "no-op" UNDERSTATES IT (round-2 review, lens B §3): the module `opt`
   accepts DOES NOT LINK.** Measured with NO region at all — `int r=cq_theta(…);
   __cq_invert_begin(); r=cq_phi(r,.14); __cq_invert_end(); return
   cq_measure(r);` — `cq-opt` exits 0 and leaves `declare void
   @__cq_invert_begin()` plus both call sites in the lowered IR, and stage 3
   fails with `Undefined symbols … ___cq_invert_begin`. No e2e slice uses the
   bracket (`grep -rln '__cq_invert' tests/e2e/*.c` is empty), so the only layer
   that LINKS never sees it. `CQ.h` declares the markers, so this is reachable
   from ordinary user source. PRE-EXISTING and Phase-8-owned — recorded here
   because the honest statement of today's behaviour is "accepts and cannot be
   built", not "silent no-op", and because a loud decline on an unconsumed
   `__cq_invert_begin` would be the Prime-Directive-consistent interim. FOR THE
   ORCHESTRATOR TO FILE as its own bd issue; it is not this epic's. (`cq_invert` as a CONSUMER of the
   pre-region record does decline correctly — §4b probe a5, and finding K's
   `..._reject_lifted_phi_invert.ll` now pins the laundered spelling too.)
4. **The unconditional `cqrt_free(Flag)` after a possibly-null strip mint**
   (L3 §3). No reachable case was constructible (the forward mint succeeded on
   the same operands and predicate, so the inverse classification follows), and
   the PHASE path at `SwapRouteEmit` has the identical unconditional free — it is
   pre-existing house style, not a regression. Recorded only because the new
   emitter copies it.
5. **`RotationLowering`'s observing-sink walk treats a controlled rotation's
   CONTROL slot as a non-use** where the neighbouring `cqrt_tape_write_*_controlled`
   / `cqrt_cnot` / `cqrt_toffoli` rows model it as a HOP (L5 §9, §3d). Costs at
   most a missing DS_Warning.
6. **Detection and mint derive the ABI width from two different expressions**
   (L5 §8, §3d) — latent, agreeing on every `CQ.h` spelling checked.

### 8.3 J′ items the review resolved
* **J′ #2 ("the forward walk does not cross φ/select/freeze … strict by accident
  of who checks it, not by a proof")** — MEASURED FALSE and fixed; finding K.
* **J′ #6 (`Region.InLoop` possibly unset on the yn71 onward path)** — REFUTED by
  three lenses independently (L1 §7, L2 §3, L4 §4, L5 §11): `classifyArms` has
  exactly ONE caller, and `detectAndLowerOnwardControl` re-enters through the same
  `detectControlRegions`, hence the same `handleBranchRegion` setter. Downgrade it.
* **J′ #4 (R4's backward-only condition side)** — proof recorded rather than left
  as "no such hop today": every forward hop has a backward mirror; a Λ (two names
  joined through a common DESCENDANT) cannot be built, because `cq_phi`/`cq_theta`
  have one wire operand each, `add`/`sub`/`xor` take NO hop when both operands are
  tainted (a Q+Q op mints a fresh template rail), and a φ/select over two
  different rails is a classical mux that `declineClassicalMuxes` owns. The hop
  list was also checked COMPLETE against `isInPlaceGateOn`'s post-lowering
  in-place set, with every other producer MEASURED to mint a fresh rail
  (specialized call, cast, compare, mul, fneg, intrinsic, QRAM load).
* **J′ #1 (`declineStaleRecordOps` owns every pure-op spelling and runs first)** —
  re-confirmed, INCLUDING the laundered spelling (`m*7`, `(short)m`). L6 §12 adds
  the two rows J′ #1's table omitted: a `store` and an opaque `call` of the
  pre-region record are owned by `declineTaintEscapes`, not by R6.

### 8.4 Gates run for this round
See §9.

---

## 9. Gates run

Run AFTER the round-1 fixes, on 2026-09-02. **Report only what was run** (Rule
19): this list is exhaustive.

| gate | command | result |
|---|---|---|
| build (BOTH targets — never `--target CQPass` alone) | `cmake --build build -j8` | clean |
| `ir-pass-lit`, whole entry | `ctest --test-dir build -R ir-pass-lit` | **PASS**, 1347 fixtures (1 XFAIL), 53–74s |
| **full suite** (Rule-19 moments 1 AND 5 both apply: a Rule-13 lowering-core change AND an accept/decline predicate change) | `ctest --test-dir build -j6` | **295/295 PASS, 0 failed**, 739s |
| `cq_opt_equivalence` FULL sweep (PRD §9.1 — the diagnostic surface changed again) | `cmake --build build --target cq-opt-equivalence-full` | **compared 1347 fixtures, 0 mismatch(es)** |
| the stage-2b checker's own mutant validation | `python3 tools/free_pairing_check_test.py` | **0 failures** — 26 positives, 69 named mutants, 313 proof-targeted, 5 Case-A negatives (was 25 / 67 / 311 before the two L5 slot mutants) |

The 739s figure is NOT comparable to CLAUDE.md's quiet-box 130–230s band: this
run was under concurrent agent load. Compare two runs only under the same load.

**Red→green, measured mechanically, not argued** — each fix was verified by
stubbing it out, rebuilding BOTH targets and re-running the family:

| fix | stub | red | green |
|---|---|---|---|
| finding L (structural freeze) | `railCarriesControlledRotation` → `return false` | **5 FAIL** (the 3 new `_derived_base_*`, `_dead_base_late_use_frozen`, `_warn_live_record`) | 53/53 |
| finding K (φ crossing) | the `PHINode`/`Freeze`/`Select` arm of `forwardRailHop` → `return false` | **7 FAIL** (exactly the seven `_reject_lifted_phi_*`) | 53/53 |
| finding M (`WeakTrackingVH`) | — (the pre-fix binary crashed under libgmalloc; both new fixtures were measured DECLINING/CRASHING before and ACCEPTING after) | p34 SIGSEGV, p49 `control flow` | both accept, both libgmalloc-clean, both stage-2b strict-clean |
| L6 §1 (the diamond fixture's own assertions) | inject `cqrt_x(%h1)` between mint and gate (M10) / `cqrt_cswap(f,h1,h1)` after the free (M9) into the fixture's REAL output | both were GREEN before | both **RED** now (M10 on the main prefix, M9 on `NOROUTE`) |

**Layers NOT run:** none of the five above was skipped. Nothing else exists at
this layer.

---

## 10. Residuals from the round-1 fixes themselves (for round 2)

Recorded because this epic's history says the second hole is one hop from the
first, and because **both round-1 code fixes are SET WIDENINGS** — the exact
shape of the bd 8h7d.5 F-1/F-3 lesson.

1. **The φ-crossing widening (K) grew all THREE sets computed over
   `railWireClosure`** — R4's intersection, R6's member enumeration, and R6's
   `BaseWire.count(UI)` SKIP set — and that is the answer here, not an omission
   (the reasoning is in `ArmClassify.cpp` at the skip-set line and in finding K).
   Contrast 8h7d.5 F-3, where the two sets had to move APART. **Ask the question
   every time; the answer is not always the same.**
2. **A φ over BOTH a member and the region's own merge φ pulls `MergePhi` into
   the closure BACKWARD, and the forward exclusion does not stop it.** Probed
   and MEASURED (`%p = phi [%a, %merge], [%rm, %b2]` with `%a` a pre-region
   diagonal alias and `%rm` the region's merge φ): `%p` is reached FORWARD from
   `%a` (a new hop), and the backward walk from `%p` then pushes `%rm`. The
   result is a DECLINE (`stale rail record read past a controlled Ry`) — the SAFE
   direction, an over-decline of a shape outside the Inc-1 accept class — but the
   forward exclusion is not a closure-wide one, and a future change that made
   this shape matter would need it to be. Not fixed; recorded with its measured
   disposition rather than left for round 2 to rediscover.
3. **The structural freeze (L) is WIDER than the set it replaced, deliberately.**
   ANY in-place `cqrt_{ry,rz}_<W>_controlled` on a rail freezes it, including one
   in hand-written input IR and including the Rz stem the old set never covered.
   Freezing is the Rule-6-safe direction (a leaked rail, never a dirty free), so
   the widening can only over-leak — and the full suite is byte-identical, so it
   over-leaks nothing today. **What it changes for Inc 2:** the Rz peephole
   inherits the freeze the moment `emitRz`'s controlled arm turns on, which is
   the correct default, but Inc 2 must then decide whether a DIAGONAL controlled
   rotation should be frozen at all (it costs a leaked rail per region) rather
   than discovering the freeze by accident.
   **⚠ AND THE COST IS NOT ONLY A LEAKED RAIL — TWO PREDICATES ALREADY DISAGREE
   ABOUT THE Rz STEM (round-2 review, lens A §4).** `ChainWalk::preservesBasisUnderRecord`
   returns **true** for `cqrt_rz_<W>_controlled` (basis-preserving ⇒ NOT frozen ⇒
   **freeable**), while `railCarriesControlledRotation` returns **true** for the
   same gate (⇒ **frozen**, never freed). One gate, two answers. **The freeze wins
   today**, because it is asked FIRST (`DagTraversal` step 1 and its step-3 rail
   scan both cut before the closure scan that feeds `preservesBasisUnderRecord`),
   and the contradiction is inert only because `emitRz`'s single caller still
   passes `controlled=false`. If Inc 2 resolves the policy by narrowing the freeze
   to the `ry` stem, `preservesBasisUnderRecord`'s `true` goes **live** and becomes
   the only opinion on whether that rail may be freed. Both ends now cross-
   reference each other in source (`ChainWalk.h`'s freeze header and the
   `cqrt_rz_` row in `ChainWalk.cpp`): **change both or neither.**
4. **`railCarriesControlledRotation` is restricted to the ROTATION stems**
   because `isInPlaceGateOn` also admits the iw81.7 guarded QRAM store at arg 1,
   which is NOT frozen (its `_unc` runs while its flag is still live). Any future
   `_controlled` shape added to `isInPlaceGateOn` must be classified here
   explicitly — the restriction is a whitelist, and a new shape falls OUTSIDE it
   silently.
5. **`RoutedBase`'s `WeakTrackingVH` fixes the field, not the class.** The
   `ControlRegion` audit (finding M) found it to be the only field naming a value
   that belongs to another region — but that verdict rested on `Condition` never
   being SHARED by two regions, and the ground Inc 1 gave for that was a
   MEASUREMENT (the shared-compare shape declines `condition predates a
   non-diagonal gate`, loud and gmalloc-clean), with the re-opening condition
   "if that decline is ever narrowed".
   **CLOSED STRUCTURALLY BY THE ROUND-2 REVIEW (lens C §1), and the measurement
   named the WRONG CLAUSE.** What actually fires is `condWireDisposition`'s FIRST
   line, `Cond->getParent() != R.Pred` (`ArmClassify.cpp` ~:896) — `clang -O1`
   CSEs a shared compare into the block that dominates both regions, so for the
   LATER region the compare is not in its `Pred` and it declines there, before the
   wire walk the diagnostic string advertises ever runs. That matters because the
   old re-opening condition pointed a future reader at the wire decline, whose
   narrowing would NOT expose the field, while narrowing the cross-block guard (a
   plausible, independently motivated over-decline fix) WOULD. The row is now
   closed on a proof instead: `classifyArms` calls `condWireDisposition` for every
   `BranchRegion`, an `Instruction` has one parent and a block one terminator, so
   two regions sharing a `Condition` share a `Pred`, share the tainted `br`, and
   are THE SAME REGION. No wire guard is load-bearing for it.


---

## 11. Instruments committed by the round-2 review

Two mechanical checkers, both **committed as INSTRUMENTS and NOT as ctest gates**
(owner cost decision pending; the orchestrator filed the bd task). Each file's
header states what it witnesses, what it CANNOT witness, how to run it, and its
measured cost — read the header, not this table.

| tool | witnesses | cannot witness | cost (measured 2026-09-02, `--jobs 8`) |
|---|---|---|---|
| `tools/inplace_twin_matrix.py` | the increment's whole correctness claim: the in-place stream IS the trusted swap-route stream with the five-line route collapsed, byte-for-byte with handles renumbered. Plus 6 invariants and STRICT stage 2b per cell | **the oracle is Rz, so every Ry-ONLY fence is invisible to it** — R4 and R6 are exactly the fences the `cq_phi` twin is exempt from, so a shape violating R4 emits a byte-identical prefix and is still wrong; also all-pairs ⇒ blind to a 3-way crossing (hence `--triples`); also the `invert` cells link against a SYNTHESIZED `__cq_invert_begin/_end` stub | `--quick` 40 cells **37 s** · `--triples` 198 cells ~3.5 min · full 472 cells (944 pipelines) ~6.5 min |
| `tools/control_flag_order_check.py` | per function, every compare-minted control flag has exactly one mint / strip / free and `mint < every gate < strip < free` — the ONE invariant an emission-order defect breaks, with no golden and no expected table | blind to the UNITARY (right order, wrong angle/register/gate is invisible); only sees compare-minted flags; purely textual; 8 by-design exemptions hard-coded | whole corpus **25 s** (1349 files, 666 lower, 362 flags) · `--quick` **8 s** |

Summary lines from the runs made while committing them:

```
=== TALLY (QUICK, 40 cells) ===
  PREFIX-IDENTICAL           32
  RZ-ONLY(over-decline)       8
```
(0 `PREFIX-MISMATCH`, 0 `RY-ONLY`, 0 `HARNESS-ERROR`, 0 invariant failures; the
8 `RZ-ONLY` are the `launder` consumer, i.e. finding K's R6 true positives, whose
`cq_phi` twin is correctly exempt.)

```
control_flag_order_check: 1349 file(s) [EXEMPT=8, NOT-LOWERED=675, OK=666],
    362 control flag(s) checked, 0 violation(s) in 0 file(s)
```

---

## 12. Round-2 Rule-13 review (2026-09-02) — three lenses, ZERO defects, 14 items closed

Three independent adversarial reviewers ran against the post-round-1 working
tree. **No confirmed silent miscompile, no crash and no confirmed over-accept in
any lens** — the first clean round this epic has had. Read that against round 1
(three defects, two of them CONFIRMED silent miscompiles, two found independently
by two lenses) and against 8h7d.5's 4-for-4 history: a clean round is evidence,
not a licence. What the round DID produce is a list of **written justifications
that had gone false** — the F-1 shape, "the reason is now wrong; the behaviour is
right by accident of another file" — and those are what this pass fixed.

**Lens A — the two round-1 SET WIDENINGS (76 probes, all RUN).** Attacked the
φ/select/freeze forward crossing (finding K) and the structural freeze (finding
L) across the two-level classical launder, all 15 out-of-place base
opcode/width/operand-order cells, and every owner-set cross reachable
(`ControlOwnedRails`, `OutputRails`, `GraveyardRails`, QRAM Shadow, 7.6 tape,
Phase-6 clone, 7.2 controlled return, 7.3/7.4 loops). Both widenings held
everywhere. One PLAUSIBLE structural hole (§1 below) and six stale justifications.

**Lens B — BUILD THE INSTRUMENT (472-cell all-pairs twin matrix = 944 pipelines,
plus a 198-cell 3-way slice = 396 more, plus ~50 hand probe pairs).** 287 accepted
twin pairs are **PREFIX-IDENTICAL and SUFFIX-IDENTICAL**; 0 `PREFIX-MISMATCH`, 0
`RY-ONLY`, 0 `HARNESS-ERROR`, 0 failures across six invariants. All four round-1
reproducers verified fixed. The instrument is mutant-validated (fed the round-1
L3 defect stream it fires on three independent grounds), and **one false positive
was found IN THE INSTRUMENT and fixed** — an adjoint paired to its forward by
callee NAME alone, which is the same "widened one set, not the other" mistake the
compiler keeps making.

**Lens C — PLAN LIFETIME AND EMISSION ORDER after the `WeakTrackingVH` fix (49
probes, every one under `libgmalloc`, every one compiled TWICE for determinism).**
0 faults, 0 non-determinism, identical stream under deliberate block re-layout,
correct across 3- and 4-region chains, mixed region kinds and both Kahn
tie-breaks. Ran a new per-function control-flag ordering check over the whole
fixture corpus: 0 violations outside 8 by-design shapes. Both round-1 L4 defects
are fixed and stay fixed under every composition buildable.

### 12.1 What this pass changed

| # | lens | what was wrong | what changed |
|---|---|---|---|
| 1 | A §1 | the freeze was asked over `D.Rails` while the adjoint is emitted over `D.Calls`, and those sets are documented in-source to be UNEQUAL. The `cqrt_free` half of that gap was closed by bd `uow0` with an explicit intersection; the **ADJOINT half was not**, and Inc 0 made the controlled rotation `isInverseEmittable`, so it acquired a customer. A `@__cq_q_*` clone result is in the difference | **CODE.** `DagTraversal.cpp` step-1 walk now asks `railCarriesControlledRotation` of EVERY WALKED HANDLE, not only of the step-3 rail set. No `continue` (deliberate: `NotClosed` already aborts both drivers, and `planInteriorDischarges` needs the walk to stay a SUPERSET). New fixture `control_inplace_ry_clone_base_frozen.ll` — an ACCEPT pin, honestly labelled as NOT distinguishing the fix |
| 2 | A §2 | `DagTraversal`'s "a rotation's only non-handle operand is a classical angle" — FALSE since Inc 0 (arg 0 of the `_controlled` spelling is an i32 flag handle) | comment restated with the real ground (the flag is deliberately NOT in `taint.Tainted`), naming `GuardedStoreArmEmit.cpp:297` as the emitter that DOES taint its flag, so Inc 2/3 sees the trap |
| 3 | A §3 | `ArithLowering` arm (c)'s "`isInPlaceGateOn` does not match it, so it can never be a member of `D.Calls`" — FALSE for `cqrt_{ry,rz}_<W>_controlled` | comment says which arm is OPERATIVE (arm (a)) and that arm (a)'s own stated ground is not what makes it safe here (the rail is FROZEN and the spine emits nothing) |
| 4 | A §4 | `preservesBasisUnderRecord` (freeable) and `railCarriesControlledRotation` (frozen) give OPPOSITE verdicts for `cqrt_rz_<W>_controlled`, recorded at NEITHER end | recorded at BOTH ends + notes §10.3: the FREEZE wins today (it is asked first), the contradiction is inert only because `emitRz` passes `controlled=false`, and Inc 2 must change both or neither |
| 5 | A §5 | the fact "this register is under a controlled rotation" has TWO spellings at two pipeline phases (`taint.ControlledRotations` pre-`lowerRotations`, the structural query after) and nothing said so | one paragraph in `ChainWalk.h`'s freeze header |
| 6 | A §6 | the freeze also suppresses the spine's own LOUD DECLINES, not just its frees (`collectTerminalCandidates` skips a frozen rail before the terminal is classified) | one paragraph in the same header — a missing diagnostic downstream of the freeze is not a clean bill of health |
| 7 | B §1 | `railWireClosure`'s `Sub` hop comment says the M-C fence "decides later, so nothing here can know which" — FALSE for `sub`: there is **no `cqrt_subc` at any width** (0 hits in `runtime/cq_runtime.h` and `tools/opcode_table.yaml`), so `k - q` is unconditionally out-of-place | comment at all three sites (the block comment + both hop bodies) says the conservatism is UNCONDITIONAL for `sub` and M-C-dependent for `add`/`xor`, and warns whoever narrows it under PRD §11.5 obligation 2 |
| 8 | C §1 | finding M's `Condition` row justified itself with a MEASUREMENT whose diagnostic names the wrong clause (`clang -O1` CSEs a shared compare out of `Pred`, so `condWireDisposition`'s FIRST line fires, not the wire walk) | row rewritten with the STRUCTURAL argument (two regions cannot share a `Pred`, hence cannot share a `Condition`), and §10.5 records that the old re-opening condition pointed at the wrong guard |
| 9 | C §2 | `ControlPlan::InShadow` is populated by NOTHING, stated as a hedge ("empty FOR the 4.1 emitter") that reads as if some other emitter fills it | stated as a measured FACT at the declaration and at the `lowerRotations` read, with the re-scoping obligation for the day something populates it |
| 10 | C §3 | `emitInPlaceRotationRegion`'s `Cls != InPlaceRotation → continue` asserted support for a gate-free sibling arm that does not exist (both processing orders decline `mixed phase/value arm`), and skipping would DROP that arm's gates silently | **CODE.** the branch is now a LOUD `diagnoseUnderControl(Cond, "control flow")`, with the unreachability argument written out. Unreachable ⇒ no behaviour change; the direction is now Prime-Directive-correct |
| 11 | C §4 | the "recorded then erased" `RoutedBase` decline is unfixturable and undocumented | documented as a kept backstop with C's own refutation attempt: every merge-φ collapse RAUWs first, every erase-without-RAUW site is `use_empty`-guarded or is a block whose values dominate nothing outside it, and `Value::~Value` NULLS a `WeakTrackingVH` (so poison cannot slip past a null test) |
| 12 | C §6 | the two-gate IF/ELSE hoist had ONE standalone fixture and no COMPOSITION test — and composition is the axis both round-1 L4 defects lived on | new fixture `control_inplace_ry_ifelse_classical_between.ll` |
| 13 | B §2 / B §3 | two over-decline records in §8.2 were wrong in opposite directions, and the `cq_invert` one understated the behaviour | §8.2 items 1-3 rewritten (see below) |
| 14 | A §7 | `isInPlaceGateOn`'s controlled row names three consumers, but **six emitters** rely IN WRITING on `isTerminalHandle` being false for a rail *because it has a `_controlled` consumer*, and they survive this widening only because `if (N.contains("_controlled")) return false;` still catches `cqrt_copy_<W>_controlled` / `cqrt_cswap`. Nothing pinned that | the six are now named by `file:line` in the row (`SelectMergeEmit:224`, `SwitchValueEmit:196`, `SwitchDataMuxEmit:31`/`:140`, `SwapRouteEmit:342`, `ClassicalCallArmEmit:205`, `LoopLowering:1442`), with the consequence spelled out: the next `_controlled` stem admitted there is a Rule-13 change to SIX emitters, not a local one |

### 12.2 B §4 — the L4 reproducer trap, stated correctly

B reported that L4's `p34`/`p49` C spellings are DCE'd by `clang -O1` because
`g()` gets `memory(none)`, and therefore are not the "classical branch between"
shape. **Re-measured on L4's own artifacts, and the finding is about B's
RECONSTRUCTION, not about L4's reproducers or the committed fixtures:**

* L4's `p34_eqfold_classical_between.c` / `p49_ry_classical_ry.c` declare
  `extern void g(void);` with **no definition in the TU**, so `-O1` cannot delete
  the call. Their stage-1 IR has the classical diamond intact (three `br i1` in
  `p49.s1.ll`, with `tail call void @g()` in the middle block).
* B's `hand/p49.c` ADDS `void g(void){}` and a `main` — which its link-and-run
  harness needs — and **that addition is what let `-O1` fold the branch** (B's
  `p49.ll` has two `br i1`, no diamond).
* **Both committed fixtures are hand `.ll` fed straight to `cq-opt`, and both
  contain the classical diamond literally** — verified by reading them:
  `control_swap_eqfold_classical_between.ll` (`br i1 %cz, label %cjoin, label
  %cbody` + `call void @g()`) and
  `control_inplace_ry_sequential_classical_between.ll` (same shape at :53-55).
  There is no `clang -O1` in their path, so the DCE trap cannot reach them. **No
  rewrite was needed and none was made.**

The generalizable lesson is B's, and it stands: *adding a same-TU definition to
make a reproducer link changes the program being tested.* Anyone re-running an
archived C reproducer under a link-and-run harness must check the stage-1 IR
still has the shape the finding describes.

### 12.3 Gates run for the round-2 fix pass

Run on 2026-09-02, on the final tree. **Report only what was run** (Rule 19):
this list is exhaustive.

| gate | command | result |
|---|---|---|
| build (BOTH targets — never `--target CQPass` alone) | `cmake --build build -j8` | clean |
| the `control_inplace` family, as the inner loop | `cd build && lit ir-pass/test --filter control_inplace` | **55/55 PASS**, 2.5s |
| `ir-pass-lit`, whole entry | `ctest --test-dir build -R ir-pass-lit` | **PASS**, 1349 fixtures (1 XFAIL), 30.6s |
| **full suite** (Rule-19 moments 1 AND 5: a Rule-13 lowering-core change AND an accept/decline predicate change — the `Cls != InPlaceRotation` branch became a decline) | `ctest --test-dir build -j6` | **295/295 PASS, 0 failed** — run THREE times over the pass (240s / 290s / **354s on the FINAL tree**), each after a rebuild of BOTH targets |
| `cq_opt_equivalence` FULL sweep (PRD §9.1 — the diagnostic surface changed again) | `cmake --build build --target cq-opt-equivalence-full` | **compared 1349 fixtures, 0 mismatch(es)** — also run three times, the last on the final tree |
| the round-2 twin instrument, smoke subset | `python3 tools/inplace_twin_matrix.py --quick --jobs 8` | **40 cells: 32 PREFIX-IDENTICAL, 8 RZ-ONLY(over-decline)**; 0 `PREFIX-MISMATCH`, 0 `RY-ONLY`, 0 `HARNESS-ERROR`, 0 invariant failures, 37s. Re-run identically on the final binary |
| the round-2 ordering instrument, whole corpus | `python3 tools/control_flag_order_check.py` | **362 control flags checked, 0 violations** (1349 files, 666 lower, 8 by-design exempt), 25s. Re-run identically on the final binary |

The 240s / 290s / 354s full-suite figures sit at and above CLAUDE.md's quiet-box
130–230s band. No box state was controlled, and a 114s spread across three runs
of a tree that differs only in COMMENT TEXT is the ordinary load/cache spread
CLAUDE.md warns about — do not read it as a cost of this pass. Compare two runs
only under the same load.

**Layers NOT run:** none of the above was skipped. The two `tools/` instruments
are NOT ctest entries and were run by hand, as recorded.

**Red→green NOT available for two of the four code-touching changes, and that is
stated rather than papered over:**

| change | red→green? |
|---|---|
| the step-1 freeze query (`DagTraversal`) | **NO — and the fixture says so in its own header.** The emitted stream is byte-identical with and without it on every shape reachable today, because the caller's spine already refuses a clone-call DAG on an independent route. It is a structural second route to the same Rule-6-safe outcome, pinned by a code read. |
| `Cls != InPlaceRotation` → loud decline | **NO — unreachable by construction** (both if/else processing orders decline `mixed phase/value arm` at classification; a diamond's sole arm is `InPlaceRotation` or the emitter was not dispatched). The change is a direction fix, not a behaviour fix; the whole suite is byte-identical. |
| `control_inplace_ry_ifelse_classical_between.ll` | **YES, by construction** — it is finding M's geometry with two gates; the pre-`WeakTrackingVH` code declined `control flow` on exactly this pair. |
| every other edit in this pass | comment-only. |
