; ModuleID = 'views.c'
source_filename = "views.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = internal unnamed_addr global i32 0, align 4
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define double @p_view_hi(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %5 = bitcast double %4 to i64
  %6 = lshr i64 %5, 32
  %7 = trunc nuw i64 %6 to i32
  %8 = xor i32 %7, %2
  %9 = zext i32 %8 to i64
  %10 = shl nuw i64 %9, 32
  %11 = and i64 %5, 4294967295
  %12 = or disjoint i64 %10, %11
  %13 = bitcast i64 %12 to double
  %14 = tail call double @cq_measure_f64(double noundef %13) #6
  ret double %14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_atomic_or(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 %5, ptr %4, align 4, !tbaa !6
  %6 = atomicrmw or ptr %4, i32 %2 seq_cst, align 4
  %7 = call i32 @cq_measure_si32(i32 noundef %6) #6
  %8 = load atomic i32, ptr %4 seq_cst, align 4
  %9 = call i32 @cq_measure_si32(i32 noundef %8) #6
  %10 = add nsw i32 %9, %7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @p_global_call(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %4 = add nsw i32 %3, 1
  store i32 %4, ptr @g, align 4, !tbaa !6
  %5 = tail call fastcc i32 @other(i32 noundef %3)
  %6 = load i32, ptr @g, align 4, !tbaa !6
  %7 = add nsw i32 %6, %5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #6
  ret i32 %8
}

; Function Attrs: nofree noinline nounwind ssp uwtable
define internal fastcc i32 @other(i32 noundef %0) unnamed_addr #3 {
  %2 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %0)
  %3 = mul nsw i32 %0, 3
  ret i32 %3
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
; CHECK p_view_hi: call i32 @cq_template_lshr_i64_hl(i32 %{{v}}, i64 32)
; CHECK p_view_hi: call i32 @cq_template_and_i64_hl(i32 %{{v}}, i64 4294967295)
; CHECK p_view_hi: call i32 @cq_template_bitcast_i64_to_f64(i32 %{{n}})
; CHECK-COUNT p_view_hi: store i32 0
; CHECK p_atomic_or: call i32 @cq_template_or_i32_hl(i32 %{{x}}, i32 %2)
; CHECK p_global_call: store i32 %{{h}}, ptr @g, align 4
; CHECK-COUNT p_global_call: load i32, ptr @g 0
