; lowering_reject_io_lookalike_callee.ll — DECLINE (Phase 7.6): a look-alike callee
; `printf_helper` must NOT be carved as an I/O sink. The carve and the emitter use
; EXACT-name membership (`N == "printf" || N == "putchar"`), NEVER a
; `starts_with("printf")` prefix (the cq_theta_evil over-accept hazard). So a user
; function whose name merely begins with `printf` still escapes as an UNKNOWN
; callee — proving exact-name discipline on the ACCEPT side.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf_helper(ptr, ...)
@.d = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf_helper(ptr @.d, i32 %q)
  ret void
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
