# review_r1_L5 — Rule-13 ROUND 1, lens L5 (IN-LOOP PER-ACTIVATION), bd test_C_libtooling-3qlq Inc 1 part A

SUBJECT `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`), binaries
`build/ir-pass/{cq-opt,libCQPass.so}`, archives `build/runtime/*.a`, header `include/CQ.h`
(the new `void cq_phi(double)`).
ORACLE `$SP/wt/pre-3qlq` @ `52d7764`, binaries `$SP/wt/pre-3qlq/build/ir-pass/{cq-opt,libCQPass.so}`.
Every program below went through the FULL pipeline (clang -O1 → cq-lowering → STRICT
`free_pairing_check.py` → link → run) on the binary named; the oracle spelling is the same
program written `q = cq_phi(q, θ)` where one exists. Runner: `$SP/progress/review_r1_L5/run.sh`.
Reproducers: `$SP/progress/review_r1_L5/probes/` (subject) and `.../probes/oracle/` (oracle).
READ-ONLY: nothing in `ir-pass/`, `tests/`, `include/` was touched.

---

## F-L5-1 — CONFIRMED-MISCOMPILE (the round's headline for this lens)
### D4's per-bit idiom, ROLLED, leaks ONE ENTANGLED derived-condition rail PER ACTIVATION; its hand-unrolled twin discharges it; the pre-3qlq ORACLE emitted the discharging stream for the SAME program.

**Claim.** `for (i < K) if ((q >> i) & 1) cq_phi(θ);` — the idiom `include/CQ.h:61` and owner
decision D4 designate as THE (only) way to express a register-wide Z rotation — emits, per
trip, `cq_template_and_i32_hl(h0, 1<<i) -> hA` and never `_unc`-reverses or frees `hA`. The
hand-unrolled spelling of the same source discharges and frees all K. `opt` exits 0,
STRICT stage 2b reports `0` on both sides, and the rolled trace is EXACTLY the unrolled
trace minus the K discharge pairs. That is the 8h7d.5 **F-4 signature verbatim** — it is
written out, with this exact opcode, in `tools/free_pairing_check.py:412-432`.

**Reproducers.**
- subject rolled `…/probes/j_perbit4_rolled.c` (K=4), `…/probes/j2_perbit32.c` (K=32)
- subject unrolled twin `…/probes/j_perbit4_unrolled.c`
- ORACLE, register surface, same idiom: `…/probes/oracle/m_perbit_old_{rolled,unrolled}.c`
- prep-b's OWN committed slices, run on the SUBJECT: `…/probes/prepb/slice_control_phase_perbit_loop{,_unrolled,_k32}.c`

**Measured (K=4).** `diff j_perbit4_rolled.trace j_perbit4_unrolled.trace`:

```
8a9,10
> cq_template_and_i32_hl_unc(h1, h0, 1)
> cqrt_free(h1)
15a18,19
> cq_template_and_i32_hl_unc(h3, h0, 2)
> cqrt_free(h3)
22a27,28
> cq_template_and_i32_hl_unc(h5, h0, 4)
> cqrt_free(h5)
29a36,37
> cq_template_and_i32_hl_unc(h7, h0, 8)
> cqrt_free(h7)
```

counts, rolled / unrolled: `and_i32_hl` 4 / 4 · `and_i32_hl_unc` **0 / 4** · `cqrt_free` **4 / 8**.
At K=32 (`j2_perbit32.c`): `and` mints **32**, `and…_unc` **0**, and STRICT stage 2b still
prints `2B=0`.

**The same diff on the ORACLE is EMPTY.** `diff oracle/m_perbit_old_rolled.trace
oracle/m_perbit_old_unrolled.trace` → **IDENTICAL**. The oracle's ROLLED lowered IR
(`…/probes/oracle/out_orac/m_perbit_old_rolled.s2.ll`) and the subject's
(`…/probes/out_subj/j_perbit4_rolled.s2.ll`) have the SAME block structure, the SAME loop,
the SAME condition chain; the only difference is the arm gate:

```
ORACLE  (52d7764, register surface)          SUBJECT (fa96336, void surface)
  %h_op = and_i32_hl(%h, %4)                   %h_op = and_i32_hl(%h, %4)
  %h_cmp = icmp_eq_i32_hl(%h_op, 0)            %h_cmp = icmp_eq_i32_hl(%h_op, 0)
  x; rz_i32_controlled(%h_cmp,%h,.3); x        x; rz_i1(%h_cmp, .3); x
  icmp_eq_i32_hl_unc(%h_cmp, %h_op, 0)         icmp_eq_i32_hl_unc(%h_cmp, %h_op, 0)
  and_i32_hl_unc(%h_op, %h, %4)   <== present  (absent)
  cqrt_free(%h_op)                <== present  (absent)
  cqrt_free(%h_cmp)                            cqrt_free(%h_cmp)
```

**Analytic argument (what the correct unitary is vs what the trace does).** The source names
a DIAGONAL operator: `|x> -> e^{iθ·popcount(x & (2^K−1))} |x>`. The unrolled stream realizes
exactly that (each ancilla is minted, phased through the flag, and un-minted). The rolled
stream realizes that phase TENSORED WITH a copy-out of K of `q`'s bits into K fresh rails
that are never disentangled. Those two operators are equal only if nothing ever interferes
`q`'s branches again — and this idiom exists precisely to be a Grover phase oracle, whose
next step is a diffusion that mixes different `x`. After the mix, K dangling rails still hold
the PRE-mix basis label, so the branches that must interfere carry distinct ancilla labels
and the interference is destroyed. Rule 8 states this in one line ("a permutation that leaves
a rail dirty **and entangled** still dephases under later interference"). The leak is
therefore not a Rule-6 "safe leak" in the sense the implementer's hand-back invokes; it is a
different unitary from the twin, and from what the oracle emitted for the same source intent.

**Why every shipped gate is silent on it, MEASURED, not argued.**
`opt` exit 0 · `opt -verify` clean · STRICT `free_pairing_check.py` `0 violation(s), 0 unproven`
(its own header, lines 412-432, says why: "the leaked rail has no `cqrt_alloc`, so `minted` did
not count it and `leaked` could not report it … the instrument that DOES see this class is the
rolled-equals-unrolled byte-diff"). The implementer's hand-back
(`$SP/progress/impl_inc1a.md`, Steps 2+3) records the leak and clears it with
"the `and` rail is left allocated, Rule 6, **and stage 2b agrees**" — citing the one
instrument that file says is blind to exactly this, and never comparing against the twin or
the oracle.

**This is already a committed RED gate.** prep-b (branch `3qlq-inc1-slices`) has committed
`slice_control_phase_perbit_loop{,_unrolled,_k32}.c` and the ctest entry
`e2e-phase-perbit-loop-twin-identical`, a `cmp` of the two goldens
(`$SP/wt/prep-b/tests/e2e/CMakeLists.txt:4629-4632`). Running prep-b's own two slices through
the SUBJECT gives traces that differ by the same 8 lines — the gate is red the moment its
goldens are generated. `_k32` would ship a golden with 32 leaked rails.

**Root cause, located.** `Uncomputation.cpp:1320`
`if (canRepeat(&BB) && !taint.IterationLocalBlocks.count(&BB)) continue;` — the interior-rail
candidate is SILENTLY SKIPPED (no diagnostic) when its block repeats and the loop was not
marked iteration-local. The mark never happens for this shape: `LoopLowering.cpp`'s
`markIfRailLocal` (line 2801) and `markIfIterationLocal` (line 2301) both `return` on
"a tainted OPERAND defined outside `L` that is not on a rail", and under the void surface a
kickback body has NO gate on `q`, so `q` is a loop-INVARIANT tainted operand and no rail
exists. Under the register surface the arm's `q = cq_phi(q,θ)` made `q` a loop-carried rail,
`tryCaseA` claimed the loop, `markIfRailLocal` marked the body, and the discharge happened —
which is why the oracle is clean. Controls that isolate this: `…/probes/k_derived_rolled.c`
(derived `(q & 6) == 4` condition, but `q` gated in the body → **discharges, byte-identical
to its twin**) and `…/probes/l_perbit_ry_rolled.c` (the per-bit mask AND an `q = cq_theta`
in the body → **discharges, byte-identical**). So the trigger is precisely
*kickback region + derived condition + register not gated in the loop body*.

**Proposed fix (Prime Directive first).** The safe minimum is a LOUD decline, not a widening:
at `ArmClassify.cpp:3709` (`classifyPhaseKickback` step 7, the P6 admission) an in-loop
kickback whose condition is NOT a direct compare on a value the loop body gates — i.e. whose
condition chain mints a template rail inside `L` while the loop is not in
`taint.IterationLocalBlocks` — must decline rather than accept. (Marking the body
iteration-local instead is the capability fix, but `markIfRailLocal`'s own comment at
`LoopLowering.cpp:2862-2874` warns in terms that widening that clause "makes it reachable, and
no shipped test would go red" — so it is a separate increment with its own Rule-13 round, not
a patch here.) Whichever is chosen, `Uncomputation.cpp:1320`'s skip should not stay silent for
a rail a control emitter's own condition chain minted.

**Pinning fixtures.** (a) an `ir-pass/test/control_phase_kickback_reject_inloop_derived_cond.ll`
mirroring the chosen string character-for-character; (b) keep prep-b's
`e2e-phase-perbit-loop-twin-identical` `cmp` gate — it is the only instrument that sees the
class, and it must be GREEN, never regenerated apart; (c) a `loop_twin_matrix` cell with a
per-bit / induction-variable-masked REGION (the matrix has no such axis today, which is why
the class is invisible to it — see F-L5-2).

---

## F-L5-2 — CONFIRMED (new population on a filed defect): the void twin matrix shows **14 NON-QUARANTINED rolled≠unrolled divergences on the subject and ZERO on the oracle**

**Claim.** `tools/loop_twin_matrix.py --phi-surface void` (prep-d's build, branch
`3qlq-inc1-matrix`) over its 274 cells reports, on the SUBJECT, 14 `TRACE-DIVERGENCE` cells
that are NOT in `tools/loop_twin_matrix.quarantine.txt`. The tool's own contract calls that a
hard failure ("A NON-QUARANTINED DIVERGENCE IS STILL A HARD FAILURE — which is the half that
matters"). On the ORACLE the same mode reports 13 divergences, ALL of them quarantined and
none new (prep-d's measurement, `$SP/progress/prep_d_out2/loop_void.tbl`, which I re-read
rather than re-ran).

**Command (subject).**
```
python3 $SP/wt/prep-d/tools/loop_twin_matrix.py --clang <llvm19>/clang \
  --opt build/ir-pass/cq-opt --plugin build/ir-pass/libCQPass.so \
  --include $SP/progress/review_r1_L5/include \
  --runtime build/runtime/libcq_runtime.a --templates build/runtime/libcq_templates.a \
  --phi-surface void --jobs 6 --out …/matrix_void_subject.txt
```
Log `…/matrix_void_subject.log`, table `…/matrix_void_subject.txt`.

**Tally, SUBJECT (274 cells):** ACCEPT-IDENTICAL 126 · UNROLLED-ONLY 59 · DECLINE-BOTH 39 ·
DECLINE-BOTH-DIFFERENT 21 · **TRACE-DIVERGENCE 14** · quarantined divergences 15
(6× 1m5p A, 9× a3z7 B).
**Tally, ORACLE (prep-d's run, same mode, same cells):** no bare `TRACE-DIVERGENCE` row at all;
8× a3z7 B + 5× 1m5p A.

**The 14, with their oracle verdict (measured cell by cell):**
`m_add_der_add`, `m_add_range_add`, `m_none_der_add`, `m_none_range_add`, `m_rz_der_add`,
`m_rz_range_add`, `m_xor_der_add`, `m_xor_der_none`, `m_xor_der_rz`, `m_xor_gt_none`,
`m_xor_gt_rz`, `m_xor_range_add`, `m_xor_range_none`, `m_xor_range_rz` — every one of them
`DECLINE-BOTH-DIFFERENT  cq controlled lowering: control flow under quantum control …` on the
oracle. So **14 loud declines became silent rolled≠unrolled divergences.**

**Class.** All 14 first-differ on the M-C in-place-vs-out-of-place decision
(`cqrt_addc_i32(h0,3)` vs `cq_template_add_i32_hl(h0,3)->h9`; `cqrt_xorc_i32(h0,9)` vs
`cq_template_xor_i32_hl(h0,9)->h1`), i.e. the already-FILED bd `test_C_libtooling-a3z7`
class B (and its 1m5p sibling). So the DEFECT is pre-existing; the POPULATION is not. This is
CLAUDE.md's own drbq-Inc-3 wording applied one increment later: *"'Pre-existing' is true of
the defect and FALSE of its population … this increment ADDS CUSTOMERS to a known-defective
path."*

**Disposition owed (not mine to decide).** Per the quarantine's own rules a divergence may
never be recorded as an expected VERDICT; each of the 14 must either be fixed or entered in
`tools/loop_twin_matrix.quarantine.txt` with its class, direction and SHA-256 signature and
an owning bd issue. Note also that F-L5-1's class is NOT among these — the matrix has no
per-bit / induction-variable-mask REGION axis, so its 274 cells cannot see it.

---

## F-L5-3 — DOC-OR-FIXTURE-TRUTH: the ONE in-loop ACCEPT fixture pins a shape `clang -O1` cannot produce, and calls it Grover-with-diffusion; the C spelling of that program DECLINES, and nothing pins the decline

**Claim.** `ir-pass/test/control_phase_kickback_inloop.ll` is the increment's only P6 accept
fixture. Its module puts `%c = icmp eq i32 %q0, 5` in the LOOP HEADER on a `%q0` defined in
`entry`, with a body that gates `q` nowhere. Its header says *"This is Grover written as
`for (i = 0; i < K; i++) { oracle; diffusion; }`"* — there is no diffusion in it and no gate
on the register at all. `clang -O1` LICM-hoists that compare into the PREHEADER, which trips
`condWireDisposition`'s P4 precondition `Cond->getParent() != R.Pred`
(`ir-pass/src/ArmClassify.cpp:1725`) and returns `DeclineNow` before any rotation clause runs.

**Reproducer.** `…/probes/f_invariant_cond.c`
```c
int q = cq_theta(q, 0.5);
for (int i = 0; i < 2; ++i) { if (q == 5) { cq_phi(CQ_PI); } }
return cq_measure(q);
```
SUBJECT: `exit=1`, `error: … cq controlled lowering: condition predates a non-diagonal gate
under quantum control`. Its stage-1 IR (`…/out_subj/f_invariant_cond.s1.ll`) shows the compare
in block `%0`, the preheader — NOT in the header, where the fixture puts it.
Hand-unrolled twin `…/probes/f_invariant_cond_unrolled.c`: SUBJECT `exit=0`, 8-line trace.
ORACLE, register spelling `…/probes/oracle/f_invariant_cond_old.c`: `exit=0` — it ACCEPTS,
because `q = cq_phi(q,θ)` in the arm made the register loop-VARIANT.

So this is bd `test_C_libtooling-drbq.12`'s over-decline arriving at the PHASE stem, where it
did not exist before: under the register surface a phase arm always gated `q`; under kickback
a pure-phase loop body never does, so `if (q == k) cq_phi(θ)` alone in a loop is ALWAYS
LICM-hoisted and ALWAYS declines. Workaround measured, one token, exactly as for the Ry stem:
an opaque threshold (`…/probes/w_invariant_opaque.c`, `volatile int off`) ACCEPTS,
`exit=0`, 12-line trace.

**Why it is a fixture-truth finding and not just an over-decline.** The accept fixture's IR is
unreachable from C, its header describes a program it does not contain, and the reachable
class has NO decline fixture — while the Ry stem's identical class does
(`ir-pass/test/control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll`). A reader of the
suite would conclude P6 covers `for (…) { if (q==k) cq_phi(θ); }`; it does not.

**Proposed fix.** Rewrite `control_phase_kickback_inloop.ll`'s module to the shape `clang -O1`
actually produces for a rolled Grover (a body that gates `q`, i.e. probe
`…/probes/a_kick_rolled.c`), correct its header, and add
`control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll` mirroring
`condition predates a non-diagonal gate` character-for-character, plus an accept for the
opaque-threshold form.

---

## F-L5-4 — OVER-DECLINE of a §6.2 target shape: P2 (the angle select) INSIDE a rolled loop declines

**Claim.** PRD §6.2 row **P6** is *"in-loop rolled (8h7d.5), **P1–P3** inside a classically-
bounded loop"*. P2 in a loop declines.

**Reproducers.** `…/probes/u_ifelse_flat.c` — FLAT `if (q==5) cq_phi(.9); else cq_phi(.3);`
SUBJECT `exit=0`, trace `mint · x · rz_i1(.3) · x · rz_i1(.9) · unc · free` (the exact P2 form).
`…/probes/u_ifelse_loop_only.c` — the SAME region inside `for (i<2) { …; q = cq_theta(q,-.5); }`
SUBJECT `exit=1`, `error: … cq controlled lowering: condition predates a non-diagonal gate
under quantum control`. Its hand-unrolled twin (`…/probes/i_tailphi_unrolled.c`) declines with
the same string, so this is DECLINE-BOTH, not a rolled/unrolled asymmetry — but it is still a
declared accept shape that does not compile. No oracle comparison exists (the oracle declines
every void-surface program).

**Note on ownership.** The string is the kjd1 gate-2c / P4 window fence, not the angle-select
S7 loop prong, so the fix is a positional question in the Rule-13 core and belongs in its own
increment; I report it, I do not propose the widening. **Pinning fixture:** a decline fixture
naming the shape (there is none today — the increment's two `control_angle_select_phase_*`
declines are `two_consumers` and `empty_arm_phi`), so that when P6 is completed the red-green
exists.

---

## F-L5-5 — DOC-OR-FIXTURE-TRUTH: `branch phase on a bare i1 condition` is emitted for conditions that are not bare i1, and it REPLACES a truthful oracle message

**Claim.** `classifyPhaseKickback` step 5 (`ArmClassify.cpp:3631-3634`) emits
`cq controlled lowering: branch phase on a bare i1 condition under quantum control` for ANY
non-`CmpInst` condition. Its own comment says so deliberately ("A compound `select i1`
condition … is not a `CmpInst` either, so it takes the same partitioned message"). The message
is then FALSE for the two commonest ways to reach it.

**Reproducers, all measured on both binaries.**
| program | SUBJECT | ORACLE (register spelling) |
|---|---|---|
| `…/probes/s_barei1_flat.c` (`_Bool b = cq_theta(b,…); if (b) cq_phi(θ)`) — genuinely bare i1 | `branch phase on a bare i1 condition` | — |
| `…/probes/t_classguard_flat.c` (`if (c) { if (q==5) cq_phi(θ); }`, `c` a `volatile int`) | `branch phase on a bare i1 condition` | `control flow under quantum control` |
| `…/probes/q_backedge_only.c` (`for(i<3){ if (i) { if (q==5) cq_phi(θ); } … }` — the back-edge-only region) | `branch phase on a bare i1 condition` | `control flow under quantum control` |

The last two arrive as `%10 = select i1 %8, i1 %9, i1 false` (verified in
`…/out_subj/q_backedge_only.s1.ll`) — a COMPOUND condition whose left operand is CLASSICAL.
Nothing about them is a bare `i1` from `cq_theta`, and one of the two mixes a classical guard
with a tainted compare, which is not even P3.

**Why it matters here.** (i) A user is sent to look for a `_Bool` that does not exist; Rule 1's
whole point is that a decline is source-located and actionable. (ii) The string now labels
THREE unrelated shapes (Inc-1b's bare i1, P3's `select i1`, and the classical-guard-AND), so
when Inc 1b lands and clears the first, the string will still fire on the other two and no
fixture will detect the confusion. (iii) It is a diagnostic REGRESSION relative to the oracle,
which said `control flow` — true of all three.

**Proposed fix.** `ArmClassify.cpp:3631` — split: keep
`branch phase on a bare i1 condition` for a tainted `i1` that is not an instruction /
is a `cq_theta` result, and use the pre-existing `control flow` for a `select`/`and`/`or`/`xor`
condition tree. **Pinning fixtures:** the existing
`control_phase_kickback_reject_bare_i1.ll` plus a new
`control_phase_kickback_reject_compound_cond.ll` mirroring whichever string the compound case
takes.

---

## F-L5-6 — DOC-OR-FIXTURE-TRUTH (latent WIDENING): the B3 phase fence in the loop path went vacuous, got NO vacuity note, and the note its two siblings DID get states a reason that does not apply to it

**Claim.** The increment added a "⚠ VACUOUS SINCE 3qlq Inc 1" note at 12 `cq_phi_` prefix
recognizers. Two of the three PHASE-CARRIER predicates got it —
`ControlDetect.cpp:401` (in `retLineageCarriesPhase`) and `AbortParkEmit.cpp:148`
(`lineageCarriesPhase`) — and the third did NOT: `LoopLowering.cpp:1069` inside
`breakLineageCarriesPhase`, the §2.6 **B3** fence that declines a 7.4 `break` whose ESCAPING
ANSWER carries a relative phase (`git diff dfb8e83..fa96336 -- ir-pass/src/LoopLowering.cpp`
has exactly one hunk, at `isHoistedRegionArmGate`).

**Why the note that WAS applied is the wrong reason, twice over.** Its text is *"KEEPING IT IS
THE POINT: a `void(double)` call has no arg-0 WIRE and no arg-1 ANGLE, so every clause below
… would be reading the wrong operand"*. That is correct for the WIRE-walking predicates
(`WireWalk`, `isHoistedRegionArmGate`, the `isPhiCall` family) and a non-sequitur for a
carrier predicate, which reads no operand at all — it only asks "is a `cq_phi` call in this
lineage?". For those three the honest statement is the opposite of reassuring: **the property
they protect is no longer representable in the SSA lineage.** A register whose branches carry
a KICKBACK phase has NO `cq_phi` anywhere in its lineage, so all three now answer "no phase"
for a value that genuinely carries one — a WIDENING, not a narrowing, and the one direction a
vacuity audit exists to catch.

**Fixture status.** `ir-pass/test/lowering_reject_break_phase_answer.ll` is the only fixture
pinning `early break preserves a phase answer`; at the SUBJECT it is RED
(`cd build && lit ir-pass/test --filter lowering_reject_break_phase_answer` → 1 failed; it now
declines `cq taint escape: tainted value consumed by an unknown callee`, i.e. it is in the 491
retired-family migration set). So B3 has NO live coverage at HEAD, and the migration must not
merely re-point its string: **the fence cannot be expressed in the new surface at all.**

**Reachability: UNCONFIRMED at this HEAD, and I say so first.** My closest reproducer
`…/probes/p1_break_kickphase.c` (`int q = cq_theta(…); if (q==5) cq_phi(.3); for(…){ q=q^5;
if((q&1)==0) break; } return cq_measure(q);`) declines on an EARLIER fence —
`cq loop lowering: early break body is not a provable rolled single-rail loop` — and the
matched oracle spelling `…/probes/oracle/p2_break_condphase_old.c` (`if (q==5) q =
cq_phi(q,.3);` before the same loop) declines with the IDENTICAL string on the oracle. So
today the widening is latent, held shut by an unrelated shape fence. The oracle's
straight-line spelling `…/probes/oracle/p1_break_regphase_old.c` does reach B3
(`early break preserves a phase answer`), which is what shows the fence used to be live.

**Proposed fix.** `LoopLowering.cpp:1053-1070` — add the vacuity note, and state the correct
reason (the carrier property is now unrepresentable, so the fence is a WIDENING, filed).
Because the property is real and the mechanism is gone, the durable fix is to record
kickback-phased registers explicitly (the natural home is a `TaintSet` set written by
`emitPhaseKickbackRegion`, the way drbq Inc 1 records `ControlledRotations` /
`railCarriesControlledRotation`), and to have all three carrier predicates consult it.
**Pinning fixture:** a `lowering_reject_break_phase_answer.ll` REWRITTEN to the kickback
spelling — which, at HEAD, cannot be written, and that impossibility is itself the finding to
report to the owner.

---

## F-L5-7 — DOC-OR-FIXTURE-TRUTH (harness): `e2e-loop-twin-matrix`, the ONLY instrument in the tree that can see the F-L5-1 class, does not run against this increment in EITHER mode

Two independent breaks, both measured on the subject:

**(a) the committed `register` invocation HARNESS-ERRORs after the surface change.**
`tests/e2e/CMakeLists.txt:4263-4268` passes NO `--phi-surface` (default `register`) with
`--include ${CMAKE_SOURCE_DIR}/include`, and prep-d's branch leaves that invocation
byte-identical. Every REGION cell generates `a = cq_phi(a, T)`, which the shipped header now
rejects: `error: too many arguments to function call, expected single argument 'angle', have 2`
(`…/probes/x_regsurface_cell.c`). Running the committed invocation at `fa96336`:
**`FAILED (349)` — 175 `HARNESS-ERROR`, 172 `verdict changed … got: HARNESS-ERROR`, 2
`QUARANTINE STALE`** (`…/matrix_register_subject.log`). It fails LOUD, which is the safe
direction, but the gate measures nothing until the ctest entry gains `--phi-surface void`.

**(b) the `void` mode REFUSES to run against the shipped header.** The mode's guard is a
LITERAL substring test `if "void cq_phi(double" not in text`
(`$SP/wt/prep-d/tools/loop_twin_matrix.py:1313`), and `include/CQ.h:62` spells the declaration
with column alignment: `void                cq_phi     (double angle);`. `grep -c "void
cq_phi(double" include/CQ.h` → **0**, and the same is true of every worktree in the epic
(`prep-a`, `prep-b`, `prep-c`, `prep-d`, `inc1b`) — prep-d measured against its own stand-in
header `$SP/progress/prep_d_include/CQ.h`, which spells it unaligned. First invocation of the
mode against the real tree printed *"does not declare `void cq_phi(double ...)` … That header
is a `register`-surface one"*, which is false about the header it was given. I worked around
it with a copy whose ONLY change is that one line's spacing
(`$SP/progress/review_r1_L5/include/CQ.h`, `diff` = 1 line) — that copy is what F-L5-2's
numbers were measured with.

**Proposed fix.** (a) `tests/e2e/CMakeLists.txt:4263-4268` — add `--phi-surface void`
(coordinated with prep-d, whose docstring already says a void run must use `--out`).
(b) `$SP/wt/prep-d/tools/loop_twin_matrix.py:1313` — make the guard whitespace-insensitive
(a regex over `void\s+cq_phi\s*\(\s*double`) or, better, compile a one-line probe TU. **Pinning
fixture:** none needed for (b) beyond the guard's own refusal path, but the guard must be
exercised against the SHIPPED header, not a stand-in — that is the whole class of defect it
was written to prevent.

---

## What I probed that came out CLEAN (measured, so the negative is worth as much as the findings)

All byte-identical rolled vs hand-unrolled on the SUBJECT, STRICT stage 2b `0` on both sides:

| probe | body | result |
|---|---|---|
| `a_kick_{rolled,unrolled}.c` | kickback + `q = cq_theta` per trip, K=2 | **identical**, 13 lines |
| `b_k1_{rolled,unrolled}.c` | the same at **K=1** | **identical**, 8 lines |
| `c_mixed_ry_{rolled,unrolled}.c` | **MIXED**: kickback on `q` **+** a controlled-Ry arm on a disjoint `r` (drbq Inc 3) in the same body | **identical**, 24 lines; `rz_i1` on the flag and `ry_i32_controlled` on `r` both per trip |
| `d_leading_{rolled,unrolled}.c` | the 8h7d.5 **F-4 leading-gate** cell: `cq_theta` BEFORE the region | **identical**, 15 lines |
| `e_two_regs_{rolled,unrolled}.c` | **two kickback regions on two registers** in one body | **identical**, 27 lines |
| `h_n_gates_{rolled,unrolled}.c` | **N=3 `cq_phi` per arm** inside the loop | **identical**, 18 lines; 3 `rz_i1` on ONE flag, one mint/strip/free |
| `k_derived_{rolled,unrolled}.c` | derived condition `(q & 6) == 4`, `q` gated in the body | **identical**, 20 lines, `and` rail DISCHARGED |
| `l_perbit_ry_{rolled,unrolled}.c` | per-bit mask **plus** a body `cq_theta` | **identical**, 23 lines, `and` rail DISCHARGED |
| `v_seq_inloop_{rolled,unrolled}.c` | **two SEQUENTIAL regions per trip** (hcrg ordering inside the 8h7d.5 loop) | **identical**, 23 lines |

Also measured and **not** findings (identical disposition on BOTH binaries, so pre-existing and
unchanged):
- `g_exit_block.c` — a kickback region in the loop EXIT block: SUBJECT and ORACLE both
  `exit=1`, `cq taint escape: tainted value muxed by a classical-condition phi`.
- `r_record_{rolled,unrolled}.c` — the 8h7d.5 RECORD axis (`int mark = q;` before the loop,
  `cq_measure(mark)` after): rolled declines `cq loop lowering: rail record read past an
  in-place gate on the same rail` and the unrolled twin accepts, on the SUBJECT **and** on the
  ORACLE with the register spelling, character-for-character.
- The "Rz is diagonal and exempt" clauses in the LOOP path (`collectRailGates` /
  `railGateBetween` / `staleRailRecordRead`, `LoopLowering.cpp:737-741`, `:560`) go vacuous
  in the NARROWING direction: under the void surface a `cq_phi` no longer creates an SSA hop
  on the rail, so there is no chain edge for the fence to be exempt about. Probes C/D/E/R
  corroborate — no mixed body changed disposition. **The three carrier predicates are the
  exception, and they go the other way — F-L5-6.**

---

## VERDICT

**NOT CLEAR — 1 CONFIRMED-MISCOMPILE (F-L5-1: D4's per-bit rolled loop leaks one entangled
derived-condition rail per activation, rolled ≠ unrolled, and the pre-3qlq oracle emitted the
discharging stream for the same program — already a red `cmp` gate in prep-b's own committed
slices), 1 CONFIRMED new population on a filed defect (F-L5-2: 14 non-quarantined twin-matrix
divergences on the subject vs 0 on the oracle), 1 OVER-DECLINE of a declared §6.2 accept shape
(F-L5-4: P2 in a loop), and 4 DOC-OR-FIXTURE-TRUTH findings, one of which (F-L5-6) is a latent
WIDENING the increment's own vacuity audit missed.** The in-loop mechanism itself is sound for
every shape whose loop body gates the condition register — nine rolled/unrolled pairs are
byte-identical, including the mixed kickback+controlled-Ry body, K=1, N-gates-per-arm and two
sequential regions per trip. What is not sound is the shape where the body gates NOTHING,
which is exactly the shape the register surface could not produce and the new surface makes
the normal case.


---

## Appendix — what I ran (every number above is MEASURED; nothing is estimated)

```
# per-program pipeline, both binaries (the runner replicates run_slice.sh stages 1-4 + 2b STRICT)
$SP/progress/review_r1_L5/run.sh <probe>.c subj      # /Users/sorenwilkening/Desktop/CQ_lang build
$SP/progress/review_r1_L5/run.sh <probe>.c orac      # $SP/wt/pre-3qlq build
  -> 25 probe programs (16 subject-surface, 9 oracle-surface), each printing EXIT=, 2B=, TRACE

# the twin matrix, VOID mode, on the SUBJECT (F-L5-2)     ~4 min, 274 cells
python3 $SP/wt/prep-d/tools/loop_twin_matrix.py --phi-surface void \
  --opt build/ir-pass/cq-opt --plugin build/ir-pass/libCQPass.so \
  --include $SP/progress/review_r1_L5/include --jobs 6 --out …/matrix_void_subject.txt
  -> 126 ACCEPT-IDENTICAL / 59 UNROLLED-ONLY / 39 DECLINE-BOTH / 21 DECLINE-BOTH-DIFFERENT /
     14 TRACE-DIVERGENCE / 15 quarantined            log …/matrix_void_subject.log

# the twin matrix, the COMMITTED (register) invocation, on the SUBJECT (F-L5-7a)
python3 $SP/wt/prep-d/tools/loop_twin_matrix.py --include ./include --jobs 6 …
  -> FAILED (349): 175 HARNESS-ERROR, 172 "verdict changed … got: HARNESS-ERROR",
     2 QUARANTINE STALE                              log …/matrix_register_subject.log

# one lit fixture (F-L5-6)
cd build && lit -v ir-pass/test --filter 'lowering_reject_break_phase_answer'   -> 1 FAILED

# the ORACLE's void run was NOT re-run; I read prep-d's committed measurement
$SP/progress/prep_d_out2/loop_void.tbl                -> 13 divergences, ALL quarantined, 0 new
```

I did **not** run `ir-pass-lit` or the full `ctest` (Rule 19: read-only lens; the orchestrator
owns the gate). Nothing under `ir-pass/`, `tests/`, `include/` or `ir-pass/src/` was modified;
the one header copy I made lives under `$SP/progress/review_r1_L5/include/` and differs from
`include/CQ.h` by exactly one line's whitespace.
