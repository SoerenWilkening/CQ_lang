; ModuleID = 'W13_round2_clone.s1.ll'
source_filename = "W13_round2_clone.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %1 = tail call fastcc i32 @f(i32 noundef 4) #4
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp2 = call i32 @cq_template_icmp_eq_i32_hl(i32 %out, i32 13)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  %selop4 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  %selop5 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %selop5, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp2, i32 %out, i32 13)
  call void @cqrt_free(i32 %h_cmp2)
  %h_cmp6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %out, i32 13)
  %out7 = call i32 @cqrt_alloc_i32(i32 0)
  %selop8 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp6, i32 %selop8, i32 %out7)
  call void @cqrt_x(i32 %h_cmp6)
  %selop9 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp6, i32 %selop9, i32 %out7)
  call void @cqrt_x(i32 %h_cmp6)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp6, i32 %out, i32 13)
  call void @cqrt_free(i32 %h_cmp6)
  %2 = tail call fastcc i32 @__cq_q_helper_1(i32 noundef %out7)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m10 = call i32 @cqrt_measure_i32(i32 %out)
  %3 = add nsw i32 %m10, %m
  %m11 = call i32 @cqrt_measure_i32(i32 %out3)
  %4 = add nsw i32 %3, %m11
  %m12 = call i32 @cqrt_measure_i32(i32 %2)
  %5 = add nsw i32 %4, %m12
  ret i32 %5
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 2, 4) i32 @helper(i32 noundef %0) unnamed_addr #2 {
  %2 = add nuw nsw i32 %0, 1
  ret i32 %2
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_helper_1(i32 noundef %0) unnamed_addr #3 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %0, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
