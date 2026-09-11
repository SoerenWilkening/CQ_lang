; control_phase_kickback_cmp_measure_after.ll — ACCEPT (Track A.1, bd
; test_C_libtooling-r903 item (b)): the `br`-path discriminator for
; `control_phase_kickback_reject_cmp_measured_before.ll`. The SAME program with
; the two statements swapped:
;
;     int q = cq_theta(0, .5);
;     if (q > 3) cq_phi(.3);           // the flag reads a COHERENT q
;     return cq_measure(q);            // the measurement owns it afterwards
;
; VERBATIM `clang -O1` (probe `a3_kick_cmp_measure_after.c`), BYTE-UNCHANGED from
; `main` 0c7380c. A `cq_measure` user is never a terminator, so at the kickback's
; read point (`Pred->getTerminator()`) "same block" really would be "before" —
; which is why the decline twin needs no positional subtlety and this one is
; accepted on REACHABILITY: after linearization the measure follows the whole
; kickback stream and can never precede it.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RZCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %ph, label %join

ph:
  call void @cq_phi(double 3.000000e-01)
  br label %join

join:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: {{.*}} = call i32 @cqrt_measure_i32(i32 %[[H]])

; ORD: call i32 @cq_template_icmp_sgt_i32_hl(
; ORD: call void @cqrt_rz_i1(
; ORD: call void @cq_template_icmp_sgt_i32_hl_unc(
; ORD: call void @cqrt_free(
; ORD: call i32 @cqrt_measure_i32(

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz_i32
; NOROUTE-NOT: cqrt_rz{{.*}}_controlled
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: call void @cq_phi(
; RZCNT-COUNT-1: call void @cqrt_rz_i1(
; RZCNT-NOT:     call void @cqrt_rz_i1(
; MCNT-COUNT-1: call i32 @cqrt_measure_
; MCNT-NOT:     call i32 @cqrt_measure_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
