; ModuleID = 'quantum_depth_one_clone.c'
source_filename = "quantum_depth_one_clone.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@acc = local_unnamed_addr global i32 5, align 4
@flag = local_unnamed_addr global i8 0, align 1

; Function Attrs: nounwind ssp uwtable
define i32 @quantum_depth_one_clone(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&n, th);
  %5 = tail call fastcc i32 @down(i32 noundef %4, i32 noundef %2)    ; C: down(n, a)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4    ; C: cq_measure(down(n, a))
  ret i32 %6    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @down(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp slt i32 %0, 1    ; C: n <= 0
  br i1 %3, label %4, label %6    ; C: if (n <= 0)

4:                                                ; preds = %2, %6
  %5 = phi i32 [ %10, %6 ], [ %1, %2 ]    ; C: return value: a, or a - down(n - 1, a + 1)
  ret i32 %5    ; C: return

6:                                                ; preds = %2
  %7 = add nsw i32 %0, -1    ; C: n - 1
  %8 = add nsw i32 %1, 1    ; C: a + 1
  %9 = tail call fastcc i32 @down(i32 noundef %7, i32 noundef %8)    ; C: down(n - 1, a + 1)
  %10 = sub nsw i32 %1, %9    ; C: a - down(n - 1, a + 1)
  br label %4    ; C: (join)
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @bool_cell_rotate(double noundef %0) local_unnamed_addr #0 {
  %2 = load i8, ptr @flag, align 1, !tbaa !6, !range !10, !noundef !11    ; C: flag  (the i8 cell)
  %3 = trunc nuw i8 %2 to i1    ; C: (flag as _Bool: the high bits are 0)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef %0) #3    ; C: cq_theta(&flag, th);
  %5 = zext i1 %4 to i8    ; C: (the rotated bit as i8)
  store i8 %5, ptr @flag, align 1, !tbaa !6    ; C: flag = (the rotated value): stored straight back
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4    ; C: cq_measure(flag)
  %7 = zext i1 %6 to i32    ; C: (result as int)
  ret i32 %7    ; C: return
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @theta_add_cell(double noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = load i32, ptr @acc, align 4, !tbaa !12    ; C: acc  (the load of cq_theta(&acc, th))
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %0) #3    ; C: cq_theta(&acc, th);
  %5 = add nsw i32 %4, %1    ; C: acc + d
  store i32 %5, ptr @acc, align 4, !tbaa !12    ; C: acc += d;  (the store of cq_theta was dead: one load and one store remain)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4    ; C: cq_measure(acc)
  ret i32 %6    ; C: return
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = !{!13, !13, i64 0}
!13 = !{!"int", !8, i64 0}
