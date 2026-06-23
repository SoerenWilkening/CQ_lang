; lowering_reject_qram_dynamic_n.ll — DECLINE (Phase 7.5 Inc 3, the §2.8(iv)
; pattern-naming decline matrix): a dynamic-N (VLA) alloca-backed tainted-index
; store. A VLA lowers to `alloca i32, i64 %n` (a SCALAR allocated type with a
; non-constant array-size operand) + a FLAT `getelementptr i32, ptr %a, %idx`. The
; provenance walk now ACCEPTS a flat gep's single origin, but the origin alloca
; `isArrayAllocation()` (no compile-time shape W × N) — a reversible memory needs a
; known shape (§0, Bennett's precondition) — so it loud-declines NAMING the dynamic
; shape (needs Persistent-DS, post-freeze; §5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)

define i32 @vla(i32 %u0, i64 %n) {
entry:
  %a = alloca i32, i64 %n, align 16            ; dynamic-N (VLA) — no known shape
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %g = getelementptr inbounds i32, ptr %a, i64 %iq   ; flat gep, not array-decay
  store i32 7, ptr %g, align 4
  ret i32 0
}

; CHECK: error{{.*}}cq QRAM access: array has no compile-time shape (dynamic-size alloca)
