; control_inplace_ry_reject_tree_notform_reporter_t7.ll — DECLINE: the
; reporter's original `t7.c` (docs/CQ_FINDINGS.md F2, ~/Desktop/alg_test/dicke):
;
;     bool a = 0, b = 0, t = 1;
;     cq_theta(&a, 1.0); cq_theta(&b, 1.0);
;     b ^= a;                        /* CNOT a->b */
;     if (a & b) cq_theta(&t, 0.5);  /* CCRy */
;     b ^= a;
;
; Pinned at the coordinator's request as the dm7f.51-family decline, AND THE
; REASON IS NOT dm7f.51's — measured, bd dm7f.52. The target `t` is DISJOINT from
; every condition wire. `clang -O1` folds `a & (b ^ a)` to `a & !b` and cancels
; the two `b ^= a` outright, so the module below holds no CNOT at all: the
; condition is `and i1 %a, (xor i1 %b, true)`, and the `xor %b, true` NOT-form is
; refused by `collectCondTree` — the same grammar gap that makes the `cq_phi` twin
; `if (!a & b) cq_phi(.7)` decline (`control_phase_kickback_reject_tree_notform.ll`).
; The program is physically valid (`¬b` is realizable as a CNOT copy of the rail
; into a fresh ancilla, X-bracketed there — never a `cqrt_x` on the user's `b`,
; which the nest's `NegL`/`NegR` bracket would put on a rail leaf), so this is an
; OVER-DECLINE of the condition-tree GRAMMAR (`SelectClassify::collectCondTree`,
; shared by four consumers), filed as a follow-up of dm7f.52.
; RETIREMENT TRIGGER: when the grammar admits a NOT leaf, this file must flip to
; an accept whose stream is `toffoli` on (a, ¬b) — an `x` bracket on a COPY or
; ancilla, never a `cqrt_x` on the user's `b` — then `alloc_i1(1)` + cRy(.5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = xor i1 %2, true
  %4 = and i1 %1, %3
  br i1 %4, label %5, label %7

5:
  %6 = call i1 @cq_theta_i1(i1 true, double 5.000000e-01)
  br label %7

7:
  %8 = phi i1 [ %6, %5 ], [ true, %0 ]
  %9 = call i1 @cq_measure_i1(i1 %1)
  %10 = zext i1 %9 to i32
  %11 = call i1 @cq_measure_i1(i1 %2)
  %12 = zext i1 %11 to i32
  %13 = call i1 @cq_measure_i1(i1 %8)
  %14 = zext i1 %13 to i32
  %15 = add i32 %10, %12
  %16 = add i32 %15, %14
  ret i32 %16
}

; CHECK: cq controlled lowering: control flow under quantum control
