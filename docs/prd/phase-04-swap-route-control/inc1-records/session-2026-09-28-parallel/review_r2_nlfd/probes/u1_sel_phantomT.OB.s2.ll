; ModuleID = 'u1_sel_phantomT.ll'
source_filename = "u1_sel_phantomT.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)

define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p, align 8
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %h = call i32 @cqrt_alloc_i32(i32 %m7)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = add nsw i32 %m, 1
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m1 = call i32 @cqrt_measure_i32(i32 %h)
  %s = add nsw i32 %m1, %r
  ret i32 %s
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)
