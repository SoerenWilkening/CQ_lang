; lowering_reject_io_result_used.ll — DECLINE (Phase 7.6): the RESULT of a tainted
; output call is consumed (`int n = printf("%d", q); return n`). The tape lowering
; ERASES the sink call, so a used result cannot be cleanly dropped — it declines
; LOUDLY rather than silently lose the value (this is the "tainted printf result
; re-entering taint" guard, PRD-7.6 §3 deliverable 5). `printf`/`putchar` results
; are normally ignored, so the accepted shape is unaffected.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.d = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %n = call i32 (ptr, ...) @printf(ptr @.d, i32 %q)
  ret i32 %n
}

; CHECK: error{{.*}}cq I/O output sink: result of a tainted output call is used
