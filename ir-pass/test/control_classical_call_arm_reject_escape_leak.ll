; control_classical_call_arm_reject_escape_leak.ll — HANDLE-LEAK reject (8mld): a
; PURE classical call inside a tainted-condition diamond arm whose i32 merge phi is
; consumed by a `store` (equally: an opaque call, or a stock arithmetic op). The
; 6.5 emitter RAUWs the merge phi to the FRESH `%out` QUBIT handle; a non-measure /
; non-`ret` consumer then reads that handle as if it were the classical value —
; `store i32 <handle>` SILENTLY writes the register id to memory. That is a
; verify-clean over-accept (opt exits 0, module verifies) — the classical-over-
; quantum leak the switch data-mux `proveSwitchDataMux` G6 already rejects, but
; which the classical-call arm had NO gate for before 8mld.
;
; The merge is UNTAINTED (classical call result + constant), so `declineTaintEscapes`
; (TAINT-gated) never fires — the value/phase-diamond `store` is caught there, the
; classical-call arm's is not. The MERGE-OUT ESCAPE GATE restricts merge consumers
; to a measurement sink (any width) or an i32 `ret`; a `store` DECLINES loudly.
; NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @f(i32) #0

define void @example(i32 %u0, i32 %a, ptr %p) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)                        ; PURE, all-classical args — 6.5 shape
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]        ; UNTAINTED i32 merge
  store i32 %y, ptr %p                            ; LEAK: writes the qubit handle to memory
  ret void
}

attributes #0 = { nounwind willreturn memory(none) }
