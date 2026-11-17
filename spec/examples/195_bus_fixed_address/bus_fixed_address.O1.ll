; ModuleID = 'bus_fixed_address.c'
source_filename = "bus_fixed_address.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@reg = local_unnamed_addr global i32 2, align 4
@cell = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @bus_global_cell(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, tx);
  store i32 %5, ptr @cell, align 4, !tbaa !6    ; C: cell = x;
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4    ; C: cq_theta(&y, ty);
  %7 = load i32, ptr @cell, align 4, !tbaa !6    ; C: cell  (loaded again: the cq_theta call between may write it)
  %8 = add nsw i32 %7, %6    ; C: cell + y
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #5    ; C: cq_measure(cell + y)
  ret i32 %9    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @bus_escaped_local(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4    ; C: int w
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, tx);
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #5    ; C: (w comes into scope)
  store i32 %4, ptr %3, align 4, !tbaa !6    ; C: int w = x;
  call fastcc void @bump(ptr noundef nonnull %3)    ; C: bump(&w);
  %5 = load i32, ptr %3, align 4, !tbaa !6    ; C: w
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5    ; C: cq_measure(w)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #5    ; C: (w goes out of scope)
  ret i32 %6    ; C: return
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !6    ; C: *p
  %3 = add nsw i32 %2, 1    ; C: *p + 1
  store i32 %3, ptr %0, align 4, !tbaa !6    ; C: *p += 1;
  ret void    ; C: (end of bump)
}

; Function Attrs: nounwind ssp uwtable
define i32 @bus_rotate_cell(double noundef %0) local_unnamed_addr #0 {
  %2 = load i32, ptr @reg, align 4, !tbaa !6    ; C: reg  (the load of cq_theta(&reg, tr))
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %0) #4    ; C: cq_theta(&reg, tr);
  store i32 %3, ptr @reg, align 4, !tbaa !6    ; C: reg = (the rotated value): stored straight back through the same pointer
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #5    ; C: cq_measure(reg)  (the stored value, forwarded by -O1)
  ret i32 %4    ; C: return
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
