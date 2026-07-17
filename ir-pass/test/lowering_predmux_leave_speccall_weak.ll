; lowering_predmux_leave_speccall_weak.ll — DECLINE probe (bd adia Rule-13
; board, the CONFIRMED fence gap): the pending-spec pure-callee proof
; requires `hasExactDefinition()` — an INTERPOSABLE definition (weak /
; linkonce / common) may be replaced by the linker at stage 3, so a purity/
; termination proof read off the module-local body must never be baked into
; the speculated hoist and the Bennett clone (the analyzed semantics would be
; emitted while a different function links — verify-clean). weak_odr /
; linkonce_odr are ODR-exact and stay admitted. E4 leaves the region and the
; existing loud nested-control decline fires, char-for-char.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define weak i32 @purefn(i32 %a) {
  %t = mul i32 %a, 3
  %r = add i32 %t, 7
  ret i32 %r
}
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
