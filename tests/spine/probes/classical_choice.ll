; cq-74ok, rule 9 at a58c3a4: a select on a classical condition over quantum arms, and a phi whose
; every incoming edge predicate is classical, choose a handle classically: a classical select/phi over
; the handles, no gate (pred's lowerSelect/lowerMerge, routed by the spine). The phi's arms dominate
; the join (a phi over arm-local handles is cq-ut4k). x is measured at the end (cq-5nj9): with x dead, the
; chosen update would make x a rule 6 old value dead on one path only, a clean-up under a classical branch
; that is not built (fatal/rule6_classical_merge.ll, fatal/rule6_classical_select.ll).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @sel_handles(i32 %x0, double %t, i1 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %a = add i32 %x, 1
  %b = mul i32 %x, 3
  %s = select i1 %c, i32 %a, i32 %b
  %u = add i32 %s, 5
  %r = call i32 @cq_measure_si32(i32 %u)
  %mx = call i32 @cq_measure_si32(i32 %x)
  %rx = add i32 %r, %mx
  ret i32 %rx
}
; CHECK sel_handles: select i1 %{{c}}, i32 %{{a}}, i32 %{{b}}
; CHECK-COUNT sel_handles: _controlled 0
; CHECK-COUNT sel_handles: @cq_template_mux 0

define i32 @phi_handles(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %y = add i32 %x, 7
  %c = icmp sgt i32 %n, 0
  br i1 %c, label %then, label %join
then:
  br label %join
join:
  %p = phi i32 [ %x, %entry ], [ %y, %then ]
  %u = add i32 %p, 5
  %r = call i32 @cq_measure_si32(i32 %u)
  %mx = call i32 @cq_measure_si32(i32 %x)
  %rx = add i32 %r, %mx
  ret i32 %rx
}
; CHECK phi_handles: phi i32 [ %{{x}}, %{{entry}} ], [ %{{y}}, %{{then}} ]
; CHECK-COUNT phi_handles: _controlled 0
; CHECK-COUNT phi_handles: @cq_template_mux 0
