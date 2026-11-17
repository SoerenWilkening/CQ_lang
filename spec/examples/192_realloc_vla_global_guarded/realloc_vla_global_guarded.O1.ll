; ModuleID = 'realloc_vla_global_guarded.c'
source_filename = "realloc_vla_global_guarded.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@table = internal unnamed_addr global [8 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @realloc_shrink(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #6
  %6 = and i32 %4, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i8, ptr %5, i64 %7
  store i8 %2, ptr %8, align 1, !tbaa !6
  %9 = tail call dereferenceable_or_null(2) ptr @realloc(ptr noundef %5, i64 noundef 2) #7
  %10 = and i32 %4, 1
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds i8, ptr %9, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6
  tail call void @free(ptr noundef %9)
  %14 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %13) #8
  %15 = zext i8 %14 to i32
  ret i32 %15
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite)
declare noalias noundef ptr @realloc(ptr allocptr nocapture noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #4

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @realloc_qsize(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = tail call dereferenceable_or_null(2) ptr @malloc(i64 noundef 2) #6
  %6 = and i32 %4, 1
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i8, ptr %5, i64 %7
  store i8 %2, ptr %8, align 1, !tbaa !6
  %9 = and i32 %4, 3
  %10 = add nuw nsw i32 %9, 2
  %11 = zext nneg i32 %10 to i64
  %12 = tail call ptr @realloc(ptr noundef %5, i64 noundef %11) #7
  %13 = zext nneg i32 %9 to i64
  %14 = getelementptr inbounds i8, ptr %12, i64 %13
  %15 = getelementptr inbounds i8, ptr %14, i64 1
  store i8 7, ptr %15, align 1, !tbaa !6
  %16 = getelementptr inbounds i8, ptr %12, i64 %7
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = getelementptr inbounds i8, ptr %12, i64 1
  %19 = load i8, ptr %18, align 1, !tbaa !6
  %20 = add i8 %19, %17
  tail call void @free(ptr noundef %12)
  %21 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %20) #8
  %22 = zext i8 %21 to i32
  ret i32 %22
}

; Function Attrs: nounwind ssp uwtable
define i32 @vla_qram(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %6 = zext i32 %3 to i64
  %7 = alloca i32, i64 %6, align 16
  %8 = urem i32 %5, %3
  %9 = zext i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr %7, i64 %9
  store i32 %2, ptr %10, align 4, !tbaa !9
  %11 = load i32, ptr %7, align 16, !tbaa !9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #8
  ret i32 %12
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @guarded_global(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %3, double noundef %4) #5
  %9 = icmp ugt i32 %7, %2
  br i1 %9, label %10, label %14

10:                                               ; preds = %6
  %11 = and i32 %8, 7
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr @table, i64 0, i64 %12
  store i32 %5, ptr %13, align 4, !tbaa !9
  br label %14

14:                                               ; preds = %10, %6
  %15 = and i32 %8, 7
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [8 x i32], ptr @table, i64 0, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !9
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #8
  ret i32 %19
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { allocsize(0) }
attributes #7 = { allocsize(1) }
attributes #8 = { nounwind }

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
!9 = !{!10, !10, i64 0}
!10 = !{!"int", !7, i64 0}
