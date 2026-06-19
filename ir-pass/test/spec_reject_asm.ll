; spec_reject_asm.ll — Phase 6.4 WI-4.1: a callee body containing INLINE ASSEMBLY
; is an opaque, non-reversibilizable construct (PRD §2.11). Detected by
; `CallBase::isInlineAsm()` (a call whose "callee" is an `InlineAsm`, never a
; `Function`). Recorded in `plan6.Diagnosed`, so the carve-out does NOT also emit
; the generic `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %a = call i32 asm sideeffect "nop", "=r,r"(i32 %x)
  %y = add i32 %a, 1
  ret i32 %y
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (inline assembly)
; CHECK-NOT: cq taint escape
