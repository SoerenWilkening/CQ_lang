; spec_accept_fp_select_classical_cond.ll — ACCEPT (bd p3kd.7.2; was
; spec_reject_fp_select_mixed.ll, the kmdc taint re-proof): an fp select whose
; condition tests a CLASSICAL parameter while both arms derive from a QUANTUM one,
; `(m < 0) ? -(double)n : (double)n`. A classical choice of rail (owner ruling
; 2026-10-06; CloneRailSelect.h): after `lowerOps` the select chooses between the
; two fp handles, and the downstream `fcmp` reads the chosen handle. The reverse
; replays every template on its own operands, the `fcmp` `_unc` reading the same
; select value, hence the same rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n, i32 %m) {
  %x  = sitofp i32 %n to double        ; arms derive from TAINTED %n
  %c  = icmp slt i32 %m, 0             ; condition tests CLASSICAL %m
  %nx = fneg double %x
  %a  = select i1 %c, double %nx, double %x
  %cmp = fcmp ogt double %a, 1.000000e+00   ; p119: stock consumer (was ilogb)
  %r  = zext i1 %cmp to i32
  ret i32 %r
}
define void @example(i32 %u0, i32 %u1) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q, i32 %u1)   ; arg0 tainted, arg1 classical
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK-LABEL: define internal i32 @__cq_q_mhelper_01(i32 %n, i32 %m)
; CHECK-NEXT:  %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK-NEXT:  %[[C:[a-zA-Z0-9_.]+]] = icmp slt i32 %m, 0
; CHECK-NEXT:  %[[NX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fneg_f64(i32 %[[X]])
; CHECK-NEXT:  %[[FC:[a-zA-Z0-9_.]+]] = freeze i1 %[[C]]
; CHECK-NEXT:  %[[S:[a-zA-Z0-9_.]+]] = select i1 %[[FC]], i32 %[[NX]], i32 %[[X]]
; CHECK-NEXT:  %[[G:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[S]], double 1.000000e+00)
; CHECK:       call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[G]], i32 %[[S]], double 1.000000e+00)
; CHECK-NEXT:  call void @cq_template_fneg_f64_unc(i32 %[[NX]], i32 %[[X]])
; CHECK-NEXT:  call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[X]], i32 %n)
