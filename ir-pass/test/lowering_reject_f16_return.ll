; lowering_reject_f16_return.ll — Phase 7.1 Increment D: a tainted `half` RETURN
; declines. Now that f16 is a recognized width, a live tainted half can reach a
; `ret half`; but the runtime handle is ALWAYS i32 (RotationLowering RAUWs every
; tainted value to its i32 alloc handle), and a `ret` is never erased, so
; returning a tainted value at a non-i32 width would leave `ret half <i32
; handle>` — a broken module. The kMsgNonI32Return gate declines pre-RAUW
; (TaintPropagation.cpp), converting that abort into a clean source-located
; decline. i32-width tainted rets stay accepted; a measured (classical) half
; return is untouched (lowering_measure_f16.ll covers that ACCEPT).
;
; bd p3kd.21 (R11 r1 item 4; owner ruling owner-ruling-p3kd21-gate-subroutines-2026-10-14):
; briefly an accept on 11adde57 (the export's return re-declared `i32`), restored to
; this decline: a C caller of a `half` export reads the FP register, never the
; integer handle. The handle ABI is approved for integer returns of 32 bits or wider.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value returned at non-i32 width
; CHECK-NOT: cqrt_measure_f16

declare half @cq_theta_f16(half, double)

define half @example(half %s) {
entry:
  %a = call half @cq_theta_f16(half %s, double 5.000000e-01)
  %b = fadd half %a, 0xH3C00
  ret half %b
}
