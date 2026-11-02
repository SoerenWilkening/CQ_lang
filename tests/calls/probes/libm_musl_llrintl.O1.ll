; ModuleID = '/Users/sorenwilkening/Desktop/Projects/wt/cq-il07-rerun/run/llrintl/full.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @sweep_llrintl(x86_fp80 noundef %0) local_unnamed_addr #0 {
  %2 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef 3.000000e-01) #6
  %3 = tail call i64 @llrintl(x86_fp80 noundef %2) #7
  %4 = tail call i64 @cq_measure_sl(i64 noundef %3) #7
  ret i64 %4
}

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.sitofp.f80.i64(i64, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i64 @llvm.experimental.constrained.fptosi.i64.f80(x86_fp80, metadata) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define internal noundef i32 @fetestexcept(i32 noundef %0) local_unnamed_addr #3 {
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define internal noundef i32 @feclearexcept(i32 noundef %0) local_unnamed_addr #3 {
  ret i32 0
}

; Function Attrs: nounwind ssp strictfp
define internal i64 @llrintl(x86_fp80 noundef %0) local_unnamed_addr #4 {
  %2 = tail call i32 @fetestexcept(i32 noundef 32) #8
  %3 = tail call x86_fp80 @rintl(x86_fp80 noundef %0) #8
  %4 = icmp eq i32 %2, 0
  br i1 %4, label %5, label %13

5:                                                ; preds = %1
  %6 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i64(i64 9223372036854775807, metadata !"round.dynamic", metadata !"fpexcept.strict") #9
  %7 = tail call i1 @llvm.experimental.constrained.fcmps.f80(x86_fp80 %3, x86_fp80 %6, metadata !"ogt", metadata !"fpexcept.strict") #9
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i64(i64 -9223372036854775808, metadata !"round.dynamic", metadata !"fpexcept.strict") #9
  %10 = tail call i1 @llvm.experimental.constrained.fcmps.f80(x86_fp80 %3, x86_fp80 %9, metadata !"olt", metadata !"fpexcept.strict") #9
  br i1 %10, label %11, label %13

11:                                               ; preds = %8, %5
  %12 = tail call i32 @feclearexcept(i32 noundef 32) #8
  br label %13

13:                                               ; preds = %11, %8, %1
  %14 = tail call i64 @llvm.experimental.constrained.fptosi.i64.f80(x86_fp80 %3, metadata !"fpexcept.strict") #9
  ret i64 %14
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define internal x86_fp80 @rintl(x86_fp80 noundef %0) local_unnamed_addr #5 {
  %2 = bitcast x86_fp80 %0 to i80
  %3 = lshr i80 %2, 64
  %4 = trunc nuw nsw i80 %3 to i32
  %5 = and i32 %4, 32766
  %6 = icmp ugt i32 %5, 16445
  br i1 %6, label %22, label %7

7:                                                ; preds = %1
  %8 = icmp ult i32 %4, 32768
  br i1 %8, label %12, label %9

9:                                                ; preds = %7
  %10 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %0, x86_fp80 0xK403E8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %11 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %10, x86_fp80 0xK403E8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %15

12:                                               ; preds = %7
  %13 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %0, x86_fp80 0xK403E8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %14 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %13, x86_fp80 0xK403E8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %15

15:                                               ; preds = %12, %9
  %16 = phi x86_fp80 [ %11, %9 ], [ %14, %12 ]
  %17 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %18 = tail call i1 @llvm.experimental.constrained.fcmp.f80(x86_fp80 %16, x86_fp80 %17, metadata !"oeq", metadata !"fpexcept.ignore") #9
  br i1 %18, label %19, label %22

19:                                               ; preds = %15
  %20 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %21 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %20, x86_fp80 %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %22

22:                                               ; preds = %19, %15, %1
  %23 = phi x86_fp80 [ %21, %19 ], [ %0, %1 ], [ %16, %15 ]
  ret x86_fp80 %23
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }
attributes #8 = { nobuiltin nounwind strictfp "no-builtins" }
attributes #9 = { strictfp }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5, !6}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
