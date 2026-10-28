; Rules 9, 20: a store under a quantum predicate is select(predicate, value, old) into a fresh rail; the
; classical initial store is a seed (homogeneity, rule 7); the load in the arm forwards the select.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @guarded_store(i32 %x0, double %t, i32 %k, i32 %c) {
entry:
  %a = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  store i32 %c, ptr %a
  %b = icmp sgt i32 %x, %k
  br i1 %b, label %then, label %join
then:
  %y = add i32 %x, 1
  store i32 %y, ptr %a
  %l = load i32, ptr %a
  br label %join
join:
  %m = phi i32 [ %l, %then ], [ 0, %entry ]
  %r = call i32 @cq_measure_si32(i32 %m)
  ret i32 %r
}
; CHECK guarded_store: %{{s}} = call i32 @cqrt_alloc_i32(i32 %{{c}})
; CHECK guarded_store: %{{f}} = call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{x}}, i32 %{{k}})
; CHECK guarded_store: %{{v}} = call i32 @cq_template_select_i32(i32 %{{f}}, i32 %{{y}}, i32 %{{s}})
; CHECK guarded_store: store i32 %{{v}}, ptr %{{a}}, align 4
; CHECK-COUNT guarded_store: load i32 0
