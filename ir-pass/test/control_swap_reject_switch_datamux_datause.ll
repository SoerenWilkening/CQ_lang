; control_swap_reject_switch_datamux_datause.ll — DECLINE (4.5 WI-4): an
; all-ConstantInt DATA-MUX switch whose merge result is consumed by stock
; arithmetic (a plain `add`) instead of a measurement / escape.
;
; THE HAZARD: the data-mux merge phi is UNTAINTED (all-ConstantInt incomings), so the
; original forward propagation never tainted any downstream user. The emitter RAUWs
; the merge to a fresh quantum handle %out and re-taints it, but does NOT re-propagate
; — so `%x = add i32 %rm, 100` is left as a stock `add` reading the i32 HANDLE as if
; it were the value (classical-over-quantum; `lowerOps` never lowers it because %x was
; classical at propagate time). `proveSwitchDataMux` declines: the merge result must
; be consumed ONLY by a measurement sink or a `ret` (escape) — over-decline is safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %x = add i32 %rm, 100
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
