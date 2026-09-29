; control_inplace_ry_stateprep_runtime_seed_measured.ll — ACCEPT (bd
; test_C_libtooling-z0re, owner ruling 2026-09-28 option (a)): a controlled state
; prep seeded by a MEASUREMENT RESULT.
;
;     int s = cq_measure(q0); int r = s; if (q > 3) r = cq_theta(s, .2);   // probe e07
;
; `cq_measure` is the taint SINK (Rule 3): its result is a CLASSICAL value, the
; measured outcome, and `isRuntimeStatePrepSeed` admits it like any other runtime
; value. The seed is NOT "derived from quantum state" in the sense F1 fences — the
; state collapsed at the measurement, and what flows on is the classical record of
; it (mid-circuit measurement + classical feed-forward). The UNCONDITIONAL spelling
; already lowers this way on the ORACLE (main 9a230646, probe e07u):
; `%m = cqrt_measure_i32(%h); %h1 = cqrt_alloc_i32(%m); cqrt_ry_i32(%h1, 0.2)` —
; this file is the same seed under a flag, and the stream below is that stream
; with the Ry controlled.
;
; ⚠ WHAT IT DOES NOT CLAIM: nothing about reading `q0` AFTER measuring it (bd yiid,
; an unruled boundary) — `q0` is not read again here.
;
; On the ORACLE this module DECLINES at F1's literal-only clause.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u1, double 4.000000e-01)
  %s = call i32 @cq_measure_si32(i32 %q0)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %s, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %s, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %sum = add i32 %mq, %mr
  ret i32 %sum
}

; CHECK:      %[[Q0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q0]], double 4.000000e-01)
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[Q0]])
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[S]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])

; NEG-NOT: cq_theta_
; NEG-NOT: = phi
