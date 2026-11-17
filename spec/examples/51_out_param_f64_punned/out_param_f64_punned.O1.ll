; ModuleID = '51_out_param_f64_punned/out_param_f64_punned.c'
source_filename = "51_out_param_f64_punned/out_param_f64_punned.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @out_param_f64_punned(double noundef %0, double noundef %1, i32 noundef %2, i64 noundef %3) local_unnamed_addr #0 {
  %5 = alloca double, align 8    ; C: double ip;
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #5    ; C: (ip comes into scope)
  %7 = call fastcc double @split(double noundef %6, ptr noundef nonnull %5, i32 noundef %2, i64 noundef %3)    ; C: double f = split(x, &ip, k, mask);
  %8 = call double @cq_measure_f64(double noundef %7) #5    ; C: cq_measure(f)
  %9 = load double, ptr %5, align 8, !tbaa !6    ; C: ip  (written by split)
  %10 = call double @cq_measure_f64(double noundef %9) #5    ; C: cq_measure(ip)
  %11 = fadd double %8, %10    ; C: cq_measure(f) + cq_measure(ip)  (classical)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #5    ; C: (ip goes out of scope)
  ret double %11    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline nounwind ssp memory(argmem: readwrite) uwtable
define internal fastcc double @split(double noundef %0, ptr noundef %1, i32 noundef %2, i64 noundef %3) unnamed_addr #3 {
  %5 = bitcast double %0 to i64    ; C: memcpy(&bits, &x, 8)
  %6 = lshr i64 %5, 52    ; C: bits >> 52
  %7 = trunc nuw nsw i64 %6 to i32    ; C: (int)(bits >> 52)
  %8 = and i32 %7, 2047    ; C: int e = ... & 0x7ff;
  %9 = icmp slt i32 %8, %2    ; C: if (e < k)
  br i1 %9, label %10, label %12    ; C: if (e < k)

10:                                               ; preds = %4
  %11 = and i64 %5, %3    ; C: int64_t z = bits & mask;
  store i64 %11, ptr %1, align 1    ; C: memcpy(ip, &z, 8)  (type-punned store of the integral part)
  br label %25    ; C: return x  (end of arm 1)

12:                                               ; preds = %4
  %13 = add nsw i32 %2, 51    ; C: k + 51
  %14 = icmp sgt i32 %8, %13    ; C: if (e > k + 51)
  br i1 %14, label %15, label %17    ; C: if (e > k + 51)

15:                                               ; preds = %12
  store double %0, ptr %1, align 8, !tbaa !6    ; C: *ip = x;
  %16 = fsub double %0, %0    ; C: x - x
  br label %25    ; C: return x - x  (end of arm 2)

17:                                               ; preds = %12
  %18 = sub nsw i32 %8, %2    ; C: e - k
  %19 = zext nneg i32 %18 to i64    ; C: (shift amount)
  %20 = ashr i64 %3, %19    ; C: mask >> (e - k)
  %21 = xor i64 %20, -1    ; C: ~(mask >> (e - k))
  %22 = and i64 %21, %5    ; C: int64_t t = bits & ~(...);
  %23 = bitcast i64 %22 to double    ; C: memcpy(&i, &t, 8)
  store i64 %22, ptr %1, align 8, !tbaa !6    ; C: *ip = i;  (stored as the i64 bits)
  %24 = fsub double %0, %23    ; C: x - i
  br label %25    ; C: return x - i  (end of arm 3)

25:                                               ; preds = %17, %15, %10
  %26 = phi double [ %0, %10 ], [ %16, %15 ], [ %24, %17 ]    ; C: return value: x / x - x / x - i
  ret double %26    ; C: return
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
