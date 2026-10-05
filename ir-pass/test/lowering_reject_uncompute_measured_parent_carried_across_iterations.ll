; lowering_reject_uncompute_measured_parent_carried_across_iterations.ll —
; DECLINE (bd test_C_libtooling-01po.13; decline twin of
; lowering_uncompute_measured_parent_per_iteration.ll). The `clang -O1` IR of
;     int slice(int x, int n){ int acc = 0; int q = x; cq_theta(&q, .25);
;       for (int i = 0; i < n; i++) {
;         int t = q ^ i; cq_theta(&t, .5);    // reads the ONE q every trip
;         acc += cq_measure(q); }
;       return acc; }
;
; THE NEIGHBOUR THE LOOP SCOPING MUST NOT TAKE. `q` is minted ONCE, before the
; loop. Trip i measures it; trip i+1's `q ^ i` then reads that SAME register after
; its collapse — bd yiid, a RULED capability (owner 2026-09-14; E3 (b) BROAD
; 2026-09-15) that is not built, so the in-body reversal would replay a
; post-collapse read. Every path from the measurement back to the xor goes round
; the back edge WITHOUT re-executing q's `cqrt_alloc`, so
; `measuredParentsReadBeforeCollapse` keeps its answer and the module keeps its
; decline verbatim. A loud gap pending E3, not a physics wall (R1).
; RETIREMENT TRIGGER (L7): when E3 lands, re-derive this file with
; lowering_reject_uncompute_measured_parent_read_after_measure.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %7, label %5

5:
  %6 = phi i32 [ 0, %2 ], [ %13, %7 ]
  ret i32 %6

7:
  %8 = phi i32 [ %13, %7 ], [ 0, %2 ]
  %9 = phi i32 [ %14, %7 ], [ 0, %2 ]
  %10 = xor i32 %9, %3
  %11 = tail call i32 @cq_theta_si32(i32 %10, double 5.000000e-01)
  %12 = tail call i32 @cq_measure_si32(i32 %3)
  %13 = add nsw i32 %12, %8
  %14 = add nuw nsw i32 %9, 1
  %15 = icmp eq i32 %14, %1
  br i1 %15, label %5, label %7
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
