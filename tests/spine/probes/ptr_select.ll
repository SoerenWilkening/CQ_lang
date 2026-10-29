; cq-xb7r, rule 21: a select of pointers on a quantum condition between two objects has a quantum
; tag; the spine hands it to fatptr::lower at the select (never pred's lowerSelect), which binds its
; (tag, idx) fields; the compare reads them.
declare i8 @cq_theta_ui8(i8, double)
declare i1 @cq_measure_ui1(i1)

define i1 @pick(i8 %x0, double %th) {
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  %x = call i8 @cq_theta_ui8(i8 %x0, double %th)
  %c = icmp ult i8 %x, 3
  %p = select i1 %c, ptr %a, ptr %b
  %e = icmp eq ptr %p, %a
  %r = call i1 @cq_measure_ui1(i1 %e)
  ret i1 %r
}
; CHECK-COUNT pick: call i32 @cq_template_select_i32_ll( 1
; CHECK-COUNT pick: call i32 @cq_template_icmp_eq_i32_hl( 1
