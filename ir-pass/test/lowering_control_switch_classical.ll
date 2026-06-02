; lowering_control_switch_classical.ll — Family D (WP12), positive guard. A
; `switch` on a CLASSICAL scrutinee (`%k`, a plain parameter — not derived from
; any `cq_theta`) is NOT under quantum control and must be left untouched, even
; in a module that also carries quantum ops (so the pass runs). The WP12 guard
; fires strictly on `taint.Tainted.count` of the switch condition, so a
; classical switch survives verify-clean with no diagnostic (exit 0).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The classical switch survives unchanged; the quantum handle still lowers.
; CHECK:     switch i32 %k
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i32)
define i32 @example(i32 %u0, i32 %k) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %k, label %dflt [
    i32 0, label %c0
    i32 3, label %c3
  ]
c0:
  call void @sink(i32 1)
  br label %merge
c3:
  call void @sink(i32 2)
  br label %merge
dflt:
  call void @sink(i32 9)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
