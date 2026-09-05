; control_angle_select_reject_second_select_same_cmp.ll — DECLINE (S4): TWO angle
; selects on ONE compare (bd drbq Inc 2b).
;
;     if (q == 5) { r = cq_theta(r,.9); r = cq_theta(r,.8); }
;     else        { r = cq_theta(r,.3); r = cq_theta(r,.2); }
;
; `clang -O1` folds TWO gates per arm into TWO selects sharing ONE `icmp`
; (measured — probe q5). S4's `Cond->hasOneUse()` refuses it.
;
; WHY IT IS NOT MERELY A COUNT. Each accepted select mints its OWN flag from the
; compare and strips it, so two selects on one compare would emit mint/strip
; TWICE over an interleaved gate stream — sound only if each strip's window
; contains no gate that moves the condition's basis, which is a per-window proof
; nothing here performs. Sharing one flag across both is the better lowering and
; is the recorded follow-on; refusing is the Prime-Directive answer until it is
; built.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %a1 = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %a2 = select i1 %c, double 8.000000e-01, double 2.000000e-01
  %t1 = call i32 @cq_theta_si32(i32 %r, double %a1)
  %t2 = call i32 @cq_theta_si32(i32 %t1, double %a2)
  %m = call i32 @cq_measure_si32(i32 %t2)
  ret i32 %m
}
