; lowering_reject_uncompute_measured_parent_moved_on_some_paths.ll — DECLINE (bd
; test_C_libtooling-01po.8 review round 1, finding F2: a silent miscompile that
; f6984f85 introduced and this file pins shut). The `clang -O1` IR of
;     int slice(int x, int c){ _Bool q = x; cq_theta(&q, .25);
;       _Bool a = !q; cq_theta(&a, .5);
;       if (c) cq_theta(&q, .3);          // moves q on ONE classical path
;       cq_theta(&a, .4); return cq_measure(q); }
;
; A MOVE ON SOME PATHS DOES NOT FORCE THE RECORD. On the `c` path `a` is alive
; across `cq_theta(&q, .3)` and must stay allocated; on the other path nothing
; moves q, so the program's meaning of the dead `a` is that it is uncomputed
; at its last use (`ry(a,-.4); ry(a,-.5); xor_i1_hl_unc(a, q, 1); free(a)`, the
; bd ptue accept). f6984f85 accepted any user of q that MIGHT lie inside the
; window and leaked `a` on both paths, so the `c == 0` path measured q
; dephased by a record the program had uncomputed (the reviewer's `if (c)
; m = cq_measure(q)` twin: P(q=1) 0.1295 emitted against 0.2092 for the
; straight-line program). One reversal point cannot serve both paths, so the
; module keeps its pre-f6984f85 decline. `recordLiveAcrossMove` now requires
; the forcing gate to DOMINATE a later use of the record that dominates the
; reversal point — the move on every path, by LLVM's own dominator tree (L4).
; A loud gap (per-path disposition is not built), not a physics wall (R1).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)

define i32 @slice(i32 noundef %0, i32 noundef %1) {
  %3 = icmp ne i32 %0, 0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 2.500000e-01)
  %5 = xor i1 %4, true
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef 5.000000e-01)
  %7 = icmp eq i32 %1, 0
  br i1 %7, label %10, label %8

8:
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 3.000000e-01)
  br label %10

10:
  %11 = phi i1 [ %9, %8 ], [ %4, %2 ]
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 4.000000e-01)
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11)
  %14 = zext i1 %13 to i32
  ret i32 %14
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
