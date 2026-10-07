; p3kd.7.7: an untaken classical arm must not inject poison into a gate or a
; noundef scalar call. The single freeze is reused by both add and its adjoint.
; The source arm runs only for 0<d<1000. d=1e30 with that arm untaken is defined.
; RUN: %cq-opt -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define internal i32 @__cq_q_guarded_01(
; CHECK: %[[N:[a-zA-Z0-9_.]+]] = fptosi double %d to i32
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = freeze i32 %[[N]]
; CHECK: call i32 @scalar(i32 %[[F]])
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %q, i32 %[[F]])
; CHECK: call void @cq_template_add_i32_hl_unc(i32 %[[R]], i32 %q, i32 %[[F]])
; CHECK: ret i32

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @inner(i32 noundef %a) noinline {
  %r = add i32 %a, 1
  ret i32 %r
}
define noundef i32 @scalar(i32 %a) noinline {
  %r = call i32 @inner(i32 noundef %a)
  ret i32 %r
}
define i32 @guarded(i32 %q, double noundef %d) noinline {
entry:
  %qc = icmp sgt i32 %q, 0
  br i1 %qc, label %inner, label %merge
inner:
  %lo = fcmp ogt double %d, 0.0
  %hi = fcmp olt double %d, 1000.0
  %ck = and i1 %lo, %hi
  br i1 %ck, label %arm, label %merge
arm:
  %n = fptosi double %d to i32
  %c = call i32 @scalar(i32 %n)
  %r = add i32 %q, %n
  %s = add i32 %r, %c
  br label %merge
merge:
  %v = phi i32 [ %s, %arm ], [ %q, %inner ], [ 5, %entry ]
  ret i32 %v
}
define i32 @probe(i32 %seed, double noundef %d) {
  %q = call i32 @cq_theta_si32(i32 %seed, double 0.5)
  %r = call i32 @guarded(i32 %q, double %d)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
