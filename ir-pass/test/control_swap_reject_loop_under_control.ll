; control_swap_reject_loop_under_control.ll — Phase 7.2 Inc 4 DECLINE: a tainted-
; condition `br` one of whose arms is a self-`br` infinite loop (`%spin: br
; %spin`) with NO recognized noreturn sink. This is the §2.11-C-ii divergent-arm
; case — a non-`abort` divergence is NOT a park (only the named libc sinks
; provably TERMINATE, so the park's "no coherent downstream" premise does not
; hold for a loop) — DEFERRED to 7.3/7.4 (bounded loops / `break`) with the
; dedicated `loop` diagnostic. Hand-constructed (clang does not emit a bare self-
; loop here); the `loop` row is checked BEFORE the value-exit row so the divergent
; arm reports the divergence, not the `%cont` value sibling.
;
; classifyAbortPark → NotApplicable (no `unreachable`-after-recognized-sink arm);
; recoverRegion → OffPattern (the self-loop arm has 2 preds, so it is not a single-
; pred diamond arm, and its `uncondSucc` is itself, not the merge); the partition
; sees the self-`br` arm → `loop`. Over-declining is always safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}loop under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %spin, label %cont
spin:
  br label %spin                                   ; divergent: self-`br` loop
cont:
  ret i32 0
}
