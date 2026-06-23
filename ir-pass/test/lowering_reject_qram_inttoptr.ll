; lowering_reject_qram_inttoptr.ll — DECLINE (Phase 7.5 Inc 3, the §2.8(iv)
; pattern-naming decline matrix): a tainted-index read with NO pointer provenance —
; the address is FORGED from the tainted index via `inttoptr`, not a
; `getelementptr` off a known-shape origin. With no single `PtrOrigin` and no
; compile-time shape, reversibility is impossible (no-cloning / linearity,
; [[pointer-boundary-linearity-bennett]]): the provenance walk hits the `inttoptr`
; and loud-declines NAMING the pattern (the Bennett signpost model). PERMANENT
; decline (PRD-7.5 §0, §5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @forged(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = inttoptr i32 %q to ptr        ; no provenance — a forged address
  %v = load i32, ptr %p
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}

; CHECK: error{{.*}}cq QRAM access: pointer has no static array provenance
