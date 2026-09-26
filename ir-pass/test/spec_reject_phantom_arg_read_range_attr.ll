; spec_reject_phantom_arg_read_range_attr.ll — DECLINE (bd test_C_libtooling-vsfp, the TOTAL
; half: `declinePhantomCloneArgReads`). HAND-WRITTEN IR.
;
; `@h` ignores `%a`, the bead's shape, but `%a` carries `range(i32 1, 100)`: a null
; constant would violate it, so the dead-argument drop's attribute whitelist
; (noundef/signext/zeroext/inreg only) leaves the call alone — the predictor is
; deliberately conservative, and this is its miss. The operand is the 4.4 bool-select
; `%out` rail (`select i1 %b, i32 9, i32 4`), a which-path copy of `%b`, read only by the
; clone that ignores it, across Ry(.7) on `%b`: on the oracle (`main` aee8f4f8) a SILENTLY
; dephased circuit (exit 0, no warning, stage 2b clean). After `specialize()` the backstop
; sees the built clone's parameter 0 with no uses and a non-`cq_theta` tainted operand in
; that slot, and declines. The CHECK-NOT pins that the DROP did not fire — so the fence
; that speaks is the observer, not the predictor.
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}in function main{{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @h(i32 range(i32 1, 100) %a, i32 %k) {
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
