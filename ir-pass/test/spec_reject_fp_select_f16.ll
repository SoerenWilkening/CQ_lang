; spec_reject_fp_select_f16.ll — ACCEPT since bd test_C_libtooling-p3kd.12 (2026-10-08). The
; FILENAME IS HISTORY, kept on purpose (CLAUDE.md L7); rename it in a change that does nothing else.
; A HALF (f16) fp select in a lifted clone body. It used to be the f16 edge pin of the
; {f32,f64,f80} select accept set ("no tested coverage"), while the PHI spelling of the
; same merge already lifted (spec_accept_clone_f16_phi_merge.ll). The width question has one
; answer now: f16 has the runtime controlled copy, and the select lowers through it.
; `mhelper(n)` = (int)|(half)n|: the controlled copies pick -x when n < 0, else x.
;
; Was: `not` + `cq specialization: callee contains tainted control flow under quantum lift`.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(
; CHECK:       %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f16(
; CHECK:       %[[NX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fneg_f16(i32 %[[X]])
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 0)
; CHECK:       %[[O:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f16(half 0xH0000)
; CHECK-NEXT:  call void @cqrt_copy_f16_controlled(i32 %[[C]], i32 %[[NX]], i32 %[[O]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[C]])
; CHECK-NEXT:  call void @cqrt_copy_f16_controlled(i32 %[[C]], i32 %[[X]], i32 %[[O]])
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to half
  %c  = icmp slt i32 %n, 0
  %nx = fneg half %x
  %a  = select i1 %c, half %nx, half %x
  %r  = fptosi half %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
