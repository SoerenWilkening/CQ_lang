; control_swap_accept_select_rail_alias_cond.ll — ACCEPT (bd big5, 2026-07-31).
; THE canonical fixture for the aliased-rail condition compare, and the one that
; pins the DIRECTION this was resolved in. It was a DECLINE fixture for exactly
; one day (bd 7q3s / commit dd2c103, 2026-07-30→31); the fence it pinned rested on
; a false premise and was reverted. DO NOT RE-ADD THAT FENCE.
;
; THE SHAPE. The two condition operands are SSA-DISTINCT — `%q` and
; `%r = cq_phi(%q, .25)` — so InstCombine cannot fold the compare, unlike the
; `x == x` idiom. But `cq_phi` (Rz) is an IN-PLACE gate whose result RAUWs to its
; argument's i32 handle, so AFTER RotationLowering both operands ARE ONE RAIL.
; That mechanism is the durable finding of bd 7q3s and it still stands:
;   *** A PRE-MUTATION SSA TEST CANNOT SEE A POST-LOWERING ALIAS. ***
; It is reachable from FOUR LINES of ordinary C at the plain -O1 ship floor —
;     q = cq_theta(u,.5);  r = cq_phi(q,.25);  s = (q < r) ? 11 : 22;
; — and the `if (q < r) s = 11;` spelling lowers to this same select via -O1
; if-conversion, so this fixture covers that route too.
;
; WHY IT ACCEPTS — THE CASE A / CASE B PARTITION (owner ruling 2026-07-31; bd
; memory [aliased-rail-gate-is-realizable-2026-07-31]).
;
;   CASE A — aliased INPUTS of an OUT-OF-PLACE gate whose OUTPUT is a FRESH |0>
;   rail. REALIZABLE, and the proof is a THEOREM, not a list of lucky cases:
;   the generated ABI's out-of-place shape is `out(fresh |0>) ^= f(in0, in1)`
;   (mechanically true of all 2479 generated bodies — every non-void template
;   calls `cqrt_alloc_handle()`, every void one is an out-first `_unc`). Aliasing
;   the inputs makes that `out ^= g(a)` with `g(a) := f(a,a)`, and
;       (a, 0) ─► (a, g(a))
;   is the standard reversible embedding of a classical function, self-inverse and
;   unitary for ANY g. So realizability does not depend on g being degenerate —
;   degeneracy only changes COST. Cheap cases: `icmp_eq/sle/sge(a,a)` is constant
;   TRUE (one X on the flag rail), `icmp_slt/sgt/ne(a,a)` is constant FALSE
;   (nothing at all), `toffoli(c,c,G)` == `cnot(c,G)`, `fadd(a,a)` == 2a. Genuinely
;   unary cases: `fmul(a,a)` = squaring; `fcmp uno(a,a)` IS `isnan(a)`; every
;   ORDERED `fcmp` on aliased operands is `!isnan(a)` or constant FALSE.
;   *** DO NOT WRITE `fsub(a,a) == 0` OR `fdiv(a,a) == 1` — THEY ARE FALSE. ***
;   Under IEEE-754 both are NaN on inf/NaN inputs (and `fdiv` also on ±0), which is
;   exactly what tests/e2e/slice_libm_real_acos.c:98 `(x-x)/(x-x)` RELIES on to
;   produce NaN. A backend implementing them as constants would turn acos(2.0)
;   from NaN into 1.0. They are still Case A — they are unary functions of `a` —
;   but they are not constants. (An earlier draft of this header got this wrong;
;   an adversarial reviewer caught it. Rule 11.)
;   CASE A IS A PHASE-9 BACKEND OBLIGATION, never a compiler defect.
;
;   CASE B — an input aliasing a rail the gate WRITES. NOT realizable
;   (`cqrt_cnot(c,c)` erases; `cqrt_cswap(c,c,b)` sends both |1,0> and |0,1> to
;   |0,1>). A compare can never be Case B: its forward mint is an unconditional
;   `CreateCall(Callee, {Lhs, Rhs}, "h_cmp")` (CompareLowering.cpp:262), so the
;   flag rail is a NEW value whatever the operands are. A 2026-07-31 adversarial
;   sweep of every rail-writing mint in the pass found NO Case B emitted anywhere.
;
; THE CONSISTENCY ARGUMENT, STATED ACCURATELY. 118 of 226 committed e2e goldens
; already ship an aliased-operand forward template call — slice_libm_real_acos.c
; :102 `z = x*x` → `cq_template_fmul_f64(h0, h0)` (golden line 48). Those goldens
; were GREEN WITH THE FENCE IN: `collectCondTree` walks a select CONDITION tree and
; never inspects arithmetic, so the fence could not and did not condemn any of
; them. The defect was an INCONSISTENCY OF PRINCIPLE — the DATA path has always
; emitted aliased Case-A mints unfenced, so the compiler already depends on Case A
; being realizable, and fencing the CONDITION path contradicted a premise the tree
; relies on. *** DO NOT restate this as "a fence would have condemned 109 goldens"
; and DO NOT generalize it into "if a fence would condemn a golden the fence is
; wrong" *** — this project routinely accepts a shape as data and declines it under
; control (kjd1 accepts fp at the select and declines it at every non-select
; consumer), so "consistency with the data path" is not a rule here. It is evidence
; about THIS gate shape only.
;
; WHY THE ACCEPT IS SOUND AND NOT MERELY REALIZABLE: the alias is created by a
; DIAGONAL gate (Rz), so both SSA names denote the same BASIS LABEL and collapsing
; `icmp(a,a)` to a constant is the CORRECT answer. The NON-diagonal twin —
; `r = cq_theta(q,.25)`, an in-place Ry that also RAUWs to one rail but CHANGES the
; basis, so the source means "pre-Ry record vs post-Ry record" — must NOT lower,
; and does not: it is owned by ArmClassify's gate 2c (`findNonDiagonalWireGate`)
; and pinned by control_swap_reject_select_theta_alias_cond.ll. Read that fixture
; alongside this one; the pairing is the whole invariant.
;
; WHICH FENCE SITES THIS FIXTURE ACTUALLY COVERS (MEASURED by re-adding exactly one
; fence at a time into three isolated plugin builds — do not guess, and do not
; infer it from the diagnostic string):
;   fixture                                    | Arm only | PredMux only | Select only
;   control_predmux_accept_aliased_leaf        |  FAIL    |   FAIL       |   FAIL
;   control_swap_accept_diamond_aliased_cond   |  PASS    |   FAIL       |   FAIL
;   control_swap_accept_select_aliased_leaf    |  FAIL    |   PASS       |   FAIL
;   control_swap_accept_select_rail_alias_cond |  PASS    |   PASS       |   FAIL
;   spec_accept_select_aliased_leaf            |  FAIL    |   PASS       |   FAIL
; (FAIL = re-adding that ONE fence breaks the fixture, i.e. the fixture covers that
; site.) So THIS fixture covers only the SelectClassify site; the predmux fixture
; is the only one covering all three.
;
; The end-to-end witness (link + run + trace + the Rule-6 free-pairing gate) is
; tests/e2e/slice_select_rail_alias_cond.c.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCASEB < %t.cqd0.ll
;
; The aliased CASE A mint is the point — pin it verbatim so a re-added fence
; cannot pass:
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK: %h_cmp = call i32 @cq_template_icmp_slt_i32(i32 %h, i32 %h)
; The 4.4 controlled-XOR copy merge. ARM POLARITY IS PINNED (constants and all):
; the TRUE arm (11) copies on the flag, the FALSE arm (22) inside the cqrt_x
; bracket. An arm-swap is a silent miscompile and a `%{{.*}}` source operand would
; not catch it (§16.3).
; CHECK: %out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %selop = call i32 @cqrt_alloc_i32(i32 11)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: %selop1 = call i32 @cqrt_alloc_i32(i32 22)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; Flag strip then free — the strip WRITES %h_cmp and READS %h twice, so the
; aliasing is confined to the READ slots (Case A). %h_cmp is not among them:
; CHECK: call void @cq_template_icmp_slt_i32_unc(i32 %h_cmp, i32 %h, i32 %h)
; CHECK: call void @cqrt_free(i32 %h_cmp)
; CHECK: %m{{[0-9]*}} = call i32 @cqrt_measure_i32(i32 %out)
;
; CASE B MUST NEVER APPEAR — an input aliasing the rail the gate WRITES.
; THESE LIVE UNDER THEIR OWN CHECK-PREFIX ON PURPOSE: a trailing `CHECK-NOT` only
; scans from the LAST `CHECK` match to EOF, so as plain CHECK-NOTs these were DEAD
; over the whole function body — a body mutant emitting every spelling below
; PASSED. MEASURED 2026-07-31 by injection. A prefix carrying ONLY *-NOT
; directives scans the ENTIRE input, which is what makes them real.
; NOCASEB-NOT: @cq_template_icmp_slt_i32_unc(i32 %h, i32 %h
; NOCASEB-NOT: @cqrt_cnot(i32 %h_cmp, i32 %h_cmp)
; NOCASEB-NOT: @cqrt_cswap(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %out, i32 %out)
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp slt i32 %q, %q                                 ; SSA-distinct, one rail
  %s = select i1 %c, i32 11, i32 22
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
