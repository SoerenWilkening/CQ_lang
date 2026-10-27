; ModuleID = 'quantum_bitfield.c'
source_filename = "quantum_bitfield.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fields = type { i32 }

; Function Attrs: nounwind ssp uwtable
define i32 @quantum_bitfield(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %7 = and i32 %6, 7
  %8 = add i32 %7, %2
  %9 = and i32 %8, 31
  %10 = icmp ugt i32 %9, %3
  br i1 %10, label %11, label %12

11:                                               ; preds = %5
  tail call void @cq_phi(double noundef %4) #5
  br label %12

12:                                               ; preds = %11, %5
  %13 = shl i32 %8, 3
  %14 = and i32 %13, 248
  %15 = and i32 %6, -249
  %16 = or disjoint i32 %14, %15
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #5
  ret i32 %17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @bitfield_through_pointer(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.fields, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #5
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  store i32 %6, ptr %5, align 4
  call fastcc void @bump_c(ptr noundef nonnull %5, i32 noundef %2)
  %7 = load i32, ptr %5, align 4
  %8 = and i32 %7, 7
  %9 = icmp eq i32 %8, 5
  br i1 %9, label %10, label %11

10:                                               ; preds = %4
  tail call void @cq_phi(double noundef %3) #5
  br label %11

11:                                               ; preds = %10, %4
  %12 = lshr i32 %7, 8
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %12) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #5
  ret i32 %13
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump_c(ptr nocapture noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = load i32, ptr %0, align 4
  %4 = shl i32 %1, 8
  %5 = add i32 %3, %4
  store i32 %5, ptr %0, align 4
  ret void
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
