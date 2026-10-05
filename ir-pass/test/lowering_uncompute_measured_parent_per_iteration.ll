; lowering_uncompute_measured_parent_per_iteration.ll — ACCEPT (bd
; test_C_libtooling-01po.13). The `clang -O1` IR (debug info stripped) of
;     int slice(int x, int n){ int acc = 0;
;       for (int i = 0; i < n; i++) {
;         int q = x + i; cq_theta(&q, .25);   // a FRESH register every iteration
;         int t = q ^ 9; cq_theta(&t, .5);    // dead rotated copy, iteration-local
;         acc += cq_measure(q); }
;       return acc; }
; Declined "cq uncompute: dead chain would free a measured register" on main
; 7b4e6359.
;
; WHAT DECLINED. The bd ptue retry borrows the measured `q` and reverses `t`
; in-body (an iteration-local group). `measuredParentsReadBeforeCollapse` asked
; `isPotentiallyReachable(measure(q), xor(q, 9))` with no loop scoping: iteration
; i's measurement reaches iteration i+1's xor round the back edge, so it read as
; bd yiid (a post-collapse read). But the SSA value the xor reads is the
; `cqrt_alloc` of iteration i+1 — a register minted AFTER that measurement.
;
; THE FIX. A read counts as post-collapse only if some path from the measurement
; reaches it WITHOUT re-executing the measured value's own definition, and that
; escape hatch is taken only for a definition that MINTS a physically fresh
; register each time it runs (a `cqrt_alloc` mint or a template producer).
; `everyPathReExecutes(measure, read, def)` is the per-activation barrier walk
; (WireWalk, one spelling). A register carried across iterations (minted
; outside the loop, or a loop-carried φ) keeps today's answer: the decline twin
; is lowering_reject_uncompute_measured_parent_carried_across_iterations.ll.
;
; HAND TRACE, one iteration (each trip mints q and t afresh; the reversal is
; in-body, once per trip). Ry(.25)|x+i> = Σ_v a_v|v> on q:
;   xor_hl(q,9) -> t; ry(t,.5)       Σ a_v |v> R|v^9>
;   ry(t,-.5); xor_hl_unc(t,q,9)     q unmoved since the xor (its only other
;                                    users this trip are its prep Ry, before, and
;                                    the measure, after) -> t = 0
;   cqrt_free(t)                     |0> in a product state: the reset learns nothing
;   measure(q)                       P(v) = |a_v|^2, the program's distribution
; q is never adjointed or freed (it is measured; born |x+i>).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %0, i32 %1) {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %6, label %4

4:
  %5 = phi i32 [ 0, %2 ], [ %14, %6 ]
  ret i32 %5

6:
  %7 = phi i32 [ %14, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %15, %6 ], [ 0, %2 ]
  %9 = add nsw i32 %8, %0
  %10 = tail call i32 @cq_theta_si32(i32 %9, double 2.500000e-01)
  %11 = xor i32 %10, 9
  %12 = tail call i32 @cq_theta_si32(i32 %11, double 5.000000e-01)
  %13 = tail call i32 @cq_measure_si32(i32 %10)
  %14 = add nsw i32 %13, %7
  %15 = add nuw nsw i32 %8, 1
  %16 = icmp eq i32 %15, %1
  br i1 %16, label %4, label %6
}

; CHECK-LABEL: define i32 @slice(i32 %0, i32 %1)
; CHECK:       {{^}}6:
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:   @cqrt_free(i32 %[[H]])
; CHECK:       br i1 %{{[0-9]+}}, label %4, label %6
