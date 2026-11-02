; cq-06bi: the rule 27 clone registry (BACKEND_ABI §1.14, CQ_spec f684858): a module constructor
; registers f's clones; a call through a host pointer resolves them; an unregistered pointer resolves
; to null
target triple = "x86_64-apple-macosx16.0.0"
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @reg, ptr null }]
define internal void @reg() {
  call void @cqrt_clone_register(ptr @f, ptr @f_q, ptr @f_q_ctl, ptr @f_q_unc)
  ret void
}
define i32 @f(i32 %x) {
  %r = add i32 %x, 1
  ret i32 %r
}
define i32 @g(i32 %x) {
  ret i32 %x
}
define i32 @f_q(i32 %h) {
  %r = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
  ret i32 %r
}
define i32 @f_q_ctl(i32 %c, i32 %h) {
  ret i32 %h
}
define void @f_q_unc(i32 %o, i32 %h) {
  call void @cq_template_add_i32_hl_unc(i32 %o, i32 %h, i32 1)
  ret void
}
define i32 @v(i32 %x0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  %p = call ptr @cqrt_clone_resolve(ptr @f, i32 0)
  %y = call i32 %p(i32 %x)
  %pu = call ptr @cqrt_clone_resolve(ptr @f, i32 2)
  call void %pu(i32 %y, i32 %x)
  call void @cqrt_free(i32 %y)
  %pc = call ptr @cqrt_clone_resolve(ptr @f, i32 1)
  %okc = icmp eq ptr %pc, @f_q_ctl
  %pg = call ptr @cqrt_clone_resolve(ptr @g, i32 0)
  %okg = icmp eq ptr %pg, null
  %ok = and i1 %okc, %okg
  %m = call i32 @cqrt_measure_i32(i32 %x)
  %bonus = select i1 %ok, i32 1000, i32 0
  %r = add i32 %m, %bonus
  ret i32 %r
}
declare void @cqrt_clone_register(ptr, ptr, ptr, ptr)
declare ptr @cqrt_clone_resolve(ptr, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
