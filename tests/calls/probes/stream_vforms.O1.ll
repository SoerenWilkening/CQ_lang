; ModuleID = 'stream_vforms.c'
source_filename = "stream_vforms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@.str = private unnamed_addr constant [13 x i8] c"%d|%s|%5.3s|\00", align 1
@.str.1 = private unnamed_addr constant [3 x i8] c"ab\00", align 1
@.str.2 = private unnamed_addr constant [5 x i8] c"wxyz\00", align 1
@__stdoutp = external local_unnamed_addr global ptr, align 8
@.str.3 = private unnamed_addr constant [22 x i8] c"<%ld %c %.2f %Lg %*d>\00", align 1
@.str.4 = private unnamed_addr constant [10 x i8] c"odd %hhx;\00", align 1
@__stderrp = external local_unnamed_addr global ptr, align 8
@.str.5 = private unnamed_addr constant [8 x i8] c"err %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @stream_vforms(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #6
  %3 = sext i8 %2 to i32
  tail call void (ptr, ...) @say(ptr nonnull poison, i32 noundef %3, ptr noundef nonnull @.str.1, ptr noundef nonnull @.str.2)
  %4 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  %5 = sext i8 %2 to i64
  %6 = mul nsw i64 %5, 3
  %7 = and i32 %3, 7
  %8 = add nuw nsw i32 %7, 65
  %9 = sitofp i8 %2 to double
  %10 = fmul double %9, 5.000000e-01
  %11 = sitofp i8 %2 to x86_fp80
  %12 = fmul x86_fp80 %11, 0xK3FFD8000000000000000
  tail call void (ptr, ptr, ...) @say_to(ptr noundef %4, ptr noundef nonnull @.str.3, i64 noundef %6, i32 noundef %8, double noundef %10, x86_fp80 noundef %12, i32 noundef 4, i32 noundef %3)
  %13 = and i32 %3, 1
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %1
  %16 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  tail call void (ptr, ptr, ...) @say_to(ptr noundef %16, ptr noundef nonnull @.str.4, i32 noundef %3)
  br label %17

17:                                               ; preds = %15, %1
  %18 = load ptr, ptr @__stderrp, align 8, !tbaa !6
  tail call void (ptr, ptr, ...) @say_to(ptr noundef %18, ptr noundef nonnull @.str.5, i32 noundef %3)
  %19 = add nsw i32 %3, 1
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #7
  ret i32 %20
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline nounwind ssp uwtable
define internal void @say(ptr nocapture readnone %0, ...) unnamed_addr #3 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #7
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = call i32 @vprintf(ptr noundef nonnull @.str, ptr noundef nonnull %2) #7
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #7
  ret void
}

; Function Attrs: nofree noinline nounwind ssp uwtable
define internal void @say_to(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, ...) unnamed_addr #3 {
  %3 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #7
  call void @llvm.va_start.p0(ptr nonnull %3)
  %4 = call i32 @vfprintf(ptr noundef %0, ptr noundef %1, ptr noundef nonnull %3) #7
  call void @llvm.va_end.p0(ptr %3)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #7
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #4

; Function Attrs: nofree nounwind
declare noundef i32 @vprintf(ptr nocapture noundef readonly, ptr noundef) local_unnamed_addr #5

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #4

; Function Attrs: nofree nounwind
declare noundef i32 @vfprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ptr noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #5 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

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
