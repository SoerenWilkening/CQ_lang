; control_classical_call_arm_reject_onward_ctl_spec_i128arg.ll — DECLINE (bd p3kd.9
; review round 1 F1; the i128 twin of
; control_classical_call_arm_reject_onward_ctl_spec_fparg.ll, which flipped to an accept
; when i16 became a lift-boundary width).
;
; The witness this keeps: the CHAINED onward-control (bd afmv) re-plan's ABI boundary.
; TWO chained 6.5 classical-call arms build a yn71 %out2 control rail, and the round-1
; Pending candidate `gg128` reads a WIDENED `sext i32 %out2 to i128`. At round 1 `gg128`
; reads the theta handle `q` (mask 0b10, Accept — the i128 arg is classical then). The
; afmv re-plan recomputes the mask against the FINAL post-yn71 taint (the %out2 rail is
; in the reseed set): the mask grows to 0b11, and `classifyCandidate` step (A) refuses
; the tainted i128 (no `cqrt_copy_i128`; outside `liftHandleWidth`). The re-plan
; declines LOUDLY with the precise specialization ABI message, marks the site Diagnosed
; and drops it from Pending, so the driver never clones a stale-mask body (the afmv
; analog of control_classical_call_arm_reject_onward_spec_i128arg.ll, over a yn71 %out2
; rail). RETIREMENT TRIGGER (L7): when `cqrt_copy_i128` exists, re-pin with a width
; that has no copy-out (fp128, a vector).
;
; Hand-written IR (the i16 sibling's body with i16 -> i128):
;   int f(int a) { return a + 100; }   /* pure, total */
;   int gg128(__int128 a, int b) { return (int)a * b; }
;   void example(int u0, int aa) {
;     int q = u0; cq_theta(&q, 0.25);
;     int out1 = q > 5 ? f(aa) : 5;
;     int out2 = out1 > 50 ? f(aa) : 6;
;     cq_measure(gg128((__int128)out2, q));
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; The error is the first line (no note, no generic escape message before it).
; CHECK-NOT: note:
; CHECK-NOT: unknown callee
; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; Defined, not declared (bd wve8): the 6.5 arm hoists this call and needs a totality
; proof from a visible pure body.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
; a visible pure body whose first parameter is i128 (no lift-boundary handle copy).
define i32 @gg128(i128 %a, i32 %b) {
entry:
  %e = trunc i128 %a to i32
  %s = mul i32 %e, %b
  ret i32 %s
}

define void @example(i32 %u0, i32 %aa) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @f(i32 %aa)
  br label %merge1
merge1:
  %out1 = phi i32 [ %r1, %arm1 ], [ 5, %entry ]
  %c2 = icmp sgt i32 %out1, 50
  br i1 %c2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @f(i32 %aa)
  br label %merge2
merge2:
  %out2 = phi i32 [ %r2, %arm2 ], [ 6, %merge1 ]
  %w128 = sext i32 %out2 to i128               ; an i128 %out2-derivation (reseed value)
  %z = call i32 @gg128(i128 %w128, i32 %q)     ; round-1 Pending 0b10; re-plan -> 0b11 step-A FpAbi
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
