; ModuleID = 'pb1_own_caller_prealloc.ll'
source_filename = "pb1_own_caller_prealloc.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr)

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare token @llvm.call.preallocated.setup(i32) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare ptr @llvm.call.preallocated.arg(token, i32) #0

; Function Attrs: noinline
define i32 @h(ptr preallocated(i32) %s, i32 %a) #1 {
  %r = add i32 %a, 1
  ret i32 %r
}

define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %sp = load ptr, ptr %g, align 8
  %m = call i32 @atoi(ptr %sp)
  %a = and i32 %m, 7
  %h = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %tok = call token @llvm.call.preallocated.setup(i32 1)
  %p = call ptr @llvm.call.preallocated.arg(token %tok, i32 0) #3
  store i32 3, ptr %p, align 4
  %r = call i32 @__cq_q_h_10(ptr preallocated(i32) %p, i32 %h) [ "preallocated"(token %tok) ]
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_h_10(ptr preallocated(i32) %s, i32 %a) #2 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %a, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nocallback nofree nosync nounwind willreturn }
attributes #1 = { noinline }
attributes #2 = { noinline memory(readwrite) }
attributes #3 = { preallocated(i32) }
