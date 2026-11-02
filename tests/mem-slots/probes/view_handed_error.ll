; cq-e5lj: a view object (63) handed to a clone: its cells hold no handles (the view's values are tracked in
; the function), so the clone's read was silently wrong on main; now the escape stop (not built: materialising
; the view's bytes into handle cells for the callee). From view_esc.c with the union alloca spelled [4 x i8].
; ModuleID = 'view_esc.c'
source_filename = "view_esc.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%union.anon = type { i32 }

; Function Attrs: nounwind ssp uwtable
define range(i32 -256, 255) i32 @view_esc(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  store i32 %4, ptr %3, align 4, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %3, i64 1
  %6 = load i8, ptr %5, align 1, !tbaa !6
  %7 = tail call signext i8 @cq_measure_c(i8 noundef signext %6) #4
  %8 = sext i8 %7 to i32
  %9 = call fastcc i32 @use(ptr noundef nonnull %3)
  %10 = add nsw i32 %9, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc range(i32 -128, 128) i32 @use(ptr nocapture noundef readonly %0) unnamed_addr #3 {
  %2 = load i8, ptr %0, align 1, !tbaa !6
  %3 = sext i8 %2 to i32
  ret i32 %3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
; EXPECT-ERROR: a bit view of a slot object whose pointer escapes or is handed to a call
