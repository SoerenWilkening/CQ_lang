; control_classical_call_arm_reject_onward_spec_newcand_i128arg.ll — DECLINE (bd p3kd.9
; review round 1 F1; the i128 twin of
; control_classical_call_arm_reject_onward_spec_newcand_fparg.ll, which flipped to an
; accept when i16 became a lift-boundary width).
;
; The witness this keeps: the round-2 DETECTION of a wholly-new candidate whose precise
; ABI decline suppresses the escape net's `kMsgUnknownCallee`. A 6.5 classical-call
; arm's `%out` is WIDENED (`sext i32 %out to i128`) and passed as the SOLE argument of
; `@g128(i128)`. Its arg was classical at round 1, so it is a round-2 NEW candidate
; (never in Pending — distinct from the re-plan twin
; control_classical_call_arm_reject_onward_spec_i128arg.ll). The round-2
; `detectSpecializations` (bd 9paa) DETECTS it (it reads the reseed `%y128`), and
; `classifyCandidate` step (A) refuses the tainted i128 (no `cqrt_copy_i128`; outside
; `liftHandleWidth`). Detection declines with the precise specialization ABI message
; and records the site Diagnosed, so the re-run `declineTaintEscapes` carve does not
; also render `unknown callee`. RETIREMENT TRIGGER (L7): when `cqrt_copy_i128` exists,
; re-pin with a width that has no copy-out (fp128, a vector).
;
; Hand-written IR (the i16 sibling's body with i16 -> i128):
;   int f(int a) { return a + 100; }   /* pure, total */
;   int g128(__int128 v) { int e = (int)v; return e * e; }
;   void example(int u0, int a) {
;     int q = u0; cq_theta(&q, 0.25);
;     int y = q > 3 ? f(a) : 5;
;     cq_measure(g128((__int128)y));
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
; a visible pure body whose SOLE parameter is i128 (no lift-boundary handle copy).
define i32 @g128(i128 %v) {
entry:
  %e = trunc i128 %v to i32
  %s = mul i32 %e, %e
  ret i32 %s
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
  %y128 = sext i32 %y to i128              ; an i128 %out-derivation (reseed value)
  %z = call i32 @g128(i128 %y128)          ; round-2 NEW candidate; tainted i128 arg -> FpAbi
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
