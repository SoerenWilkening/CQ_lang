; spec_reject_setjmp.ll — Phase 6.4 WI-4.1: a callee body that calls a
; `returns_twice` function (setjmp/sigsetjmp) can re-enter mid-stream, breaking
; the single-entry straight-line assumption the Bennett reverse needs. Keyed on
; the ATTRIBUTE clang stamps on setjmp (its longjmp twin is `noreturn`), NOT the
; name (Rule 11/C7). Recorded in `plan6.Diagnosed`, so the carve-out does NOT
; also emit the generic `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @setjmp(ptr) returns_twice

define i32 @helper(i32 %x, ptr %buf) {
entry:
  %j = call i32 @setjmp(ptr %buf)
  %y = add i32 %x, %j
  ret i32 %y
}

define i32 @example(i32 %u0, ptr %buf) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, ptr %buf)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (setjmp/longjmp)
; CHECK-NOT: cq taint escape
