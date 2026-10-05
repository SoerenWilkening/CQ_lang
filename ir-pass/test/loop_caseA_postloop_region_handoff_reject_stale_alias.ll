; loop_caseA_postloop_region_handoff_reject_stale_alias.ll — DECLINE (bd
; test_C_libtooling-wt8u's unsafe neighbour). `clang -O1` output (attributes and
; metadata dropped) of
;
;     int slice(int n) {
;       int q = 0; cq_theta(&q, .5);
;       int r = 0; cq_theta(&r, .25);
;       cq_theta(&r, q == 5 ? .9 : .3);
;       for (int i = 0; i < n; i++) cq_theta(&r, .1);
;       int s = r;                                   // post-loop record of r
;       if (q == 3) cq_theta(&r, .2);                // moves r's wire under control
;       return cq_measure(s) + cq_measure(r);        // s read past that gate
;     }
;
; WHAT IT PINS. wt8u hands a post-loop tainted region's consumers of the rail
; (the arm's `theta(%9, .2)` and the merge φ) to the control chain instead of
; absorbing them into the loop's rail. `cq_measure(s)` reads the loop's exit φ
; `%9` AFTER the region, and on the q == 3 path the arm's Ry has moved the one
; register `%9` names, so after the collapse `measure(h_r)` would read the
; post-Ry wire where the source reads the pre-Ry record. The record-liveness
; fence (`staleRailRecordRead`) asks every non-member read of a rail value
; positionally, a hand-off arm gate counts as a rail GATE for that walk
; (`collectRailGates`' in-place-rotation edge), and the walk `%9` → `%18` →
; `%21` finds it. Declined identically on main (where the arm gate was a rail
; member); this fixture keeps it declined once the region is handed off.
; Accept twin: `loop_caseA_postloop_region_handoff.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  %4 = icmp eq i32 %2, 5
  %5 = select i1 %4, double 9.000000e-01, double 3.000000e-01
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %5)
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %11, label %8

8:
  %9 = phi i32 [ %6, %1 ], [ %14, %11 ]
  %10 = icmp eq i32 %2, 3
  br i1 %10, label %17, label %19

11:
  %12 = phi i32 [ %15, %11 ], [ 0, %1 ]
  %13 = phi i32 [ %14, %11 ], [ %6, %1 ]
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 1.000000e-01)
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %0
  br i1 %16, label %8, label %11

17:
  %18 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.000000e-01)
  br label %19

19:
  %20 = phi i32 [ %18, %17 ], [ %9, %8 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %20)
  %23 = add nsw i32 %22, %21
  ret i32 %23
}
