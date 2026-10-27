; ModuleID = 'pointer_out_param.c'
source_filename = "pointer_out_param.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @pointer_out_param(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4    ; C: int hi;
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #5    ; C: (hi comes into scope)
  %6 = call fastcc i32 @split(i32 noundef %5, i32 noundef %2, ptr noundef nonnull %4)    ; C: int lo = split(x, k, &hi);
  %7 = load i32, ptr %4, align 4, !tbaa !6    ; C: hi  (written by split)
  %8 = add nsw i32 %7, %6    ; C: lo + hi
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #5    ; C: cq_measure(lo + hi)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #5    ; C: (hi goes out of scope)
  ret i32 %9    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc i32 @split(i32 noundef %0, i32 noundef %1, ptr nocapture noundef writeonly %2) unnamed_addr #3 {
  %4 = ashr i32 %0, %1    ; C: v >> k
  store i32 %4, ptr %2, align 4, !tbaa !6    ; C: *hi = v >> k;
  %5 = shl nsw i32 -1, %1    ; C: (1 << k) - 1  (as ~(-1 << k))
  %6 = xor i32 %5, -1    ; C: (1 << k) - 1
  %7 = and i32 %6, %0    ; C: v & ((1 << k) - 1)
  ret i32 %7    ; C: return
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
