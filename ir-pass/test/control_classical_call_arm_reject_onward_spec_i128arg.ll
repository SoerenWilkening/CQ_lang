; control_classical_call_arm_reject_onward_spec_i128arg.ll — DECLINE (bd p3kd.9 review
; round 1 F1; the i128 twin of control_classical_call_arm_reject_onward_spec_i16arg.ll,
; which flipped to an accept when i16 became a lift-boundary width).
;
; The witness this keeps: the round-2 RE-PLAN of a round-1 Pending candidate that
; cannot be unfrozen. A 6.5 classical-call arm's `%out` is WIDENED (`sext i32 %out to
; i128`) and passed to `@ipow128(i32, i128)`. At round 1 the merge is untainted, so
; `%y128` is classical and the candidate is masked `0b01` (Accept — arg0 the theta
; handle is i32). The round-2 re-plan recomputes the mask to `0b11` and re-classifies:
; `classifyCandidate` step (A) admits a tainted argument only at a lift-boundary width
; (`liftHandleWidth`: i1..i64, f16..f80), and i128 has no `cqrt_copy_i128`. So the
; re-plan declines LOUDLY with the precise specialization ABI message (NOT dugh's
; generic "under quantum control", NOT the escape net's "unknown callee"), marks the
; site Diagnosed and drops it from Pending, so the driver never clones a stale-mask
; body. A compiler gap, not a physics limit (R1). RETIREMENT TRIGGER (L7): when
; `cqrt_copy_i128` exists, `liftHandleWidth` admits i128 and this becomes an accept;
; pick another width without a copy-out (fp128, a vector) to keep the path pinned.
;
; Hand-written IR (the i16 sibling's body with i16 -> i128):
;   int f(int a) { return a + 100; }   /* pure, total */
;   int ipow128(int base, __int128 exp) { return base * base + (int)exp; }
;   void example(int u0, int a) {
;     int q = u0; cq_theta(&q, 0.25);
;     int y = q > 3 ? f(a) : 5;
;     cq_measure(ipow128(q, (__int128)y));
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; bd 3c6m.82 (LiftDiagnostics.h): this error is located in the USER's function while the
; re-plan lifts the site, so no "lifted from here" note precedes it (a note would print first).
; CHECK-NOT: note:
; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; Defined, not declared (bd wve8): the 6.5 arm hoists this call and needs a totality
; proof from a visible pure body.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
; a visible pure body whose second parameter is i128 (no lift-boundary handle copy).
define i32 @ipow128(i32 %base, i128 %exp) {
entry:
  %e = trunc i128 %exp to i32
  %sq = mul i32 %base, %base
  %r = add i32 %sq, %e
  ret i32 %r
}

define void @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %y128 = sext i32 %y to i128                 ; an i128 %out-derivation
  %z = call i32 @ipow128(i32 %q, i128 %y128)  ; arg1 = tainted i128 -> re-plan step (A) FpAbi
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
