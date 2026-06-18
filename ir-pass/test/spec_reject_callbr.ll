; spec_reject_callbr.ll — Phase 6.1 WI-1.3b: a tainted-arg `callbr` (a `CallBase`
; that is not a `CallInst`) is excluded by the same `dyn_cast<CallInst>`
; narrowing as `invoke`, so it never enters `plan6` and STILL fires
; `kMsgUnknownCallee`. (A valid `callbr` is asm-goto — its "callee" is inline
; asm; the point is the `CallBrInst` exclusion, like `InvokeInst`.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  callbr void asm sideeffect "", "r,!i"(i32 %q) to label %ok [label %bad]
ok:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
bad:
  ret i32 0
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
