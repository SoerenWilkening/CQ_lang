; control_swap_switch_datamux.ll — a clean constant DATA-MUX switch.
;
; WI-1 (emit stubbed): every merge incoming is a ConstantInt (default v_d=3, cases
; 7/9) — a compile-time multiplexer. The classifier reaches the would-be-ACCEPT and
; fires the TRANSITIONAL "switch" decline. (Hand-written switch i32: clang -O1
; folds a small const data-mux to a select chain, so the real switch is authored by
; hand.) WI-4 graduates: lands emitSwitchDataMuxRegion (preload + XOR-delta) +
; stream CHECKs, flips accept to push, replaces this RUN.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
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
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
