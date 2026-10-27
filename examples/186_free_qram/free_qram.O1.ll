; ModuleID = 'free_qram.c'
source_filename = "free_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @free_uncond(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #6
  %6 = and i32 %4, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i8, ptr %5, i64 %7
  store i8 %2, ptr %8, align 1, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %5, i64 1
  %10 = load i8, ptr %9, align 1, !tbaa !6
  %11 = tail call dereferenceable_or_null(6) ptr @realloc(ptr noundef %5, i64 noundef 6) #7
  %12 = getelementptr inbounds i8, ptr %11, i64 5
  store i8 2, ptr %12, align 1, !tbaa !6
  %13 = urem i32 %4, 6
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds i8, ptr %11, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6
  %17 = add i8 %16, %10
  tail call void @free(ptr noundef %11)
  %18 = mul i32 %4, 3
  %19 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %17) #8
  %20 = zext i8 %19 to i32
  %21 = tail call i32 @cq_measure_ui32(i32 noundef %18) #8
  %22 = add i32 %21, %20
  ret i32 %22
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite)
declare noalias noundef ptr @realloc(ptr allocptr nocapture noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #4

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @free_classical_cond(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %6 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #6
  %7 = and i32 %5, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds i8, ptr %6, i64 %8
  store i8 %2, ptr %9, align 1, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %6, i64 1
  %11 = load i8, ptr %10, align 1, !tbaa !6
  %12 = tail call dereferenceable_or_null(6) ptr @realloc(ptr noundef %6, i64 noundef 6) #7
  %13 = getelementptr inbounds i8, ptr %12, i64 5
  store i8 2, ptr %13, align 1, !tbaa !6
  %14 = urem i32 %5, 6
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds i8, ptr %12, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = icmp eq i32 %3, 0
  br i1 %18, label %20, label %19

19:                                               ; preds = %4
  tail call void @free(ptr noundef %12)
  br label %20

20:                                               ; preds = %19, %4
  %21 = add i8 %17, %11
  %22 = mul i32 %5, 3
  %23 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %21) #8
  %24 = zext i8 %23 to i32
  %25 = tail call i32 @cq_measure_ui32(i32 noundef %22) #8
  %26 = add i32 %25, %24
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @free_entangled(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %7 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #5
  %8 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #6
  %9 = and i32 %6, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i8, ptr %8, i64 %10
  store i8 %7, ptr %11, align 1, !tbaa !6
  %12 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %7, double noundef %4) #5
  store i8 1, ptr %8, align 1, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %8, i64 1
  %14 = load i8, ptr %13, align 1, !tbaa !6
  %15 = add i8 %14, 1
  tail call void @free(ptr noundef %8)
  %16 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %15) #8
  %17 = zext i8 %16 to i32
  ret i32 %17
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @qram_ptr_addr(i32 noundef %0, double noundef %1, ptr noundef readnone %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #6
  %6 = and i32 %4, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i32, ptr %5, i64 %7
  store i32 5, ptr %8, align 4, !tbaa !9
  %9 = shl i32 %4, 1
  %10 = and i32 %9, 12
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds i8, ptr %5, i64 %11
  %13 = icmp eq ptr %12, %2
  %14 = zext i1 %13 to i32
  %15 = icmp ult i32 %10, 8
  %16 = zext i1 %15 to i32
  %17 = getelementptr inbounds i8, ptr %5, i64 4
  %18 = load i32, ptr %17, align 4, !tbaa !9
  tail call void @free(ptr noundef %5)
  %19 = tail call i32 @cq_measure_si32(i32 noundef %14) #8
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #8
  %21 = add nsw i32 %20, %19
  %22 = tail call i64 @cq_measure_sl(i64 noundef %11) #8
  %23 = tail call i32 @cq_measure_si32(i32 noundef %18) #8
  %24 = trunc i64 %22 to i32
  %25 = add i32 %21, %24
  %26 = add i32 %25, %23
  ret i32 %26
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

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
