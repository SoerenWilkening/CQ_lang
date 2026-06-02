; lowering_control_angle_select.ll — Family B1 (WP9, retained after WP10).
; A tainted-condition `select` over a `double` is a non-handle value chosen
; under quantum control. WP10 lowers the COMMON case — a clean rotation-angle
; feed (`rz(u, select(cmp,a,b))`) — as controlled-rotation-by-difference (see
; lowering_control_angle_rotdiff.ll). But a double-select whose result is used
; somewhere OTHER than a rotation angle (here a classical `@use_angle` call) is
; a classical value computed under quantum control that the pass cannot lower —
; it stays a loud diagnostic (the WP9 B1 guard), never a silent miscompile.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @use_angle(double)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  %sel = select i1 %c, double %a, double %b   ; double under quantum control
  call void @use_angle(double %sel)            ; NOT a rotation angle — unlowerable
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
