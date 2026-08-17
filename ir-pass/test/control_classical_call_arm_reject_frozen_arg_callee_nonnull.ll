; control_classical_call_arm_reject_frozen_arg_callee_nonnull.ll — DECLINE (bd 9hea).
; ARM: the callee-side hole again, on `nonnull` rather than `range`, and via the
; `speculatable`-DECLARATION totality route where the declaration is the ONLY place a
; parameter attribute can live.
;
; *** WHY A SECOND ATTRIBUTE, AND WHY THIS ONE. *** The sibling `range` rows rest on a
; question their own header admits is unresolved here — whether LLVM 19 treats a
; `range`-violating DEFINED value as poison at a parameter. `nonnull` has no such
; ambiguity: LangRef states a violated `nonnull` yields a POISON value, and poison in a
; `noundef` parameter operand is the immediate-UB case. So this row pins the fence on a
; premise that does not depend on the open question, which is why it is committed
; alongside rather than instead.
;
; AND IT PINS THE OTHER TOTALITY ROUTE. Here the callee is a bare `declare` carrying
; `speculatable`, so `isSafeToSpeculativelyExecute` supplies totality and there is no
; body to walk. A declaration has no call-site-independent place to put a parameter
; attribute other than itself — so a fence that reads only `CallBase::getAttributes()`
; is structurally blind on this whole route, not merely unlucky.
;
; `freeze` cannot discharge it: freeze yields an ARBITRARY defined pointer, and an
; arbitrary pointer may be null, which re-poisons the parameter. The fence must refuse.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; `nonnull` lives ONLY on the declaration; the call site below is bare `noundef`.
declare i32 @pn(ptr noundef nonnull %p) #0

define i32 @example(i32 noundef %u0, ptr noundef %base, i64 %k) {
entry:
  %pp = getelementptr inbounds i32, ptr %base, i64 %k   ; poison-capable
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pn(ptr noundef %pp)   ; NOTE: no `nonnull` token at the call site
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { speculatable nounwind willreturn memory(none) }

; NOTE: no `CHECK-NOT` over the emitted stream — on a `DS_Error` cq-opt writes ZERO
; bytes to stdout, so such an assertion can never match under ANY gate behaviour.
