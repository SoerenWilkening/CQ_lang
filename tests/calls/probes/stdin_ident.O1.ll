; ModuleID = 'stdin_ident.c'
source_filename = "stdin_ident.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8
@__stderrp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_ident(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = alloca [2 x ptr], align 16
  %3 = alloca [8 x i8], align 8
  %4 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #5
  %5 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  store ptr %5, ptr %2, align 16, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %2, i64 8
  %7 = load ptr, ptr @__stderrp, align 8, !tbaa !6
  store ptr %7, ptr %6, align 8, !tbaa !6
  %8 = sext i8 %4 to i32
  %9 = and i32 %8, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [2 x ptr], ptr %2, i64 0, i64 %10
  %12 = load ptr, ptr %11, align 8, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #5
  store i64 0, ptr %3, align 8
  %13 = call ptr @fgets(ptr noundef nonnull %3, i32 noundef 4, ptr noundef %12)
  %14 = call i32 @getc(ptr noundef %12)
  %15 = icmp ne ptr %13, null
  %16 = zext i1 %15 to i32
  %17 = load i8, ptr %3, align 8, !tbaa !10
  %18 = sext i8 %17 to i32
  %19 = mul nsw i32 %18, 3
  %20 = getelementptr inbounds i8, ptr %3, i64 1
  %21 = load i8, ptr %20, align 1, !tbaa !10
  %22 = sext i8 %21 to i32
  %23 = mul nsw i32 %22, 5
  %24 = mul nsw i32 %14, 7
  %25 = add nsw i32 %16, %8
  %26 = add i32 %25, %24
  %27 = add i32 %26, %19
  %28 = add i32 %27, %23
  %29 = call i32 @cq_measure_si32(i32 noundef %28) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #5
  ret i32 %29
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef ptr @fgets(ptr noundef, i32 noundef, ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @getc(ptr nocapture noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
