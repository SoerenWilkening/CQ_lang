; ModuleID = 'tests/eff-conc/probes/inplace_forms.c'
source_filename = "tests/eff-conc/probes/inplace_forms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g1 = local_unnamed_addr global i32 11, align 4
@g2 = local_unnamed_addr global i32 22, align 4
@g3 = global [2 x i32] [i32 3, i32 4], align 4
@b1 = local_unnamed_addr global i8 1, align 1
@b2 = local_unnamed_addr global i8 0, align 1
@dcell = local_unnamed_addr global double 1.500000e+00, align 8
@hw = local_unnamed_addr global i16 4660, align 2

; Function Attrs: nounwind ssp uwtable
define i32 @f_add_cells(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store i32 %4, ptr @g3, align 4, !tbaa !6
  %5 = icmp eq i32 %2, 0
  %6 = select i1 %5, ptr getelementptr inbounds (i8, ptr @g3, i64 4), ptr @g3
  tail call fastcc void @add_cells(ptr noundef nonnull %6)
  %7 = load i32, ptr @g3, align 4, !tbaa !6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #7
  %9 = load i32, ptr getelementptr inbounds (i8, ptr @g3, i64 4), align 4, !tbaa !6
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: read, inaccessiblemem: none) uwtable
define internal fastcc void @add_cells(ptr nocapture noundef readonly %0) unnamed_addr #2 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = load i32, ptr @g3, align 4, !tbaa !6
  %4 = add nsw i32 %3, %2
  store i32 %4, ptr @g3, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f_old(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = load i32, ptr @g1, align 4, !tbaa !6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %1) #6
  %5 = add nsw i32 %4, %0
  store i32 %5, ptr @g1, align 4, !tbaa !6
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  %7 = mul nsw i32 %6, 1000
  %8 = load i32, ptr @g1, align 4, !tbaa !6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #7
  %10 = add nsw i32 %9, %7
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_new(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = load i32, ptr @g2, align 4, !tbaa !6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %1) #6
  %5 = xor i32 %4, %0
  store i32 %5, ptr @g2, align 4, !tbaa !6
  store i32 %5, ptr getelementptr inbounds (i8, ptr @g3, i64 4), align 4, !tbaa !6
  %6 = add nsw i32 %5, 1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #7
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_chain(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = load i32, ptr @g1, align 4, !tbaa !6
  %4 = xor i32 %3, %0
  %5 = mul nsw i32 %4, 3
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %1) #6
  %7 = add i32 %6, -6
  %8 = tail call i32 @llvm.bswap.i32(i32 %7)
  %9 = tail call i32 @llvm.fshl.i32(i32 %8, i32 %8, i32 7)
  store i32 %9, ptr @g1, align 4, !tbaa !6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.bswap.i32(i32) #3

; Function Attrs: nounwind ssp uwtable
define i32 @f_ends(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = load i32, ptr @g2, align 4, !tbaa !6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %1) #6
  %5 = add nsw i32 %4, %0
  store i32 %5, ptr @g2, align 4, !tbaa !6
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  %7 = mul nsw i32 %6, 3
  %8 = load i32, ptr @g2, align 4, !tbaa !6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #7
  %10 = add nsw i32 %9, %7
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_under(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %6 = icmp sgt i32 %5, 2
  br i1 %6, label %7, label %12

7:                                                ; preds = %4
  %8 = load i32, ptr @g1, align 4, !tbaa !6
  %9 = add nsw i32 %8, %3
  store i32 %9, ptr @g1, align 4, !tbaa !6
  %10 = load i32, ptr @g2, align 4, !tbaa !6
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef %2) #6
  store i32 %11, ptr @g2, align 4, !tbaa !6
  br label %12

12:                                               ; preds = %7, %4
  %13 = load i32, ptr @g1, align 4, !tbaa !6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #7
  %15 = load i32, ptr @g2, align 4, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #7
  %17 = shl nsw i32 %16, 1
  %18 = add nsw i32 %17, %14
  %19 = tail call i32 @cq_measure_si32(i32 noundef %5) #7
  %20 = shl nsw i32 %19, 2
  %21 = add nsw i32 %18, %20
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_select(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %6 = load i32, ptr @g1, align 4, !tbaa !6
  %7 = icmp sgt i32 %5, 2
  %8 = select i1 %7, i32 %3, i32 0
  %9 = add nsw i32 %8, %6
  store i32 %9, ptr @g1, align 4, !tbaa !6
  %10 = load i32, ptr @g2, align 4, !tbaa !6
  %11 = icmp eq i32 %2, 0
  %12 = select i1 %11, i32 -1, i32 1
  %13 = add nsw i32 %10, %12
  store i32 %13, ptr @g2, align 4, !tbaa !6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  %15 = load i32, ptr @g2, align 4, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #7
  %17 = add nsw i32 %16, %14
  %18 = tail call i32 @cq_measure_si32(i32 noundef %5) #7
  %19 = add nsw i32 %17, %18
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @f_bool(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = load i8, ptr @b1, align 1, !tbaa !10, !range !12, !noundef !13
  %4 = trunc nuw i8 %3 to i1
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef %0) #6
  %6 = zext i1 %5 to i8
  store i8 %6, ptr @b1, align 1, !tbaa !10
  %7 = load i8, ptr @b2, align 1, !tbaa !10, !range !12, !noundef !13
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef %1) #6
  %10 = zext i1 %9 to i8
  store i8 %10, ptr @b2, align 1, !tbaa !10
  %11 = load i8, ptr @b1, align 1, !tbaa !10, !range !12, !noundef !13
  %12 = icmp ne i8 %11, %10
  %13 = zext i1 %12 to i8
  store i8 %13, ptr @b1, align 1, !tbaa !10
  %14 = xor i1 %9, true
  %15 = zext i1 %14 to i8
  store i8 %15, ptr @b2, align 1, !tbaa !10
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12) #7
  %17 = zext i1 %16 to i32
  %18 = load i8, ptr @b2, align 1, !tbaa !10, !range !12, !noundef !13
  %19 = trunc nuw i8 %18 to i1
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %19) #7
  %21 = select i1 %20, i32 2, i32 0
  %22 = or disjoint i32 %21, %17
  ret i32 %22
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @f_fneg(double noundef %0) local_unnamed_addr #0 {
  %2 = load double, ptr @dcell, align 8, !tbaa !14
  %3 = fneg double %2
  store double %3, ptr @dcell, align 8, !tbaa !14
  %4 = load i16, ptr @hw, align 2, !tbaa !16
  %5 = tail call zeroext i16 @cq_theta_ui16(i16 noundef zeroext %4, double noundef %0) #6
  %6 = xor i16 %5, 5
  store i16 %6, ptr @hw, align 2, !tbaa !16
  %7 = load double, ptr @dcell, align 8, !tbaa !14
  %8 = tail call double @cq_measure_f64(double noundef %7) #7
  %9 = load i16, ptr @hw, align 2, !tbaa !16
  %10 = tail call zeroext i16 @cq_measure_ui16(i16 noundef zeroext %9) #7
  %11 = uitofp i16 %10 to double
  %12 = fadd double %8, %11
  ret double %12
}

declare zeroext i16 @cq_theta_ui16(i16 noundef zeroext, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

declare zeroext i16 @cq_measure_ui16(i16 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f_fwd(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %5 = tail call fastcc i32 @fwd(i32 noundef %4, double noundef %2)
  %6 = load i32, ptr @g3, align 4, !tbaa !6
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #7
  %8 = add nsw i32 %7, %5
  %9 = load i32, ptr getelementptr inbounds (i8, ptr @g3, i64 4), align 4, !tbaa !6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  %11 = add nsw i32 %8, %10
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @fwd(i32 noundef %0, double noundef %1) unnamed_addr #4 {
  store i32 %0, ptr @g3, align 4, !tbaa !6
  %3 = add nsw i32 %0, 1
  store i32 %3, ptr getelementptr inbounds (i8, ptr @g3, i64 4), align 4, !tbaa !6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store i32 %4, ptr @g3, align 4, !tbaa !6
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  ret i32 %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"_Bool", !8, i64 0}
!12 = !{i8 0, i8 2}
!13 = !{}
!14 = !{!15, !15, i64 0}
!15 = !{!"double", !8, i64 0}
!16 = !{!17, !17, i64 0}
!17 = !{!"short", !8, i64 0}
