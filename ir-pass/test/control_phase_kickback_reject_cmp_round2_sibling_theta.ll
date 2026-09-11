; control_phase_kickback_reject_cmp_round2_sibling_theta.ll — DECLINE (Track A.1,
; bd test_C_libtooling-9pum): the ROUND-2 TAINT WINDOW at the `br` KICKBACK, with
; a COMPARE leaf. Same window as
; `control_swap_reject_select_cmp_round2_sibling_theta.ll`, different consumer —
; here the flag carries `cqrt_rz_i1` rather than two controlled copies, and it is
; minted from `Ry(.9)Ry(.5)|y>` while `if (b > 0)` names `Ry(.5)|y>`. ACCEPT on
; `main` 0c7380c (exit 0, verify-clean). The rail twin is
; `control_phase_kickback_reject_rail_round2_sibling_theta.ll`.
;
; THE KICKBACK GETS NO CLASSIFIER CLAUSE FOR THIS RUNG — it is caught by
; `reverifyCmpCondReads` over the record `lowerCompareToFlag` writes, which is
; the point of recording inside the shared mint rather than at each emitter.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = add i32 %y, 0
  br label %second

second:
  %b = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %b3 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %cc = icmp sgt i32 %b, 0
  br i1 %cc, label %ph, label %join

ph:
  call void @cq_phi(double 7.000000e-01)
  br label %join

join:
  %mm = call i32 @cq_measure_si32(i32 %b3)
  %t = add i32 %mm, %keep
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
