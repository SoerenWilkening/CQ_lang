; spec_reject_atomic.ll — Phase 6.4 WI-4.1: a callee body with an ATOMIC
; read-modify-write is a synchronizing memory side effect, never a pure
; reversible value op (PRD §2.11). Detected by `AtomicRMWInst`/`AtomicCmpXchgInst`/
; `FenceInst`. Recorded in `plan6.Diagnosed`, so the carve-out does NOT also emit
; the generic `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x, ptr %p) {
entry:
  %a = atomicrmw add ptr %p, i32 %x seq_cst
  %y = add i32 %x, %a
  ret i32 %y
}

define i32 @example(i32 %u0, ptr %p) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, ptr %p)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (atomic)
; CHECK-NOT: cq taint escape
