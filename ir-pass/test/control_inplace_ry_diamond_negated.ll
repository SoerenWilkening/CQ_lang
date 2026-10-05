; control_inplace_ry_diamond_negated.ll — ACCEPT spec, the FALSE-SUCCESSOR
; polarity of the control-in-place rotation diamond (Rule 9; bd
; test_C_libtooling-drbq Inc 1).
;
;     if (q != 5) cq_theta(&r, .9);
;
; `clang -O1` canonicalizes `!=` to `icmp eq` and SWAPS the successors, so the
; gate arm is the FALSE one and the gate must fire on ¬flag. The in-place
; emitter brackets it in the SAME self-inverse `cqrt_x(flag)` pair `emitRoute`
; (today only the abort park's cswap) puts around a negated route — one spelling
; of "fires on ¬f", so the two cannot drift. Transcribed from `clang -O1` output
; (the source above compiles to exactly this shape).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; the ¬flag bracket: X, the controlled gate, X — the flag is back to `q==5`
; before the strip recomputes it
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: phi i32

; the X bracket is a PAIR — exactly two, never one (a stray X leaves the flag
; inverted at the strip, which would not return it to |0>)
; CNT-COUNT-2: call void @cqrt_x(
; CNT-NOT:     call void @cqrt_x(
