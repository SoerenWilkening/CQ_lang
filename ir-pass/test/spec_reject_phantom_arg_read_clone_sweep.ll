; spec_reject_phantom_arg_read_clone_sweep.ll — DECLINE (bd test_C_libtooling-vsfp, the TOTAL
; half: `declinePhantomCloneArgReads` OBSERVES the built clone). HAND-WRITTEN IR.
;
; `@h` USES `%a` — `icmp sgt i32 %a, 3` steers a branch whose arms are EMPTY and whose
; merge carries no phi (`clang -O1` would have deleted it; hence IR) — so the drop, keyed
; on `use_empty()` of the callee's parameter, correctly does nothing. Inside the clone the
; branch is tainted: the scoped PredMux flatten (claimAll) removes it and its sweep takes
; the dead compare, so the BUILT `__cq_q_h_01` never reads parameter 0. That is the
; property only an observer after `specialize()` can see (the "observe, don't predict"
; lesson of bd woa0). The operand is the 4.4 bool-select `%out` rail, left entangled
; across Ry(.7) on the oracle (`main` aee8f4f8): silent, exit 0, stage 2b clean.
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}in function main{{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @h(i32 %a, i32 %k) {
entry:
  %c = icmp sgt i32 %a, 3
  br i1 %c, label %t, label %e
t:
  br label %e
e:
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %b = call i1 @cq_theta_i1(i1 %lo, double 5.000000e-01)
  %p = select i1 %b, i32 9, i32 4
  %t = call i32 @h(i32 %p, i32 %m)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 7.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %mz = zext i1 %mm to i32
  %s = add i32 %t, %mz
  ret i32 %s
}
