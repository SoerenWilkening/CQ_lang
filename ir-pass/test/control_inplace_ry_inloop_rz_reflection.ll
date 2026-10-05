; control_inplace_ry_inloop_rz_reflection.ll — ACCEPT: the in-loop Ry arm on a
; loop-invariant condition register whose compare sits in the loop block (bd
; test_C_libtooling-drbq Inc 3; written as the C-reachable spelling of shape S2).
;
;     for (...) { if (q == 5) cq_theta(&r, .9); }
;
; ⚠ THE Rz REFLECTION IS GONE. The body used to apply `q = cq_phi(q, .1)`
; (pre-3qlq register form), a diagonal gate on `q` that made it loop-variant, so
; `clang -O1` could not LICM-hoist the compare into the preheader, where P4
; declines it (PRD §13.2 row W, an over-decline), while `condWireDisposition`
; still returned `None`. The 3qlq migration deleted that uncontrolled phase, and a
; register-free phase cannot touch `q`, so this hand-kept IR is no longer the
; C-reachable spelling. (An `Ry` reflection here is the Grover customer and needs
; §13.4b — see control_inplace_ry_post_region_theta_cond.ll.)
;
; WHAT IT STILL PINS: the condition rail and the rotated rail are DISJOINT (R4),
; so the flag the mint reads is the basis the source compare describes and the
; uncontrolled `_unc` strip returns it to |0> — per activation, exactly as flat.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
;
; NOROUTE-NOT: call void @cqrt_cswap
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %q, %merge ]
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %ma = call i32 @cq_measure_si32(i32 %q)
  %mb = call i32 @cq_measure_si32(i32 %rm)
  %sum = add i32 %ma, %mb
  ret i32 %sum
}
