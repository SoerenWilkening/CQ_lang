; ModuleID = 'call_result_rotation.c'
source_filename = "call_result_rotation.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @call_result_as_target(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %8 = tail call fastcc i32 @pick(i32 noundef %7, i32 noundef %2, i32 noundef %3, i32 noundef %4)    ; C: y = pick(x, k, a, b)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef %5) #3    ; C: cq_theta(&y, t);
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4    ; C: cq_measure(y)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %7) #4    ; C: cq_measure(x)
  %12 = add nsw i32 %11, %10    ; C: cq_measure(y) + cq_measure(x)
  ret i32 %12    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i32 @pick(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #2 {
  %5 = icmp sgt i32 %0, %1    ; C: v > k
  %6 = add nsw i32 %2, %0    ; C: v + a
  %7 = mul nsw i32 %3, %0    ; C: v * b
  %8 = select i1 %5, i32 %6, i32 %7    ; C: v > k ? v + a : v * b
  ret i32 %8    ; C: return ...;
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @call_result_as_theta_angle(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %7 = tail call fastcc zeroext i8 @pick8(i8 noundef zeroext %6, i8 noundef zeroext %2)    ; C: pick8(x, k)
  %8 = uitofp i8 %7 to double    ; C: (double) pick8(x, k)
  %9 = fmul double %8, %4    ; C: s * pick8(x, k)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %9) #3    ; C: cq_theta(&r, s * pick8(x, k));  (r = r0)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4    ; C: cq_measure(r)
  %12 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %6) #4    ; C: cq_measure(x)
  %13 = zext i8 %12 to i32    ; C: (int) cq_measure(x)
  %14 = add nsw i32 %11, %13    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %14    ; C: return ...;
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc noundef zeroext i8 @pick8(i8 noundef zeroext %0, i8 noundef zeroext %1) unnamed_addr #2 {
  %3 = icmp ugt i8 %0, %1    ; C: v > k
  %4 = add i8 %0, 1    ; C: v + 1
  %5 = shl i8 %0, 1    ; C: v * 2
  %6 = select i1 %3, i8 %4, i8 %5    ; C: v > k ? v + 1 : v * 2
  ret i8 %6    ; C: return ...;
}

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @call_result_as_phi_angle(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call fastcc zeroext i8 @pick8(i8 noundef zeroext %5, i8 noundef zeroext %2)    ; C: pick8(x, k)
  %7 = uitofp i8 %6 to double    ; C: (double) pick8(x, k)
  %8 = fmul double %7, %3    ; C: s * pick8(x, k)
  tail call void @cq_phi(double noundef %8) #4    ; C: cq_phi(s * pick8(x, k));
  %9 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %5) #4    ; C: cq_measure(x)
  %10 = zext i8 %9 to i32    ; C: (int) cq_measure(x)
  ret i32 %10    ; C: return ...;
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
