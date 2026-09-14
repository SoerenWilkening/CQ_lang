; E2 q5 — THE ONE THAT DECIDES THE NARROWING. `valueCarriesUndef` is
; `carriesUndefImpl(C, Seen, SkipGlobals=FALSE)` (LiteralIntegrity.cpp:113-119), so
; it walks INTO a referenced global's INITIALIZER. Here the measured operand is a
; FULLY DEFINED value — the address of `@g`, truncated — and only `@g`'s second
; field is undef. The operand is NOT `isa<UndefValue>`.
; If E2 retires the decline by REWRITING the operand to zero, this module's
; measurement reports 0 for a value the source fully defined: a VALUE CHANGE, not a
; refinement. That is why the retirement must carry z9t1's `isa<UndefValue>`
; conjunct verbatim.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@g = global { i32, i32 } { i32 1, i32 undef }
declare i32 @cq_measure_si32(i32)
define i32 @gi() {
entry:
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr @g to i32))
  ret i32 %m
}
; CHECK: error{{.*}}cq_measure_<sfx> operand is an undef/poison literal
