; ModuleID = 'bus_mutable_table.c'
source_filename = "bus_mutable_table.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = local_unnamed_addr global [4 x i32] [i32 2, i32 7, i32 1, i32 8], align 16
@ROM = internal unnamed_addr constant [4 x i32] [i32 3, i32 1, i32 4, i32 1], align 16

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define void @tab_set(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 3    ; C: i & 3
  %4 = zext nneg i32 %3 to i64    ; C: (index)
  %5 = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %4    ; C: &tab[i & 3]
  store i32 %1, ptr %5, align 4, !tbaa !6    ; C: tab[i & 3] = v;
  ret void    ; C: (end of tab_set)
}

; Function Attrs: nounwind ssp uwtable
define i32 @bus_mutable_table(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&k, tk);
  %4 = and i32 %3, 3    ; C: k & 3
  %5 = zext nneg i32 %4 to i64    ; C: (index, shared by both loads)
  %6 = getelementptr inbounds [4 x i32], ptr @ROM, i64 0, i64 %5    ; C: &ROM[k & 3]
  %7 = load i32, ptr %6, align 4, !tbaa !6    ; C: ROM[k & 3]
  %8 = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %5    ; C: &tab[k & 3]
  %9 = load i32, ptr %8, align 4, !tbaa !6    ; C: tab[k & 3]
  %10 = add nsw i32 %9, %7    ; C: ROM[k & 3] + tab[k & 3]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4    ; C: cq_measure(ROM[k & 3] + tab[k & 3])
  ret i32 %11    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
