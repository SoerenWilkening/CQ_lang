; control_inplace_ry_stateprep_runtime_seed_inloop.ll — ACCEPT, ROLLED (bd
; test_C_libtooling-z0re): a RUNTIME seed that the loop RE-COMPUTES every trip.
;
;     for (int k = 0; k < 3; k++) { int q = m + k; cq_theta(&q, .5); int r = s + k;
;                                   if (q > k) { r = s + k; cq_theta(&r, .2); } acc += cq_measure(r); }
;
; The in-loop state prep is the bd wx8g ITERATION-LOCAL rail (R7-loop clause (c)):
; the rail is minted by the hoisted theta INSIDE the body, so each activation
; allocates a fresh rail from THAT activation's seed value `%seed` — exactly what
; the hand-unrolled twin's k-th copy does with its own `s + k`. F1 is the SAME
; clause for the flat and the in-loop form (it runs before the loop clause), so the
; runtime seed reaches both with one predicate. MEASURED: the C pair `lvC`/`lvT`
; (rolled vs hand-unrolled, `z0re_probes/twins.sh`) is ACC-SAME, 24 trace lines at
; arguments `5 7` and `2 9`, STRICT stage 2b clean; e2e gate
; `e2e-z0re-runtime-seed-loop-twin-identical`. The lowered body below is
; K-independent (one alloc per trip, no unrolling).
;
; On the ORACLE this module DECLINES at F1's literal-only clause.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %m, i32 %s) {
entry:
  br label %loop
exit:
  ret i32 %acc.next
loop:
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %latch ]
  %k = phi i32 [ 0, %entry ], [ %k.next, %latch ]
  %mk = add nsw i32 %k, %m
  %q = call i32 @cq_theta_si32(i32 %mk, double 5.000000e-01)
  %seed = add nsw i32 %k, %s
  %c = icmp sgt i32 %q, %k
  br i1 %c, label %arm, label %latch
arm:
  %rt = call i32 @cq_theta_si32(i32 %seed, double 2.000000e-01)
  br label %latch
latch:
  %rm = phi i32 [ %rt, %arm ], [ %seed, %loop ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %acc.next = add nsw i32 %mr, %acc
  %k.next = add nuw nsw i32 %k, 1
  %done = icmp eq i32 %k.next, 3
  br i1 %done, label %exit, label %loop
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %mk)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %seed = add nsw i32 %k, %s
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 %k)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %seed)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 %k)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

; NEG-NOT: cq_theta_
; NEG-NOT: cqrt_copy

; Rolled: exactly the two per-trip allocs, no unrolled copies.
; ACNT-COUNT-2: call i32 @cqrt_alloc_i32(
; ACNT-NOT:     call i32 @cqrt_alloc_i32(
