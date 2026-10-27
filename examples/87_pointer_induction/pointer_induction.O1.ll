; ModuleID = 'pointer_induction.c'
source_filename = "pointer_induction.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @count_nonzero(i8 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 1    ; C: unsigned char s[4]
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3    ; C: cq_theta(&c, th);
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4    ; C: (s comes into scope)
  store i8 %4, ptr %3, align 1, !tbaa !6    ; C: s[0] = c;
  %5 = add i8 %4, 1    ; C: c + 1
  %6 = getelementptr inbounds i8, ptr %3, i64 1    ; C: &s[1]
  store i8 %5, ptr %6, align 1, !tbaa !6    ; C: s[1] = c + 1;
  %7 = xor i8 %4, 3    ; C: c ^ 3
  %8 = getelementptr inbounds i8, ptr %3, i64 2    ; C: &s[2]
  store i8 %7, ptr %8, align 1, !tbaa !6    ; C: s[2] = c ^ 3;
  %9 = getelementptr inbounds i8, ptr %3, i64 3    ; C: &s[3]
  store i8 0, ptr %9, align 1, !tbaa !6    ; C: s[3] = 0;
  %10 = load i8, ptr %3, align 1, !tbaa !6    ; C: *p  (p = s, first test)
  %11 = icmp eq i8 %10, 0    ; C: *p != 0 ?  (first test)
  br i1 %11, label %12, label %15    ; C: for (...; *p; ...)

12:                                               ; preds = %15, %2
  %13 = phi i32 [ 0, %2 ], [ %18, %15 ]    ; C: n  (0, or the last n++)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4    ; C: cq_measure(n)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4    ; C: (s goes out of scope)
  ret i32 %14    ; C: return

15:                                               ; preds = %2, %15
  %16 = phi ptr [ %19, %15 ], [ %3, %2 ]    ; C: p  (loop-carried pointer)
  %17 = phi i32 [ %18, %15 ], [ 0, %2 ]    ; C: n  (loop-carried)
  %18 = add nuw nsw i32 %17, 1    ; C: n++
  %19 = getelementptr inbounds i8, ptr %16, i64 1    ; C: p++
  %20 = load i8, ptr %19, align 1, !tbaa !6    ; C: *p
  %21 = icmp eq i8 %20, 0    ; C: *p != 0 ?
  br i1 %21, label %12, label %15, !llvm.loop !9    ; C: for (...; *p; ...)
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
