; ModuleID = 'bus_byte_view.c'
source_filename = "bus_byte_view.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @bus_byte_view(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i8 noundef zeroext %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4    ; C: unsigned w
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&k, tk);
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #3    ; C: cq_theta(&x, tx);
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #4    ; C: (w comes into scope)
  store i32 %8, ptr %6, align 4, !tbaa !6    ; C: unsigned w = x;
  %9 = and i32 %7, 3    ; C: k & 3
  %10 = zext nneg i32 %9 to i64    ; C: (index)
  %11 = getelementptr inbounds i8, ptr %6, i64 %10    ; C: &b[k & 3]
  %12 = load i8, ptr %11, align 1, !tbaa !10    ; C: unsigned char lo = b[k & 3];
  %13 = lshr i32 %7, 2    ; C: k >> 2
  %14 = and i32 %13, 3    ; C: (k >> 2) & 3
  %15 = zext nneg i32 %14 to i64    ; C: (index)
  %16 = getelementptr inbounds i8, ptr %6, i64 %15    ; C: &b[(k >> 2) & 3]
  store i8 %4, ptr %16, align 1, !tbaa !10    ; C: b[(k >> 2) & 3] = c;
  %17 = load i32, ptr %6, align 4, !tbaa !6    ; C: w
  %18 = zext i8 %12 to i32    ; C: (lo promoted to unsigned)
  %19 = add i32 %17, %18    ; C: w + lo
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #4    ; C: cq_measure(w + lo)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4    ; C: (w goes out of scope)
  ret i32 %20    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
