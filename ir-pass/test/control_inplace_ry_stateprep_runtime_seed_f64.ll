; control_inplace_ry_stateprep_runtime_seed_f64.ll — ACCEPT (bd
; test_C_libtooling-z0re, owner ruling 2026-09-28 option (a)): a RUNTIME f64 seed.
;
;     double s = atof(v[2]); double r = s; if (q > 3) r = cq_theta(s, .2);   // probe e11
;
; bd z0re's named population includes the f64 width (`zxdC`, Rule-13 r1B d88e), and
; the ruling's purpose — the hand-inlined twin and the spec-classical side door
; ACCEPT with the same circuit — reaches it, so the widening is not integer-only.
; What made the LITERAL fp seed special does not apply: the `Constant` spelling's
; `-0.0` argument (uniquing IS bit identity) is replaced by SSA identity (the fresh
; rail is seeded with the very bits the straight-through edge carries, whatever
; they are at run time, `-0.0` and NaN included), and the precautionary decline of
; notes §9 item 24 is about a LITERAL seed pinned by an `fcmp oeq` edge, which F2's
; fp ANCHOR still refuses unchanged. The runtime fp seed's own `fcmp` question is
; the relational half (`…_runtime_seed_fcmp_cond_operand.ll`).
;
; On the ORACLE this module DECLINES at F1's literal-only clause.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_measure_f64(double)

define i32 @example(i32 %u0, double %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double %s, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ %s, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %ir = fptosi double %mr to i32
  %mq = call i32 @cq_measure_si32(i32 %q)
  %sum = add i32 %mq, %ir
  ret i32 %sum
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %s)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[R]])

; NEG-NOT: cq_theta_
; NEG-NOT: = phi
; NEG-NOT: cqrt_copy
