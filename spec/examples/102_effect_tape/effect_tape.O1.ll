; ModuleID = 'effect_tape.c'
source_filename = "effect_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@hit = internal global i32 0, align 4
@.str = private unnamed_addr constant [10 x i8] c"/tmp/cq_x\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @raise_handled(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = tail call ptr @signal(i32 noundef 30, ptr noundef nonnull @h) #5    ; C: signal(SIGUSR1, h);
  %6 = icmp sgt i32 %4, %2    ; C: if (x > k)
  br i1 %6, label %7, label %9    ; C: if (x > k)

7:                                                ; preds = %3
  %8 = tail call i32 @raise(i32 noundef 30) #5    ; C: raise(SIGUSR1);
  br label %9    ; C: end of if

9:                                                ; preds = %7, %3
  %10 = tail call i32 @cq_measure_si32(i32 noundef %4) #5    ; C: cq_measure(x)
  %11 = load volatile i32, ptr @hit, align 4, !tbaa !6    ; C: hit
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #5    ; C: cq_measure(hit)
  %13 = add nsw i32 %12, %10    ; C: cq_measure(x) + cq_measure(hit)
  ret i32 %13    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare ptr @signal(i32 noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: nofree norecurse nounwind ssp memory(readwrite, argmem: none) uwtable
define internal void @h(i32 noundef %0) #2 {
  store volatile i32 %0, ptr @hit, align 4, !tbaa !6    ; C: hit = s;
  ret void    ; C: return
}

declare i32 @raise(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @raise_default(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = icmp sgt i32 %4, %2    ; C: if (x > k)
  br i1 %5, label %6, label %8    ; C: if (x > k)

6:                                                ; preds = %3
  %7 = tail call i32 @raise(i32 noundef 6) #5    ; C: raise(SIGABRT);
  br label %8    ; C: end of if

8:                                                ; preds = %6, %3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %4) #5    ; C: cq_measure(x)
  ret i32 %9    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @remove_cond(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = icmp sgt i32 %4, %2    ; C: if (x > k)
  br i1 %5, label %6, label %8    ; C: if (x > k)

6:                                                ; preds = %3
  %7 = tail call i32 @remove(ptr noundef nonnull @.str)    ; C: remove("/tmp/cq_x");
  br label %8    ; C: end of if

8:                                                ; preds = %6, %3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %4) #5    ; C: cq_measure(x)
  ret i32 %9    ; C: return
}

; Function Attrs: nofree nounwind
declare noundef i32 @remove(ptr nocapture noundef readonly) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nounwind ssp memory(readwrite, argmem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
