; cq-xb7r: a pointer phi at a quantum join over two objects is a fat-pointer merge (rule 21), not
; built in fatptr yet (cq-8zqm); the spine hands it to fatptr::lower like a select (cq-29ej).
; FATAL: cq: unimplemented: fatptr: a phi of fat pointers (rule 21 merge over edge predicates)
declare i8 @cq_theta_ui8(i8, double)
declare i1 @cq_measure_ui1(i1)

define i1 @join(i8 %x0, double %th) {
entry:
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  %x = call i8 @cq_theta_ui8(i8 %x0, double %th)
  %c = icmp ult i8 %x, 3
  br i1 %c, label %t, label %j
t:
  br label %j
j:
  %p = phi ptr [ %a, %t ], [ %b, %entry ]
  %e = icmp eq ptr %p, %a
  %r = call i1 @cq_measure_ui1(i1 %e)
  ret i1 %r
}
