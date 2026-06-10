; lowering_reject_taint_escape_store_global.ll — DECLINE: tainted value STORED
; to a global — the non-call memory escape of the taint-escape family
; (test_C_libtooling-bxv audit).
;
; Taint is SSA-only: it never flows through memory, so a `store` of a tainted
; value exits the discipline's visibility entirely. After rotation lowering's
; RAUW the store writes the RUNTIME HANDLE TAG to @g; a later classical `load`
; of @g reads the tag as data, UNTAINTED — verify-clean silent miscompile. At
; -O1 stores to globals DO survive mem2reg (only non-escaping locals are
; promoted), so this is reachable from plain C (`g = q;`).
;
; The handle is deliberately ALSO measured: a measured handle returns
; `FreePointKind::Measured` BEFORE FreePoint's FirstUnrecognized check
; (FreePoint.cpp §2.5 ordering), so the Phase-5 "unrecognized user" net is
; bypassed and HEAD 6ac1ae3 accepted this shape silently (exit 0,
; `store i32 %h, ptr @g` in the output). The store-without-measure variant was
; already loud via that net; this fixture pins the hole.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@g = global i32 0

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  store i32 %q, ptr @g                            ; escapes the SSA taint domain
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
