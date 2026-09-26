; ModuleID = 'k74.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %arr = call i32 @cqrt_qram_alloc_i32(i32 8)
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %h = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h2 = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01)
  %9 = tail call i32 @__cq_q_k2_10(i32 noundef %5, i32 noundef %h) #6
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h2, i32 7)
  %qval = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_qram_store_i32(i32 %arr, i32 %h_op, i32 %qval)
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h, i32 7)
  %qval1 = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_qram_store_i32(i32 %arr, i32 %h_op3, i32 %qval1)
  %h_op4 = call i32 @cq_template_add_i32_hl(i32 %h2, i32 1)
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op4, i32 7)
  %10 = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %h_op5)
  call void @cq_template_and_i32_hl_unc(i32 %h_op5, i32 %h_op4, i32 7)
  call void @cqrt_free(i32 %h_op5)
  call void @cq_template_add_i32_hl_unc(i32 %h_op4, i32 %h2, i32 1)
  call void @cqrt_free(i32 %h_op4)
  %m = call i32 @cqrt_measure_i32(i32 %10)
  %11 = tail call i32 @__cq_q_k1_10(i32 noundef %8, i32 noundef %h2) #6
  %12 = add nsw i32 %m, %9
  %13 = add nsw i32 %12, %11
  %m6 = call i32 @cqrt_measure_i32(i32 %h2)
  %14 = add nsw i32 %13, %m6
  %m7 = call i32 @cqrt_measure_i32(i32 %h)
  %15 = add nsw i32 %14, %m7
  ret i32 %15
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @k1(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = mul nsw i32 %0, 7
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @k2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = mul i32 %0, 7
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 4, 0) i32 @k3(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = and i32 %0, -5
  %4 = xor i32 %3, 95
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483635, -2147483648) i32 @k4(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %0, 13
  ret i32 %3
}

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cqrt_qram_alloc_i32(i32)

declare i32 @cqrt_qram_load_i32(i32, i32)

declare void @cqrt_qram_store_i32(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

; Function Attrs: mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal noundef i32 @__cq_q_k2_10(i32 noundef %0, i32 noundef %1) local_unnamed_addr #5 {
  %3 = mul i32 %0, 7
  ret i32 %3
}

declare void @cqrt_free(i32)

; Function Attrs: mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_k1_10(i32 noundef %0, i32 noundef %1) local_unnamed_addr #5 {
  %3 = mul nsw i32 %0, 7
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
