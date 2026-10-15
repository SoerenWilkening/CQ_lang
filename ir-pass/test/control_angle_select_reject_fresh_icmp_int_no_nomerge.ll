; control_angle_select_reject_fresh_icmp_int_no_nomerge.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, item A2): the R10 twin of
; `control_angle_select_ry_fresh_icmp_int.ll` — the SAME module with the
; call-site `nomerge` removed. Without it the single theta on the literal seed may
; be the image of a SimplifyCFG sink of two thetas (drbq.13), so the literal base
; keeps the drbq.13 decline and its string.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %x = call i32 @cq_theta_si32(i32 0, double 1.000000e+00) 
  %c = icmp eq i32 %x, 3
  %ang = select i1 %c, double 3.000000e-01, double 0x3FE6666666666666
  %t = call i1 @cq_theta_i1(i1 false, double %ang) 
  %mx = call i32 @cq_measure_si32(i32 %x)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %zt = zext i1 %mt to i32
  %s = add i32 %mx, %zt
  ret i32 %s
}

attributes #0 = { nounwind }
