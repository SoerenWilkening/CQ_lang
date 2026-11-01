; ModuleID = 'tests/mem-slots/probes/view_pieces.c'
source_filename = "tests/mem-slots/probes/view_pieces.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 65536) i32 @view_pieces(x86_fp80 noundef %0, double noundef %1, i16 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = alloca [12 x i8], align 16
  %5 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %4)
  %6 = getelementptr inbounds i8, ptr %4, i64 10
  store i16 %2, ptr %6, align 2, !tbaa !6
  store x86_fp80 %5, ptr %4, align 16, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %4, i64 8
  %8 = load i32, ptr %7, align 8, !tbaa !6
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #4
  %10 = lshr i32 %9, 16
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %4)
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
; CHECK view_pieces: call i32 @cq_template_lshr_i80_hl(i32 %{{a}}, i80 64)
; CHECK view_pieces: call i32 @cq_template_zext_i16_to_i32(i32 %{{k}})
; CHECK view_pieces: call i32 @cq_template_shl_i32_hl(i32 %{{b}}, i32 16)
; CHECK view_pieces: call i32 @cq_template_or_i32(i32 %{{c}}, i32 %{{d}})
