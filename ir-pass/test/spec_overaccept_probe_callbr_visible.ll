; spec_overaccept_probe_callbr_visible.ll — Phase 6.4 WI-4.3 over-accept probe.
; A `callbr` (asm-goto) is a `CallBase` that is not a `CallInst`, excluded by the
; same `dyn_cast<CallInst>` SHAPE narrowing as `invoke`. Its tainted operand never
; enters `plan6` and STILL fires `kMsgUnknownCallee`. Guards the `CallBrInst`
; exclusion against a future weakening that handles arbitrary `CallBase`.
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
