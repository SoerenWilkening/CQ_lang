; ModuleID = 'e2e/slice_control_cascade_two_bools_uncond.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_cascade_two_bools_uncond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %h4 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h4, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %out, i32 -3)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h4, i32 %bf2)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %h_op, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %out, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_cnot(i32 %h4, i32 %bf2)
  call void @cqrt_free(i32 %bf2)
  %m = call i1 @cqrt_measure_i1(i32 %h)
  %1 = zext i1 %m to i32
  %m5 = call i1 @cqrt_measure_i1(i32 %h4)
  %2 = zext i1 %m5 to i32
  %3 = add nuw nsw i32 %2, %1
  %m6 = call i32 @cqrt_measure_i32(i32 %out3)
  %4 = add nsw i32 %3, %m6
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %h4 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h4, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %out, i32 -3)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h4, i32 %bf2)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %h_op, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %out, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_cnot(i32 %h4, i32 %bf2)
  call void @cqrt_free(i32 %bf2)
  %m = call i1 @cqrt_measure_i1(i32 %h)
  %m5 = call i1 @cqrt_measure_i1(i32 %h4)
  %m6 = call i32 @cqrt_measure_i32(i32 %out3)
  ret i32 0
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
