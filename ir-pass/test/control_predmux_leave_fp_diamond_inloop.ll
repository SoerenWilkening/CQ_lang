; control_predmux_leave_fp_diamond_inloop.ll — DECLINE (bd vyqi, W5 matrix): a
; sole-phi both-arms-write fp diamond whose entry sits ON A CFG CYCLE (inside
; a loop body). The W5 witness fires but E2 (acyclic) LEAVES the region
; byte-untouched — PredMux never flattens across a backedge (the RegionFlatten
; merge-erase would dangle the loop's header phi) — and the d8jl in-loop guard
; declines it with the accurate loop message. The loop fence survives the W5
; widening: no flat in-loop diamond is ever claimed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %q, -5.000000e-01
  br label %latch
hi:
  %b = fmul double %q, 2.000000e+00
  br label %latch
latch:
  %zv = phi double [ %a, %lo ], [ %b, %hi ]
  %m = call double @cq_measure_f64(double %zv)
  %inext = add i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head
exit:
  ret double %m
}
