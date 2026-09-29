; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295/ir-pass/test/spec_accept_musttail_in_clone_demoted_inalloca.ll'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295/ir-pass/test/spec_accept_musttail_in_clone_demoted_inalloca.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr)

; Function Attrs: noinline
define i32 @h2(i32 %x, ptr inalloca(i32) %s) #0 {
  %r = add i32 %x, 1
  ret i32 %r
}

; Function Attrs: noinline
define i32 @h(i32 %a, ptr inalloca(i32) %s) #0 {
  %r = musttail call i32 @h2(i32 %a, ptr inalloca(i32) %s)
  ret i32 %r
}

define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %sp = load ptr, ptr %g, align 8
  %m = call i32 @atoi(ptr %sp)
  %a = and i32 %m, 7
  %h = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %p = alloca inalloca i32, align 4
  store i32 3, ptr %p, align 4
  %r = call i32 @__cq_q_h_01(i32 %h, ptr inalloca(i32) %p)
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_h_01(i32 %a, ptr inalloca(i32) %s) #1 {
  %r = call i32 @__cq_q_h2_01(i32 %a, ptr inalloca(i32) %s)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %r, i32 %cqq.out)
  call void @__cq_q_h2_01_unc(i32 %r, i32 %a, ptr %s)
  call void @cqrt_free(i32 %r)
  ret i32 %cqq.out
}

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_h2_01(i32 %x, ptr inalloca(i32) %s) #1 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %x, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: noinline memory(readwrite)
define internal void @__cq_q_h2_01_unc(i32 %out, i32 %x, ptr inalloca(i32) %s) #1 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %x, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { noinline }
attributes #1 = { noinline memory(readwrite) }
