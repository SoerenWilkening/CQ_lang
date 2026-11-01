; ModuleID = 'm1.O1.ll'
source_filename = "m1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @m1(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = alloca [2 x ptr], align 8
  %9 = alloca i32, i64 1, align 4
  %10 = alloca i32, i64 1, align 4
  %11 = call i32 @cqrt_alloc_i32(i32 %3)
  store i32 %11, ptr %9, align 4
  call void @cqrt_free(i32 %11)
  %12 = call i32 @cqrt_alloc_i32(i32 %5)
  store i32 %12, ptr %10, align 4
  call void @cqrt_free(i32 %12)
  %13 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %13, double %1)
  %14 = call i32 @cqrt_alloc_i32(i32 %3)
  call void @cqrt_ry_i32(i32 %14, double %4)
  %15 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %14, i32 %15)
  store i32 %15, ptr %9, align 4
  %16 = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %16, double %6)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %16, i32 %17)
  store i32 %17, ptr %10, align 4
  %18 = call i32 @cq_template_mul_i32_hl(i32 %14, i32 5)
  %19 = call i32 @cq_template_add_i32(i32 %16, i32 %18)
  %20 = call i32 @cq_template_sub_i32(i32 %19, i32 %16)
  call void @cqrt_copy_i32(i32 %20, i32 %18)
  call void @cq_template_sub_i32_unc(i32 %20, i32 %19, i32 %16)
  call void @cqrt_free(i32 %20)
  call void @cqrt_free(i32 %18)
  %21 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %13, i32 %2)
  %22 = call i32 @cq_template_select_i32_ll(i32 %21, i32 1, i32 2)
  %23 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 2)
  %24 = call i32 @cq_template_select_i32(i32 %23, i32 %17, i32 %15)
  %25 = call i32 @cq_template_add_i32_hl(i32 %24, i32 7)
  %26 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 1)
  %27 = call i32 @cq_template_select_i32(i32 %26, i32 %25, i32 %15)
  store i32 %27, ptr %9, align 4
  %28 = call i32 @cq_template_add_i32_hl(i32 %27, i32 -7)
  %29 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 2)
  %30 = call i32 @cq_template_select_i32(i32 %29, i32 %25, i32 %17)
  call void @cq_template_add_i32_hl_unc(i32 %25, i32 %24, i32 7)
  call void @cqrt_free(i32 %25)
  store i32 %30, ptr %10, align 4
  %31 = call i32 @cq_template_add_i32_hl(i32 %30, i32 -7)
  store ptr %9, ptr %8, align 8
  %32 = getelementptr inbounds ptr, ptr %8, i64 1
  store ptr %10, ptr %32, align 8
  call fastcc void @__cq_q_bump_1011(ptr %8, i32 %22, i32 0, i32 1)
  %33 = load i32, ptr %9, align 4
  %34 = load i32, ptr %10, align 4
  %35 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 1)
  %36 = call i32 @cq_template_add_i32_hl(i32 %33, i32 -1)
  %37 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 2)
  %38 = call i32 @cq_template_add_i32_hl(i32 %34, i32 -1)
  %39 = call i32 @cq_template_mul_i32_hl(i32 %24, i32 3)
  %40 = call i32 @cq_template_add_i32(i32 %19, i32 %39)
  %41 = call i32 @cq_template_sub_i32(i32 %40, i32 %39)
  call void @cqrt_copy_i32(i32 %41, i32 %19)
  call void @cq_template_sub_i32_unc(i32 %41, i32 %40, i32 %39)
  call void @cqrt_free(i32 %41)
  call void @cqrt_free(i32 %19)
  call void @cq_template_mul_i32_hl_unc(i32 %39, i32 %24, i32 3)
  call void @cqrt_free(i32 %39)
  call void @cq_template_select_i32_unc(i32 %24, i32 %23, i32 %17, i32 %15)
  call void @cqrt_free(i32 %24)
  %42 = call i32 @cq_template_select_i32(i32 %29, i32 %31, i32 %30)
  call void @cqrt_copy_i32(i32 %42, i32 %17)
  call void @cq_template_select_i32_unc(i32 %42, i32 %29, i32 %31, i32 %30)
  call void @cqrt_free(i32 %42)
  call void @cqrt_free(i32 %17)
  call void @cq_template_add_i32_hl_unc(i32 %31, i32 %30, i32 -7)
  call void @cqrt_free(i32 %31)
  %43 = call i32 @cq_template_select_i32(i32 %37, i32 %38, i32 %34)
  call void @cqrt_copy_i32(i32 %43, i32 %30)
  call void @cq_template_select_i32_unc(i32 %43, i32 %37, i32 %38, i32 %34)
  call void @cqrt_free(i32 %43)
  call void @cqrt_free(i32 %30)
  call void @cq_template_add_i32_hl_unc(i32 %38, i32 %34, i32 -1)
  call void @cqrt_free(i32 %38)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %37, i32 %22, i32 2)
  call void @cqrt_free(i32 %37)
  %44 = call i32 @cq_template_select_i32(i32 %26, i32 %28, i32 %27)
  call void @cqrt_copy_i32(i32 %44, i32 %15)
  call void @cq_template_select_i32_unc(i32 %44, i32 %26, i32 %28, i32 %27)
  call void @cqrt_free(i32 %44)
  call void @cqrt_free(i32 %15)
  call void @cq_template_add_i32_hl_unc(i32 %28, i32 %27, i32 -7)
  call void @cqrt_free(i32 %28)
  %45 = call i32 @cq_template_select_i32(i32 %35, i32 %36, i32 %33)
  call void @cqrt_copy_i32(i32 %45, i32 %27)
  call void @cq_template_select_i32_unc(i32 %45, i32 %35, i32 %36, i32 %33)
  call void @cqrt_free(i32 %45)
  call void @cqrt_free(i32 %27)
  call void @cq_template_add_i32_hl_unc(i32 %36, i32 %33, i32 -1)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %35, i32 %22, i32 1)
  call void @cqrt_free(i32 %35)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %29, i32 %22, i32 2)
  call void @cqrt_free(i32 %29)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %23, i32 %22, i32 2)
  call void @cqrt_free(i32 %23)
  call void @cq_template_select_i32_ll_unc(i32 %22, i32 %21, i32 1, i32 2)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %21, i32 %13, i32 %2)
  call void @cqrt_free(i32 %21)
  %46 = call i32 @cqrt_measure_i32(i32 %33), !cq.measure !6
  %47 = call i32 @cqrt_measure_i32(i32 %34), !cq.measure !6
  %48 = add nsw i32 %47, %46
  %49 = call i32 @cqrt_measure_i32(i32 %40), !cq.measure !6
  %50 = add nsw i32 %48, %49
  ret i32 %50
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

define internal fastcc void @__cq_q_bump_1011(ptr %0, i32 %1, i32 %2, i32 %3) {
  %5 = load ptr, ptr %0, align 8
  %6 = getelementptr inbounds ptr, ptr %0, i64 1
  %7 = load ptr, ptr %6, align 8
  %8 = zext i32 %2 to i64
  %9 = getelementptr inbounds i32, ptr %5, i64 %8
  %10 = load i32, ptr %9, align 4
  %11 = getelementptr inbounds i32, ptr %7, i64 %8
  %12 = load i32, ptr %11, align 4
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 1)
  %14 = call i32 @cq_template_select_i32(i32 %13, i32 %10, i32 %12)
  %15 = call i32 @cq_template_add_i32_hl(i32 %14, i32 1)
  %16 = getelementptr inbounds i32, ptr %5, i64 %8
  %17 = load i32, ptr %16, align 4
  %18 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 1)
  %19 = call i32 @cq_template_select_i32(i32 %18, i32 %15, i32 %17)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %18, i32 %1, i32 1)
  call void @cqrt_free(i32 %18)
  store i32 %19, ptr %16, align 4
  %20 = getelementptr inbounds i32, ptr %7, i64 %8
  %21 = load i32, ptr %20, align 4
  %22 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 2)
  %23 = call i32 @cq_template_select_i32(i32 %22, i32 %15, i32 %21)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %22, i32 %1, i32 2)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i32_hl_unc(i32 %15, i32 %14, i32 1)
  call void @cqrt_free(i32 %15)
  call void @cq_template_select_i32_unc(i32 %14, i32 %13, i32 %10, i32 %12)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %1, i32 1)
  call void @cqrt_free(i32 %13)
  store i32 %23, ptr %20, align 4
  ret void
}

declare i32 @cqrt_measure_i32(i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

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
