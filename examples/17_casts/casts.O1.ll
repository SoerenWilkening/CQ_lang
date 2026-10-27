; ModuleID = 'casts.c'
source_filename = "casts.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define signext i16 @trunc_i32_i16(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = trunc i32 %3 to i16    ; C: y = (short)x;
  %5 = tail call signext i16 @cq_measure_si16(i16 noundef signext %4) #3    ; C: cq_measure(y)
  ret i16 %5    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @zext_u16_i32(i16 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i16 @cq_theta_ui16(i16 noundef zeroext %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = zext i16 %3 to i32    ; C: y = x;
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3    ; C: cq_measure(y)
  ret i32 %5    ; C: return
}

declare zeroext i16 @cq_theta_ui16(i16 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @sext_i8_i32(i8 noundef signext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = sext i8 %3 to i32    ; C: y = x;
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3    ; C: cq_measure(y)
  ret i32 %5    ; C: return
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @sitofp_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = sitofp i32 %3 to double    ; C: (double)x
  %5 = tail call double @cq_measure_f64(double noundef %4) #3    ; C: cq_measure((double)x)
  ret double %5    ; C: return
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @fptosi_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = fptosi double %3 to i32    ; C: (int)x
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3    ; C: cq_measure((int)x)
  ret i32 %5    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @fpext_q(float noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call float @cq_theta_f32(float noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = fpext float %3 to double    ; C: (double)x
  %5 = tail call double @cq_measure_f64(double noundef %4) #3    ; C: cq_measure((double)x)
  ret double %5    ; C: return
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define float @fptrunc_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %4 = fptrunc double %3 to float    ; C: (float)x
  %5 = tail call float @cq_measure_f32(float noundef %4) #3    ; C: cq_measure((float)x)
  ret float %5    ; C: return
}

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

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
