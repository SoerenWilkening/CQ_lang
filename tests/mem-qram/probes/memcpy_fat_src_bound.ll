; Rule 22 (cq-pf4n): a quantum-length memcpy into a slot array from a quantum source pointer whose length -O1 does not
; select with it: per object the length's bound capped by the object's extent (A: 4 bytes, Bq: 7); cqcheck user: PASS.
; CHECK sb: call i32 @cq_template_icmp_ugt_i32_hl(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@A = internal unnamed_addr constant [4 x i8] c"\01\02\03\04", align 1
@Bq = internal unnamed_addr constant [8 x i8] c"\05\06\07\08\09\0A\0B\0C", align 1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 69616) i32 @sb(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i64, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store i64 0, ptr %3, align 8
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  %7 = lshr i32 %4, 1
  %8 = select i1 %6, ptr @Bq, ptr @A
  %9 = select i1 %6, i32 7, i32 3
  %10 = and i32 %9, %7
  %11 = zext nneg i32 %10 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 %3, ptr nonnull align 1 %8, i64 %11, i1 false)
  %12 = load i8, ptr %3, align 8, !tbaa !6
  %13 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %12) #5
  %14 = zext i8 %13 to i32
  %15 = getelementptr inbounds i8, ptr %3, i64 2
  %16 = load i8, ptr %15, align 2, !tbaa !6
  %17 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %16) #5
  %18 = zext i8 %17 to i32
  %19 = shl nuw nsw i32 %18, 4
  %20 = add nuw nsw i32 %19, %14
  %21 = getelementptr inbounds i8, ptr %3, i64 5
  %22 = load i8, ptr %21, align 1, !tbaa !6
  %23 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %22) #5
  %24 = zext i8 %23 to i32
  %25 = shl nuw nsw i32 %24, 8
  %26 = add nuw nsw i32 %20, %25
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  ret i32 %26
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
