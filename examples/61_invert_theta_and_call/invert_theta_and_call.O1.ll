; ModuleID = '61_invert_theta_and_call/invert_theta_and_call.c'
source_filename = "61_invert_theta_and_call/invert_theta_and_call.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @invert_theta(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  tail call void @__cq_invert_begin() #6    ; C: cq_invert_begin();
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !6    ; C: (barrier of cq_invert_begin)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %2) #5    ; C: cq_theta(&x, t2);  (bracketed)
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !7    ; C: (barrier of cq_invert_end)
  tail call void @__cq_invert_end() #6    ; C: cq_invert_end();
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #7    ; C: cq_measure(x)
  ret i32 %6    ; C: return
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
define i32 @invert_call(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = alloca i32, align 4    ; C: unsigned x  (its address is taken)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #7
  store i32 %0, ptr %7, align 4, !tbaa !8    ; C: x = x0
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #5    ; C: cq_theta(&y, ty);
  call fastcc void @prep(ptr noundef nonnull %7, i32 noundef %8, double noundef %3, double noundef %4, i32 noundef %5)    ; C: prep(&x, y, t1, t2, k);
  tail call void @__cq_invert_begin() #6    ; C: cq_invert_begin();
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !12    ; C: (barrier)
  call fastcc void @prep(ptr noundef nonnull %7, i32 noundef %8, double noundef %3, double noundef %4, i32 noundef %5)    ; C: prep(&x, y, t1, t2, k);  (bracketed)
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #7, !srcloc !13    ; C: (barrier)
  tail call void @__cq_invert_end() #6    ; C: cq_invert_end();
  %9 = load i32, ptr %7, align 4, !tbaa !8    ; C: x
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #7    ; C: cq_measure(x)
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %8) #7    ; C: cq_measure(y)
  %12 = add i32 %11, %10    ; C: cq_measure(x) + cq_measure(y)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #7
  ret i32 %12    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @prep(ptr nocapture noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) unnamed_addr #4 {
  %6 = load i32, ptr %0, align 4, !tbaa !8    ; C: *x
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %6, double noundef %2) #5    ; C: cq_theta(x, t1);
  store i32 %7, ptr %0, align 4, !tbaa !8    ; C: *x = ...
  %8 = icmp ugt i32 %1, %4    ; C: y > k
  br i1 %8, label %9, label %11    ; C: if (y > k)

9:                                                ; preds = %5
  %10 = tail call i32 @cq_theta_ui32(i32 noundef %7, double noundef %3) #5    ; C: cq_theta(x, t2);
  store i32 %10, ptr %0, align 4, !tbaa !8    ; C: *x = ...
  br label %11    ; C: end of if

11:                                               ; preds = %9, %5
  ret void    ; C: return
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{i64 2147510700}
!7 = !{i64 2147511771}
!8 = !{!9, !9, i64 0}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = !{i64 2147515664}
!13 = !{i64 2147515720}
