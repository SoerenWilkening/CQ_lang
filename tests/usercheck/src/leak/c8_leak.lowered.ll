; ModuleID = '<stdin>'
source_filename = "/Users/sorenwilkening/Desktop/Projects/wt/rev/w2a-slots3-n1/p/c8.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @c8(i64 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, i64 1, align 8
  %4 = call i32 @cqrt_alloc_i64(i64 %0)
  call void @cqrt_ry_i64(i32 %4, double %1)
  call fastcc void @__cq_q_g_10(i32 %4, ptr %3)
  %5 = load i32, ptr %3, align 4
  %6 = call i32 @cq_template_bitcast_i64_to_f64(i32 %5)
  %7 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %6, double 1.000000e+00)
  %8 = call i32 @cq_template_zext_i1_to_i32(i32 %7)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %7, i32 %6, double 1.000000e+00)
  call void @cqrt_free(i32 %7)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %6, i32 %5)
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cqrt_measure_i32(i32 %8), !cq.measure !6
  %10 = add nsw i32 %9, 1
  %11 = call i64 @cqrt_measure_i64(i32 %4), !cq.measure !6
  %12 = trunc i64 %11 to i32
  %13 = add nsw i32 %10, %12
  ret i32 %13
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_i64(i32, double)

define internal fastcc void @__cq_q_g_10(i32 %0, ptr %1) {
  %3 = call i32 @cq_template_add_i64_hl(i32 %0, i64 3)
  %4 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %3, i32 %4)
  call void @cq_template_add_i64_hl_unc(i32 %3, i32 %0, i64 3)
  call void @cqrt_free(i32 %3)
  store i32 %4, ptr %1, align 4
  ret void
}

declare i32 @cq_template_bitcast_i64_to_f64(i32)

declare i32 @cq_template_fcmp_ogt_f64_hl(i32, double)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare i64 @cqrt_measure_i64(i32)

declare void @cq_template_fcmp_ogt_f64_hl_unc(i32, i32, double)

declare void @cqrt_free(i32)

declare void @cq_template_bitcast_i64_to_f64_unc(i32, i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_copy_i64(i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
