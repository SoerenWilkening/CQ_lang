; ModuleID = 'bit_views.c'
source_filename = "bit_views.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @high_word(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = bitcast double %3 to i64    ; C: u.d = x;  (bits of x)
  %5 = lshr i64 %4, 32    ; C: u.w[1]  (high word: bits >> 32)
  %6 = trunc nuw i64 %5 to i32    ; C: u.w[1]  (as uint32_t)
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #3    ; C: cq_measure(...)
  ret i32 %7    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @bits_of(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = bitcast double %3 to i64    ; C: memcpy(&b, &x, 8);
  %5 = tail call i64 @cq_measure_ull(i64 noundef %4) #3    ; C: cq_measure(b)
  ret i64 %5    ; C: return
}

declare i64 @cq_measure_ull(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @from_words(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2    ; C: cq_theta(&h, th);
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #2    ; C: cq_theta(&l, tl);
  %7 = zext i32 %6 to i64    ; C: u.w[0] = l;
  %8 = zext i32 %5 to i64    ; C: u.w[1] = h;
  %9 = shl nuw i64 %8, 32    ; C: u.w[1] = h;  (into bits 32..63)
  %10 = or disjoint i64 %9, %7    ; C: u.w[0] = l; u.w[1] = h;  (combined bits)
  %11 = bitcast i64 %10 to double    ; C: u.d
  %12 = tail call double @cq_measure_f64(double noundef %11) #3    ; C: cq_measure(...)
  ret double %12    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
