; ModuleID = 'bus_pointer_cell.c'
source_filename = "bus_pointer_cell.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @bus_pointer_cell(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4    ; C: int a
  %7 = alloca i32, align 4    ; C: int b
  %8 = alloca [2 x ptr], align 16    ; C: int *slot[2]
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&k, tk);
  %10 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3    ; C: cq_theta(&x, tx);
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #4    ; C: (a comes into scope)
  store i32 1, ptr %6, align 4, !tbaa !6    ; C: a = 1
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #4    ; C: (b comes into scope)
  store i32 %10, ptr %7, align 4, !tbaa !6    ; C: b = x
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %8) #4    ; C: (slot comes into scope)
  store ptr %6, ptr %8, align 16, !tbaa !10    ; C: slot[0] = &a
  %11 = getelementptr inbounds i8, ptr %8, i64 8    ; C: &slot[1]
  store ptr %7, ptr %11, align 8, !tbaa !10    ; C: slot[1] = &b
  %12 = and i32 %9, 1    ; C: k & 1
  %13 = zext nneg i32 %12 to i64    ; C: (index)
  %14 = getelementptr inbounds [2 x ptr], ptr %8, i64 0, i64 %13    ; C: &slot[k & 1]
  %15 = load ptr, ptr %14, align 8, !tbaa !10    ; C: int *p = slot[k & 1];
  store i32 %4, ptr %15, align 4, !tbaa !6    ; C: *p = v;
  %16 = lshr i32 %9, 1    ; C: k >> 1
  %17 = and i32 %16, 1    ; C: (k >> 1) & 1
  %18 = zext nneg i32 %17 to i64    ; C: (index)
  %19 = getelementptr inbounds [2 x ptr], ptr %8, i64 0, i64 %18    ; C: int **pp = &slot[(k >> 1) & 1];
  %20 = load ptr, ptr %19, align 8, !tbaa !10    ; C: *pp
  %21 = load i32, ptr %20, align 4, !tbaa !6    ; C: **pp
  %22 = add nsw i32 %21, 3    ; C: **pp + 3
  store i32 %22, ptr %20, align 4, !tbaa !6    ; C: **pp += 3;
  %23 = load i32, ptr %6, align 4, !tbaa !6    ; C: a
  %24 = load i32, ptr %7, align 4, !tbaa !6    ; C: b
  %25 = add nsw i32 %24, %23    ; C: a + b
  %26 = call i32 @cq_measure_si32(i32 noundef %25) #4    ; C: cq_measure(a + b)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %8) #4    ; C: (slot goes out of scope)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #4    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4    ; C: (a goes out of scope)
  ret i32 %26    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
