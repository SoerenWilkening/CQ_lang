; control_classical_call_arm_reject_localarray_store.ll — DECLINE (dugh, Phase 4×6;
; the DEFERRED capability, follow-on bead d3ji): a 6.5 classical-call arm whose
; UNTAINTED merge (`int y = 5; if (q>3) y = f(a)`) is STORED into a local scratch
; array (`arr[i] = y`) at a CLASSICAL index, then loaded back and measured.
;
; Storing a QUANTUM HANDLE into memory is NOT reachable by dugh's re-propagation: the
; store of a tainted value is an escape (taint is SSA-only). The Phase-7.5 Shadow
; model accepts only `arr[q] = classical_value` (TAINTED index, CLASSICAL value) — it
; never models a quantum handle written into a slot (`matchQramAccess` returns nullopt
; for the classical-index gep here). So after `repropagateControlMerges` re-taints
; `%out`, the store declines via the precise `kMsgStore`. Owner-directed defer
; (2026-07-04): the clean fix is a g7ip-sibling store→load forwarding (prove the
; scratch slot is single-write/single-read/no-alias/no-escape, RAUW the load to
; `%out`) — a distinct mechanism tracked in the follow-on bead. This fixture pins the
; SAFE over-decline in the interim (Prime Directive). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}tainted value stored to memory
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
define i32 @example(i32 %u0, i32 %a, i32 %i) {
entry:
  %arr = alloca [8 x i32]
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]         ; UNTAINTED merge (a quantum handle)
  %slot = getelementptr [8 x i32], ptr %arr, i32 0, i32 %i
  store i32 %y, ptr %slot                           ; store the qubit handle to memory
  %v = load i32, ptr %slot
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
