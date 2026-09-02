; control_inplace_ry_dead_base_frozen.ll — ACCEPT + FREEZE: the rotated register
; is DEAD after the region, and the whole-DAG uncompute spine leaves it ALLOCATED
; rather than reverse-playing and freeing it (bd test_C_libtooling-drbq Inc 1;
; Rule 6's documented fallback).
;
;     int q=cq_theta(0,.5); int r=cq_theta(0,.3);
;     if (q > 5) r = cq_theta(r, .9);
;     return cq_measure(q);              // r is dead
;
; WHY THE SPINE MUST NOT TOUCH IT: a controlled gate's adjoint NEEDS ITS CONTROL,
; and the flag lives and dies inside the region's own stream (mint · gate · strip
; · free) exactly as on the phase path. The spine runs LAST and places a rail's
; reversal after that rail's final user, so for any register with a post-region
; consumer that point is AFTER `cqrt_free(flag)` — and
; `cqrt_ry_<W>_controlled(flag, h, -θ)` on a freed (reset) flag fires on |0>,
; i.e. never, leaving the register dirty for the spine's own `cqrt_free` to
; collapse (Rules 6/8). See control_inplace_ry_dead_base_late_use_frozen.ll for
; the measured emission of exactly that.
;
; FROZEN UNIFORMLY, INCLUDING HERE, WHERE REVERSAL WOULD HAVE BEEN SOUND. With no
; post-region user the spine's reversal happens to land BEFORE the flag free —
; but that is a property of where `dagInsertPoint` puts things, not an invariant
; anyone proved. Uniform-and-provable over conditional-and-lucky; the cost is one
; leaked rail on a dead register (qubits are not scarce, PRD §8.2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl
; CHECK:     call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]],
; CHECK:     call void @cqrt_free(i32 %[[F]])
; NO adjoint of the controlled rotation, and NO free of the frozen register:
; CHECK-NOT: double -9.000000e-01
; CHECK-NOT: double -3.000000e-01
; CHECK-NOT: call void @cqrt_free(i32 %[[R]])
