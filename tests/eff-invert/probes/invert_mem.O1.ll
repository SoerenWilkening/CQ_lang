; ModuleID = 'tests/eff-invert/probes/invert_mem.c'
source_filename = "tests/eff-invert/probes/invert_mem.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cell = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @p_store_flush(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  tail call void @__cq_invert_begin() #6
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !6
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  store i32 %5, ptr @cell, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %2) #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !7
  tail call void @__cq_invert_end() #6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #7
  %9 = load i32, ptr @cell, align 4
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #3

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_inplace_cell(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #7
  store i32 %0, ptr %5, align 4
  call fastcc void @fill(ptr noundef nonnull %5, i32 noundef %0)
  tail call void @__cq_invert_begin() #6
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !8
  %6 = load i32, ptr %5, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %1) #5
  store i32 %7, ptr %5, align 4
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %2) #5
  store i32 %8, ptr %5, align 4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !9
  tail call void @__cq_invert_end() #6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #7
  ret i32 %9
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @fill(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #4 {
  store i32 %1, ptr %0, align 4
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_load_inside(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  store i32 %5, ptr @cell, align 4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %2) #5
  tail call void @__cq_invert_begin() #6
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !10
  %7 = load i32, ptr @cell, align 4
  %8 = icmp sgt i32 %7, %3
  br i1 %8, label %9, label %10

9:                                                ; preds = %4
  tail call void @cq_phi(double noundef %2) #7
  br label %10

10:                                               ; preds = %4, %9
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !11
  tail call void @__cq_invert_end() #6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #7
  ret i32 %11
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @p_effect_flush(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  tail call void @__cq_invert_begin() #6
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !12
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %6 = icmp sgt i32 %4, 2
  br i1 %6, label %7, label %8

7:                                                ; preds = %3
  tail call void @sinkfx(i32 noundef %4) #7
  br label %8

8:                                                ; preds = %7, %3
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %2) #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !13
  tail call void @__cq_invert_end() #6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  ret i32 %10
}

declare void @sinkfx(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { noduplicate nounwind }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147512066}
!7 = !{i64 2147514150}
!8 = !{i64 2147515004}
!9 = !{i64 2147517082}
!10 = !{i64 2147519966}
!11 = !{i64 2147520022}
!12 = !{i64 2147521890}
!13 = !{i64 2147523974}
