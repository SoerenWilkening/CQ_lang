; Host output test (cq-e4jk): a direct host-effect call (run.host_effects_module renames it to
; checker/rt/host_fx.c's logging wrapper) and printf to the process stdout.
target triple = "x86_64-apple-macosx16.0.0"
@.p = private constant [22 x i8] c"/nonexistent/cq_e4jk\0A\00"
@.f = private constant [7 x i8] c"v=%d\0A\00\00"
declare i32 @remove(ptr)
declare i32 @printf(ptr, ...)
define i32 @fx(i32 %x) {
  %r = call i32 @remove(ptr @.p)
  %p = call i32 (ptr, ...) @printf(ptr @.f, i32 %x)
  ret i32 %x
}
