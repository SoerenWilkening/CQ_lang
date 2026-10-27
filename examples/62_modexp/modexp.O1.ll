; ModuleID = '62_modexp/modexp.c'
source_filename = "62_modexp/modexp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @modexp(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&e, th);
  %7 = icmp sgt i32 %4, 0    ; C: nbits > 0
  br i1 %7, label %13, label %8    ; C: for (i = 0; i < nbits; i++)

8:                                                ; preds = %24, %5
  %9 = phi i32 [ 1, %5 ], [ %25, %24 ]    ; C: r (1 if the loop never ran)
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #3    ; C: cq_measure(r)
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %6) #3    ; C: cq_measure(e)
  %12 = add i32 %11, %10    ; C: m + cq_measure(e)
  ret i32 %12    ; C: return

13:                                               ; preds = %5, %24
  %14 = phi i32 [ %26, %24 ], [ %2, %5 ]    ; C: base (a before trip 0; % N applied below)
  %15 = phi i32 [ %27, %24 ], [ 0, %5 ]    ; C: i
  %16 = phi i32 [ %25, %24 ], [ 1, %5 ]    ; C: r
  %17 = urem i32 %14, %3    ; C: base % N  (-O1 merged the initial a % N with the loop's)
  %18 = shl nuw i32 1, %15    ; C: 1 << i  (-O1 rewrote (e >> i) & 1 as e & (1 << i))
  %19 = and i32 %18, %6    ; C: e & (1 << i)
  %20 = icmp eq i32 %19, 0    ; C: ((e >> i) & 1) == 0
  br i1 %20, label %24, label %21    ; C: if ((e >> i) & 1)

21:                                               ; preds = %13
  %22 = mul i32 %17, %16    ; C: r * base
  %23 = urem i32 %22, %3    ; C: (r * base) % N
  br label %24    ; C: end of if

24:                                               ; preds = %21, %13
  %25 = phi i32 [ %23, %21 ], [ %16, %13 ]    ; C: r (updated or kept)
  %26 = mul i32 %17, %17    ; C: base * base
  %27 = add nuw nsw i32 %15, 1    ; C: i++
  %28 = icmp eq i32 %27, %4    ; C: i < nbits
  br i1 %28, label %8, label %13, !llvm.loop !6    ; C: loop back / exit
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
