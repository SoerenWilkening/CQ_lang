# Brief — bd `test_C_libtooling-r9e5`, sub-increment 1b-B.1: the 4.4 DATA select on a bare `_Bool` (rail-root) condition

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-10, branch `3qlq-inc1b-b-rail-select` (off `main` 87d0699).
Written by the orchestrator for the implementation agent. Everything here is a DECISION unless marked "measure".

## 0. What the owner's program is, measured

`docs/prd/phase-04-swap-route-control/inc1-records/session-3qlq4/user_file_as_of_2026-09-10_close.c`
(`main()`: `int a = 5; bool b0 = 0; if (a >= 3) b0 = cq_theta(b0, 0.5); if (b0 == 1) a -= 3;
return cq_measure(b0) + cq_measure(a);`) arrives from `clang -O1` as

```
%1 = tail call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
%2 = select i1 %1, i32 2, i32 5
%3 = tail call zeroext i1 @cq_measure_i1(i1 %1)
%5 = tail call i32 @cq_measure_si32(i32 %2)
```

— the classical guard folds away, `a` is live through `cq_measure`, and the select's condition is the
rail itself (`isCondRailLeaf`). On `main` b00fdc2 / 87d0699 it declines
`cq controlled lowering: bare i1 register condition under quantum control` from
`SelectClassify.cpp:967` (the line after the angle-select hand-off). That is exactly bd `r9e5`'s data-select
half. THIS sub-increment builds the DATA SELECT ONLY. The value arm (`if (b) a = a + 3` on a quantum `a`,
through `classifyArms` → `emitValueRegion`) and the 6.5 classical-call arm (`ClassicalCallArmEmit`, its own
`lowerCompareToFlag` mint) are sub-increment B.2 — do NOT widen `classifyArms` or `classifyClassicalCallArm`
here; `control_swap_reject_value_rail_cond.ll` must stay a decline with its string unchanged.

## 1. The lowering — DECIDED: a CNOT-copied ancilla flag; the merge stream stays the cleared one VERBATIM

The 4.4 stream (`SelectMergeEmit.cpp` steps 1–6, Rule-13-cleared, byte-pinned by the `control_swap_select_*`
fixtures and the `slice_control_select*` goldens) needs a `cqrt_x` bracket on the FLAG for the ¬-copy. A rail
root is the USER'S register and may never carry a `cqrt_x` — bd memory `diagonal-only-on-user-registers-3qlq4`
names the three lowered-stream predicates that go wrong or over-freeze (`Uncomputation::preservesBorrowedParent`
fails CLOSED on anything it does not name; `ChainWalk::isInPlaceGateOn` never recovers `cqrt_x`; every
`ArmClassify` wire fence argues from "no non-diagonal gate on any condition register"). The phase path escaped
this with the diagonal identity `X·P(θ)·X = e^{iθ}P(−θ)`; a controlled COPY has no diagonal form for its
¬-half. Three candidates were weighed; the decision is (a):

* **(a) DECIDED — the flag is a CNOT copy of the rail, minted and stripped by the network.** When
  `emitCondNetwork`'s root is a rail leaf AND the caller asks for a bracket-able flag, mint
  `f = cqrt_alloc_i1(0); cqrt_cnot(h_b, f)` and hand `f` back as `Net.Root`; the strip emits
  `cqrt_cnot(h_b, f); cqrt_free(f)`. The merge stream between them is the shipped one, instruction for
  instruction, with `Flag = f`. Analytic argument (Rule 2, not `opt -verify`): after `cnot(b,f)` the pair is
  `Σ α_x |x⟩_b |x⟩_f`; `copy_c(f,T,out)` writes `T` iff `x=1`, the X-bracketed `copy_c(f,F,out)` writes `F` iff
  `x=0`, `b` is untouched throughout (the copies write `out`, the brackets act on `f`), so the second
  `cnot(b,f)` returns `f` to `x ⊕ x = 0` on EVERY basis branch — a proven-`|0⟩` free (Rule 6). Net:
  `|b⟩|out = b ? T : F⟩`, the same unitary the compare stream realizes with `c(x) = b`. Gates that TOUCH the
  register are two `cqrt_cnot(h_b, ·)` with the register at arg 0 — a READ-ONLY control, the SAME gate class
  the Inc-1b nest already emits on a rail (`cnot(h_b, g)` / `toffoli(h_b, f, g)` in the OR/XOR/AND node
  emission, Rule-13-cleared in §13.6/§13.7). No new gate class on a user register; no new gate class in the
  merge; the bracket-order invariants (`swap-route-select-merge-invariants` (3)) and the `XCT` count pins carry
  over unchanged.
* (b) REJECTED — a `cqrt_x` bracket on the register: re-argues the three predicates against a bracket GROUP,
  which is the `RestoringRoutes`/`routeGroupFullyInside` machinery drbq Inc 2a replaced with pointwise
  reasoning. The diagonal-only memory is explicit: do not.
* (c) REJECTED for THIS increment — the CNOT identity `¬b·F = F ⊕ b·F` (`copy_c(b,T,out); copy(F,out);
  copy_c(b,F,out)`), no ancilla, fewer gates. It puts an UNCONTROLLED `cqrt_copy_<W>(F, out)` into a control
  emitter: `ChainWalk::isCopyOutSink`/`recordsIntoKeptCarrier` (bd 5pio) FREEZE a copy-out SOURCE's whole
  chain, and stage 2b's `_COPY_SINK` seeds it as a recorded rail — for a quantum `F` (the value-arm shape
  `select b, a+3, a`, or `b ? q+1 : q`) that changes which intermediates the whole-DAG spine may discharge
  (Inc 2 relies on the chain's INTERMEDIATES being `_unc`'d with only the FINAL left allocated). A disposition
  change on B.2's own shape, reached through two predicates that were not written for it. Record it as an
  owner option (fewer gates, one uncontrolled copy) in the PRD section, not as a defect.

The mint/strip live in `CondTreeEmit` so B.2's emitters get the ONE spelling (Rule 14): add a parameter
`bool CopyRailRoot` (default `false`) to `emitCondNetwork` and a `CondNetwork` record of the pair
(e.g. `Value *RailRoot = nullptr; Value *RailRootFlag = nullptr;`); with `CopyRailRoot && RootIsRail`, mint the
ancilla AFTER the tree walk (a bare rail root has no nodes and no compare leaves, so it is the only thing
minted), set `Out.Root = f`, keep `Out.RootIsRail = false` (the root handed back is an ancilla, and the phase
emitters — which never pass `CopyRailRoot` — keep reading `RootIsRail` exactly as today), and let
`stripCondNetwork` strip it FIRST (it was minted LAST; LIFO). Every existing caller passes nothing and is
byte-unchanged — measure that: the 4.4 select goldens, the phase-bool goldens and every
`control_phase_*`/`control_swap_select_*` fixture must not move. A NON-root rail leaf (`b != c` as
`xor i1 %b, %c`; a rail inside an `and`/`or` tree) already works with the shipped stream — the root is a node
ancilla, the rails are read-only controls of its cnots/toffoli — and needs NOTHING new in the emitter.

The i1 ancilla is minted exactly as the node ancillas are (`wd.allocFn("i1")`, name it `bf` or similar so the
trace reads), NOT added to `taint.Tainted` (its only users are `cqrt_*` calls — the same treatment every flag
and node ancilla gets), `!dbg`-stamped like the rest.

## 2. The classifier — `classifySelectRegion` (`SelectClassify.cpp`), the rail-leaf ladder

Replace the `if (!Tree.RailLeaves.empty()) return diagnoseUnderControl(Sel, kBareRailCondReason);` AFTER the
angle-select hand-off with a ladder asked PER RAIL LEAF (root or not), mirroring PRD §13.3 for the kickback
but with the SELECT as the read point (the emitter inserts every gate immediately before `Sel`,
`IRBuilder<> B(Sel)`):

1. tainted — already asked in gate 2; keep.
2. **not measured before the select** — `railMeasuredBeforeBranch` (`ArmClassify.cpp:1825`, file-local) takes
   `Pred` and treats ANY same-block measure as "before" because its read point is the block terminator. A
   select reads MID-block, so a same-block measure must be tested POSITIONALLY (before `Sel` → decline; after →
   fine), and a measure elsewhere by `isPotentiallyReachable(M, Sel, nullptr, DT)` exactly as the existing
   helper does. Generalise the helper to a read POINT (`const Instruction *ReadPoint`) rather than writing a
   second spelling (Rule 14): export it from `ArmClassify` (or move it to a shared header the two TUs already
   include), and make the kickback's call pass `Pred->getTerminator()` so its behaviour is byte-unchanged.
   String: `condition measured before the control route` (the compare path's / 13.3 item 2's).
3. **the wire question** — gate 2c today seeds the rail into `Prov` and asks
   `findNonDiagonalWireGate(Seeds, CrossValueRouting=true, EmitPoint=nullptr, DT=nullptr, &taint)`,
   POSITION-FREE, which is why `k3_flat_sdagger.c` (`if (b) a -= 3; b = cq_theta(b, -0.5);` — the S† the
   owner's Grover cascade writes) declines `condition predates a non-diagonal gate` on `main` (measured, see
   `probes/`). For a RAIL root use the DT prong exactly as `railCondWireDisposition` does
   (`ArmClassify.cpp:1797`): position-free `None` → accept; else no `DT` → decline; else
   `findNonDiagonalWireGate(Seeds, true, /*EmitPoint=*/Sel, DT, &taint)` — a gate NOT provably after every
   execution of the select declines, a gate proven after is `ProvenPostRegion` and ACCEPTS (the P1 argument:
   the copies read `b`'s label at `Sel`, the flag is stripped and freed inside the stream, nothing of the
   region survives on `b` for a later gate to invalidate; `WireWalk.h`'s proof obligation "IF B executes, A
   has already executed and never runs again" is loop-safe — `k1`/`k2` in `probes/` MUST keep declining, and
   `k3` must accept). Keep the COMPARE leaves' walk position-free and the same-block prong (c) exactly as they
   are — this is a widening for RAIL seeds only. If a tree mixes compare leaves and rail leaves, ask the
   compare seeds position-free and the rail seeds with the DT prong (two calls; a tree with rail leaves is
   `condWireDisposition`'s unchanged case on the kickback path, but the select has no `Region`, so spell it as
   two seed sets here and say so).
4. **its other users are ordinary** — no `hasOneUse`, no `ShareCondFlag`, no "used outside the branch" fence
   for a rail (it is the user's register). The angle hand-off ordering is unchanged: the Rz-stem angle select
   on a rail still lowers (`control_angle_select_phase_rail.ll`), the Ry stem still declines
   `kBareRailCondReason` inside `classifyAngleSelect` (1b-C — do not touch).
5. Gates 4 (width), 5 (coherent-operand, both halves — asked of the ARM operands; a rail CONDITION with a
   downstream rotation is fine, as a compare's register is) and 6 (operand alias) apply UNCHANGED. Do not add
   an "arm operand aliases the condition rail" decline unless a probe shows a wrong stream — with the ancilla
   form the control `f` and any source are distinct rails, exactly as for a compare flag, and
   `Toffoli(f, h_b, out)` is CASE A of the aliased-operand ruling (bd big5).
6. `AllowLogicalSelect` stays `false` for the data select (`control_swap_reject_select_i1sel_combinator.ll`
   is a shipped decline — `b && q == 5` as a DATA-select condition keeps declining `control flow`; filed).

`kBareRailCondReason` must survive at every OTHER site (`classifyArms`, `classifyAngleSelect`'s Ry stem,
`emitSelectRegion`'s drift guard is now REPLACED by the accept — make the guard the OPPOSITE: if the plan
reaches the emitter with a rail root and the network did not hand back an ancilla, bail LOUDLY with
`control flow`, never silently). Grep every use and decide each explicitly.

## 3. Rule 12 — red-green, in this order

1. `git mv ir-pass/test/control_swap_reject_select_rail_cond.ll ir-pass/test/control_swap_select_rail_const.ll`
   and rewrite it as the ACCEPT its header anticipated: an ORDERED `CHECK` of the whole stream (`alloc_i1(0)`
   → `cnot(h_b, f)` → `alloc out` → `copy_c(f, t, out)` → `x(f)` → `alloc(5)` → `copy_c(f, fl, out)` → `x(f)`
   → `cnot(h_b, f)` → `free(f)`), whole-file negatives in their OWN prefixes (`NOROUTE-NOT: cqrt_cswap`,
   `NOX-NOT: cqrt_x(i32 %h_b` — no `cqrt_x` on the REGISTER, `NOUNC-NOT: _unc`), and exact COUNTS in their own
   prefixes (`XCNT` = 2 `cqrt_x`, `FCNT` = 1 `cqrt_free`, `CNCNT` = 2 `cqrt_cnot`, `RYCNT` = 1). Derive handle
   names from the pass output, never guess. Watch it fail on the pre-change binary. Reuse ONE `%cq-opt` run
   per fixture (`> %t.ll`, one `--check-prefix` per FileCheck over the same file — never a second `opt`
   spawn; CLAUDE.md Build & Test).
2. Write the DECLINE fixtures FIRST for every rung of §2 that can fire (each mirrors its string
   character-for-character on a `RUN: not …` line; a `DS_Error` decline writes 0 bytes to stdout so IR
   negatives are vacuous — say so in the header, as the shipped rail fixtures do):
   `control_swap_reject_select_rail_measured_before.ll` (measure of `b` before the select, same block),
   `..._measured_sidepath.ll` (a classically-guarded measure that can precede it — F-1b-2's shape),
   `..._stale_sibling_theta.ll` (`b = θ(t); c = θ(t); select b …` — the F-1b-1 class),
   `..._stale_chained_between.ll` (`%b = θ(u); %c = θ(%b, ·); select i1 %b …` — the stale-name spelling),
   `..._inloop_stale_theta.ll` (a same-body theta on the rail's wire — `k1` transcribed; must stay a
   decline), `..._trunc_cond.ll` and `..._phi_cond.ll` (a derived/loop-carried `i1` is NOT a rail leaf —
   `control flow`, the discriminator), and the Ry-stem angle select on a rail (already
   `control_angle_select_reject_rail_ry.ll` — keep it green, cite it).
3. ACCEPT fixtures, each with the same whole-file negatives and counts and an injection-matrix mindset (an
   injected `cqrt_x(i32 %h_b …)`, an extra `cqrt_free`, an extra `cqrt_ry` on the register, a `cqrt_cswap`
   must each turn at least one prefix red — measure it by editing the pass output, as the Inc-1b fixtures
   did): `..._rail_const.ll` (above), `..._rail_quantum_arm.ll` (`b ? q : 9`, the flagship 4.4 shape on a
   rail), `..._rail_qq_arms.ll` (`b ? q+1 : q`), `..._rail_post_ry.ll` (`k3`: select then a chained Ry on
   `b`, the DT-prong accept — pin the ORDER: copies, cnot strip, free, THEN `cqrt_ry(h_b, -0.5)`),
   `..._rail_measure_after.ll` (measure of `b` AFTER the select in the same block accepts),
   `..._rail_cross_block.ll` (rail defined in another block — the compare's `hoisted compare` over-decline
   does not apply), `..._rail_two_regions.ll` (`if (b) a -= 3; if (b) cq_phi(.9);` — select + kickback on one
   rail, the emission-order test), `..._rail_then_select.ll` (two selects on one rail), `..._rail_in_xor_tree.ll`
   (`(b != c) ? 2 : 5` — a NON-root rail leaf, the shipped stream with the rails as read-only cnot controls,
   NO ancilla copy — pin `CNCNT` and the absence of the copy), `..._rail_fp_data.ll` (`b ? 1.5 : 2.5`, the
   kjd1 fp-data copy family on a rail), `..._rail_i1_data.ll` (`b ? c : d` with `c`,`d` rails — the width-i1
   copy, and the one place `select i1 %b, i1 %c, i1 %d` is DATA, not a logical node: pin that
   `decomposeCondNode` does not claim it), `..._rail_inloop_invariant.ll` (an invariant rail with a select in
   a classically-bounded loop, no gate on the rail — accepts, and the ROLLED stream mints/strips the ancilla
   per activation), `..._rail_dead_register.ll` (`b` never measured after the select — LEFT ALLOCATED, `FCNT`
   1, the Rule-6 direction; measure what the spine does with `h_b`'s two `cqrt_cnot` users and say it in the
   header).
4. Implement minimally: `CondTreeEmit.{h,cpp}` (mint/strip + the two `CondNetwork` fields), `SelectMergeEmit.cpp`
   (pass `CopyRailRoot=true`; replace the drift guard), `SelectClassify.cpp` (the ladder), `ArmClassify.cpp`
   (generalise/export the measured-before helper). Nothing in `SwapRouteEmit`, `AngleSelectEmit`,
   `ClassicalCallArmEmit`, `Specialization`, the runtime, the YAML, `include/`.
5. Rebuild BOTH targets (`cmake --build build -j8` — never `--target CQPass` alone; a stale `cq-opt` reports
   FALSE GREEN, measured), run the family with `lit --filter`, then `ctest -R ir-pass-lit`, then
   `ctest -j6 -R '^e2e-'`. Report the numbers you ran, only those.

## 4. e2e slices (all STRICT stage 2b, registered in `tests/e2e/CMakeLists.txt` after the `phase_bool` group,
naming `slice_control_select_bool_*`)

* `slice_control_select_bool.c` — the owner's `main()` VERBATIM (keep the two `bool` declarations and the
  classical guard; header rewritten to say what `-O1` makes of it and what the trace is), the flagship.
* `slice_control_select_bool_int_twin.c` — `int b0 = 0` instead of `bool`, otherwise identical: lowers through
  the COMPARE path (`icmp eq i32 %b0, 1`). NOT byte-identical (the mint is a template + `_unc` where the rail
  form has `alloc_i1; cnot` / `cnot`) — state the reduction in the header, as `slice_control_phase_bool_int_twin.c`
  does; NO `compare_files` gate (a gate would assert something false — the Inc-4 precedent).
* `slice_control_select_bool_quantum_arm.c` — `b ? q : 9` (the `slice_control_select.c` shape on a rail).
* `slice_control_select_bool_sdagger.c` — `k3` (select, then `b = cq_theta(b, -0.5)`, measure both).
* `slice_control_select_bool_two_regions.c` — select then kickback on the same rail.
* `slice_control_select_bool_loop.c` + `_unrolled.c` + a `compare_files` gate `e2e-select-bool-loop-twin-identical`
  (an invariant rail, `for (i<3) { if (b) a -= 3; }` … hmm — `a -= 3` in a loop makes `a` loop-carried and the
  select's false arm the header phi; measure what `-O1` produces before committing to this pair, and if the
  rolled form declines for a loop reason that is not this increment's, DROP the pair and record why).

Goldens are generated from the SUBJECT binary, read line by line against the analytic stream in §1 before
committing (a golden is a self-consistent record, Rule 2), and every slice must pass stage 2b STRICT.

## 5. Probe family and record

Transcribe every fixture shape above as plain C into `docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/probes/`
(prefix `s`), plus the Inc-1b `p08`, `p09`, `p12`, `p16` and `q08` reruns, and produce `probes/README.md` in
the `session-3qlq4/probes/README.md` format (file · shape · verdict on `main` 87d0699 · verdict on the branch ·
trace lines · 2b). `p09` (value arm) and `p12` (Ry angle select) MUST still decline with their strings; `p16`
(the cascade with a quantum `a`) declines on F2 — not ours, cite HANDOFF Q4/Q6. Re-run the owner's file last
and record its trace in the README.

Write `docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/IMPL_B1.md`: what changed (file:line),
the analytic argument, every measurement with its command, the fixture/slice/golden counts (measured with
`ls … | wc -l`, `ctest -N`), and anything you could not do or had to decide. Draft PRD `§14` for
`retire-swap-route-PRD.md` in the §13 style (shape → lowering → ladder → decline partition → measured) as
`PRD_14_DRAFT.md` in the same directory; the orchestrator merges it.

## 6. Non-negotiables

* Never a `cqrt_x`, `cqrt_ry`, `cqrt_cswap` or any `_unc` on a user register from this emitter. Never
  `cqrt_free` a rail you did not mint at `|0⟩` and return to `|0⟩` on the line above.
* No new runtime symbol, no YAML/`include/` change (owner D3).
* A decline is not the escape hatch for the shape we are building (Rule 17); a shape OUTSIDE it declines
  loudly, never silently (Rule 1). If the DT prong or any rung proves ambiguous, stop and write the question
  in `IMPL_B1.md` rather than shipping a guess either way.
* Do not commit. Leave the tree building and the listed layers green; the orchestrator commits, runs the
  full `ctest -j6`, and launches the Rule-13 review.
* `cp -f`/`mv -f`/`rm -f` always. Tools: `/usr/local/opt/llvm@19/bin/{clang,opt,FileCheck}`, `build/ir-pass/cq-opt`.
