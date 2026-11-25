; Rule 2 classical collapse (cq-xja3): a value computed only from measured rails and classical values
; is classical. Its rail is uncomputed (uncompute's ordinary flush) and it is recomputed by classical
; instructions from the outcomes; no rail handle is returned as a C value.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; 155's shape: the merge of an arm measurement under a flag of an unmeasured register is a quantum
; select; once that register is measured, the flag and the select collapse.
define i32 @arm_merge(i32 %x0, double %tx, i32 %y0, double %ty, i32 %k, i32 %c) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %arm, label %join
arm:
  %my = call i32 @cq_measure_si32(i32 %y)
  br label %join
join:
  %m = phi i32 [ %my, %arm ], [ %c, %entry ]
  %mx = call i32 @cq_measure_si32(i32 %x)
  %r = add nsw i32 %mx, %m
  ret i32 %r
}
; CHECK arm_merge: %{{s}} = call i32 @cq_template_select_i32_ll(
; CHECK arm_merge: call void @cq_template_select_i32_ll_unc(
; CHECK arm_merge: call void @cq_template_icmp_sgt_i32_hl_unc(
; CHECK arm_merge: %{{fc}} = icmp sgt i32 %{{mx}}, %{{k}}
; CHECK arm_merge: %{{mc}} = select i1 %{{fc}}, i32 %{{my}}, i32 %{{c}}
; CHECK arm_merge: %{{r}} = add nsw i32 %{{mx}}, %{{mc}}
; CHECK arm_merge: ret i32 %{{r}}
; CHECK-COUNT arm_merge: cq_template_add 0
; CHECK-COUNT arm_merge: cqrt_measure_i32 2

; 140's merge without its rotations: both arms measure x (one measurement, the second a re-read);
; the merge under the flag x > k reads only the measured rail, so it is a classical select.
define i32 @merge_after(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %a, label %b
a:
  %ma = call i32 @cq_measure_si32(i32 %x)
  br label %j
b:
  %mb = call i32 @cq_measure_si32(i32 %x)
  %p = add nsw i32 %mb, 1
  br label %j
j:
  %r = phi i32 [ %ma, %a ], [ %p, %b ]
  ret i32 %r
}
; CHECK merge_after: %{{p}} = add nsw i32 %{{m}}, 1
; CHECK merge_after: %{{fc}} = icmp sgt i32 %{{m}}, %{{k}}
; CHECK merge_after: %{{r}} = select i1 %{{fc}}, i32 %{{m}}, i32 %{{p}}
; CHECK merge_after: ret i32 %{{r}}
; CHECK merge_after: call void @cq_template_icmp_sgt_i32_hl_unc(
; CHECK-COUNT merge_after: cqrt_measure_i32 1

; A chain computed before the measurement and used after it collapses through the original
; instructions.
define i32 @chain_before(i32 %x0, double %t) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %y = add i32 %x, 5
  %z = mul i32 %y, 3
  %m = call i32 @cq_measure_si32(i32 %x)
  %r = add i32 %z, %m
  ret i32 %r
}
; CHECK chain_before: %{{yc}} = add i32 %{{m}}, 5
; CHECK chain_before: %{{zc}} = mul i32 %{{yc}}, 3
; CHECK chain_before: %{{r}} = add i32 %{{zc}}, %{{m}}
; CHECK chain_before: ret i32 %{{r}}
; CHECK-COUNT chain_before: cq_template_add_i32_hl_unc 1
; CHECK-COUNT chain_before: cq_template_mul_i32_hl_unc 1

; No measurement among the sources: the derived rail stays a rail (162's escaped handle).
define i32 @no_measure(i32 %x0, double %t) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %y = add i32 %x, 5
  ret i32 %y
}
; CHECK no_measure: call void @cqrt_addc_i32(i32 %{{y}}, i32 5)
; CHECK no_measure: ret i32 %{{y}}
