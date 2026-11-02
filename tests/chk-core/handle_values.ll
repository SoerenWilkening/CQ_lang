; cq-06bi: handles are classical values of the host program (CR §1.1, CQ_spec f684858): compared,
; selected, stored, and 0 meaning "no rail" on a path that has none (rule 19's extra results)
target triple = "x86_64-apple-macosx16.0.0"
define internal i32 @mint(i1 %c, i32 %x0) {
  br i1 %c, label %m, label %n
m:
  %h = call i32 @cqrt_alloc_i32(i32 %x0)
  ret i32 %h
n:
  ret i32 0
}
define i32 @v(i32 %x0, double %th) {
  %a = call i32 @cqrt_alloc_i32(i32 %x0)
  %b = call i32 @cqrt_alloc_i32(i32 7)
  %ne = icmp ne i32 %a, %b
  %pick = select i1 %ne, i32 %b, i32 %a
  %slot = alloca i32
  store i32 %pick, ptr %slot
  %ld = load i32, ptr %slot
  %y = call i32 @cq_template_add_i32_hl(i32 %ld, i32 1)
  %odd = and i32 %x0, 1
  %c = icmp ne i32 %odd, 0
  %e = call i32 @mint(i1 %c, i32 %x0)
  %none = icmp eq i32 %e, 0
  br i1 %none, label %skip, label %rel
rel:
  call void @cqrt_free(i32 %e)
  br label %skip
skip:
  %m = call i32 @cqrt_measure_i32(i32 %y)
  %ma = call i32 @cqrt_measure_i32(i32 %a)
  call void @cqrt_free(i32 %b)
  %r = add i32 %m, %ma
  ret i32 %r
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
