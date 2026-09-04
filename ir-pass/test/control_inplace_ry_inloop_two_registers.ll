; control_inplace_ry_inloop_two_registers.ll — ACCEPT: TWO independent rotated
; registers, each with its own in-loop control-in-place Ry arm off ONE condition
; register (bd test_C_libtooling-drbq Inc 3).
;
; WHAT THIS PINS, and it is not "two of the same thing". `LoopLowering`'s
; rail-record fence groups chains PER ROOT MINT, and that grouping is load-bearing
; in BOTH directions: a gate on a DIFFERENT root's rail relabels another register
; and must NOT stale this one's record (else two independent registers in one loop
; are permanently unlowerable), while two chains sharing ONE root are one register
; wearing two SSA names and MUST interfere (Rule 8). Increment 3 makes the hoisted
; controlled Ry a chain MEMBER, i.e. a real gate in `collectRailGates` — so if the
; grouping were ever flattened, THIS fixture is what goes red first.
;
; It is also the per-wire half of the 8h7d.5 round-1 finding: the staleness
; question must be asked PER WIRE, never once for the function, or the disposition
; depends on source order and two independent registers become unlowerable.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u2)
; CHECK: loop:
; region 1 rotates R:
; CHECK: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.0
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; region 2 rotates S, off the SAME condition register:
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[S]], double 0x3FE6666666666666
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
;
; NOROUTE-NOT: call void @cqrt_cswap

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %s0 = call i32 @cq_theta_si32(i32 %u2, double 1.250000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %m2 ]
  %s = phi i32 [ %s0, %entry ], [ %sm, %m2 ]
  %i = phi i32 [ 0, %entry ], [ %inext, %m2 ]
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %m1
m1:
  %rm = phi i32 [ %rt, %arm1 ], [ %r, %loop ]
  %c2 = icmp sgt i32 %q, 3
  br i1 %c2, label %arm2, label %m2
arm2:
  %st = call i32 @cq_theta_si32(i32 %s, double 7.000000e-01)
  br label %m2
m2:
  %sm    = phi i32 [ %st, %arm2 ], [ %s, %m1 ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %ma = call i32 @cq_measure_si32(i32 %rm)
  %mb = call i32 @cq_measure_si32(i32 %sm)
  %sum = add i32 %ma, %mb
  ret i32 %sum
}
