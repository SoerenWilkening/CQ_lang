; spec_reject_syscall.ll — Phase 6.4 WI-4.1: a callee body containing a direct
; call to the libc `syscall` trap is an irreversible kernel side effect. This is
; the ONE exact-name match in the classifier — an external libc SYMBOL the pass
; lowers nothing for, never a taint-identity decision (the no-name-prefix
; discipline of C7 governs `cq_*` intrinsic identification, a different axis).
; Recorded in `plan6.Diagnosed`, so the carve-out does NOT also emit the generic
; `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @syscall(i64)

define i32 @helper(i32 %x) {
entry:
  %s = call i64 @syscall(i64 39)
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (syscall)
; CHECK-NOT: cq taint escape
