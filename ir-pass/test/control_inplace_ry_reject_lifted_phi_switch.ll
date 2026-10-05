; control_inplace_ry_reject_lifted_phi_switch.ll — DECLINE. The N-WAY CLASSICAL
; `switch` spelling of the R6 launder (round-1 Rule-13 review, lens L2 §1;
; MEASURED accepting before the fix). Read
; `control_inplace_ry_reject_lifted_phi_measure.ll`'s header for the mechanism.
;
;     int m;
;     switch (c) { case 0: m = r; break;      // pre-3qlq: m = cq_phi(r,.1)
;                  case 1: m = r; break;      // pre-3qlq: m = cq_phi(r,.2)
;                  default: m = r; }
;     if (q == 5) { cq_theta(&r, .9); }
;     return cq_measure(m) + cq_measure(r) + cq_measure(q);
;
; WHY A SEPARATE FIXTURE FROM THE `if/else` ONE: the launder is not "a diamond";
; it is ANY classical CFG join over one register. Pre-3qlq `clang -O1` lowered
; this switch to a two-predecessor merge φ over the shared `cq_phi` result and
; the base; the CFG remains (the φ now names `r` on both edges), so it reaches
; R6 through a φ with a DIFFERENT provenance than the if/else. Pinning only one
; spelling would leave the fence looking like a diamond-shaped guard, which is
; exactly the "a STRUCTURAL guard wearing a semantic label" failure this project
; has already paid for once (bd hcrg).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  switch i32 %c, label %join [
    i32 0, label %case0
    i32 1, label %case1
  ]
case1:
  br label %case0
case0:
  %ang = phi double [ 2.000000e-01, %case1 ], [ 1.000000e-01, %entry ]
  br label %join
join:
  %m = phi i32 [ %r, %entry ], [ %r, %case0 ]
  %t = icmp eq i32 %q, 5
  br i1 %t, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %join ]
  %a = call i32 @cq_measure_si32(i32 %m)
  %b = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %a, %b
  ret i32 %s
}
