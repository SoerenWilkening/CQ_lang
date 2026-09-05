; control_inplace_ry_post_region_theta_negated.ll — ACCEPT (FLAT, no loop): the
; P1 clause (PRD §13.4b) at NEGATED polarity.
;
;     if (q != 5) r = cq_theta(r, .9);
;     q = cq_theta(q, .3);              <-- the Ry reflection on the CONDITION
;
; `clang -O1` canonicalizes `if (u != k)` to `icmp eq` with the successors
; SWAPPED (Rule 9), so the gate arm is the FALSE successor and the emitter must
; bracket the flag with a self-inverse `cqrt_x`. The body below is written in that
; canonical form deliberately — it is what the pass actually sees.
;
; WHY THIS FILE EXISTS (bd test_C_libtooling-drbq Inc 3, round-1 lens L8, finding
; F-L8-2): P1 shipped with one flat accept fixture at DIRECT polarity, and the
; lens named negated polarity as one of the two it would add at minimum. The
; interaction being pinned is real rather than cosmetic: P1's soundness argument
; is that the region's ENTIRE emitted stream precedes the deferred gate, and at
; negated polarity that stream has two more calls in it — the `cqrt_x` bracket —
; one of which sits BETWEEN the mint and the controlled rotation. Measured (L8
; `p10_negated.c`, plain C at `-O1`, ORACLE DECLINE -> HEAD ACCEPT, linked and run,
; strict stage 2b clean): the bracket is paired, the strip reads the same handle
; the mint wrote, and the reflection still lands after the free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; the ¬flag bracket, both halves, around the controlled rotation:
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.0
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.0
;
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c  = icmp eq i32 %q, 5
  br i1 %c, label %merge, label %arm            ; GATE ARM IS THE FALSE SUCCESSOR
arm:
  %rt = call i32 @cq_theta_si32(i32 %r0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r0, %entry ]
  %qn = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %ma = call i32 @cq_measure_si32(i32 %qn)
  %mb = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %ma, %mb
  ret i32 %s
}
