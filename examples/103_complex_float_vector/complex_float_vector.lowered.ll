; HAND-WRITTEN. Rules: 1, 3 (lane moves emit no gate; an unread lane gets no gate), 18, 25, 26, 4, 5, 2.
; Checked: crealf(q) + cimagf(q) (measured, the result rail %15 -> %16).
; Clean: z's real lane a + 0 (%7), its scaled copy (%8), w's real lane (%10) and the clone's copied-out result lane
; (%13, zeroed by the __cq_q_twicef_10_unc twin), all uncomputed in LIFO order and freed; the clone-internal fadd rail.
; Kept: a (%5, the rotated user register).
; Rotations: (Ry, a, th, 1).
; The x86-64 ABI passes
; and returns `float _Complex` as the fixed vector <2 x float>, so clang emits insertelement, extractelement,
; shufflevector and lane-wise vector fadd. A FIXED 2-LANE VECTOR IS A PAIR OF LANES exactly as the { f32, f32 }
; aggregate of 64: each lane is a rail or a classical value on its own, insertelement/extractelement/shufflevector move
; lanes (no gate: a classical permutation of handles and values), and a vector op is one scalar template per lane that
; is read: in twicef, -O1 computes `%2 = fadd %0, %0` and `%3 = fadd %0, %0` and the shufflevector <0, 3> reads lane 0
; of %2 and lane 1 of %3 only, so %3's quantum lane 0 is dead and gets no template (rule 3), its classical lane 1 is a
; plain fadd; a poison lane is read by nothing and gets no gate either; a bitcast <2 x float> to i64 would be the two
; lanes' bit views (18) shifted and or'ed. Here lane 1 (the imaginary part) stays classical throughout: the clone
; `__cq_q_twicef_10` takes the two lanes as (handle, float) with mask 10 and returns { i32, float } (the quantum lane
; copied out as 64, the classical lane as a plain value); its _unc twin takes the lane-0 handle first.
source_filename = "complex_float_vector.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define float @complex_float(float noundef %0, double noundef %1, float noundef %2, float noundef %3) {
  %5 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %5 = cq_theta_f32(%0, %1)  [register a]
  call void @cqrt_ry_f32(i32 %5, double %1)    ; IR: %5 = cq_theta_f32(%0, %1)  [Ry]
  %6 = fmul float %2, 0.000000e+00    ; IR: %6 = fmul float %2, 0.0  (classical)
  %7 = call i32 @cq_template_fadd_f32_hl(i32 %5, float %6)    ; IR: %7 = fadd float %6, %5  (commutative, quantum operand first)
  %8 = call i32 @cq_template_fmul_f32_hl(i32 %7, float %3)    ; IR: %8 = fmul float %7, %3
  %9 = fmul float %2, %3    ; IR: %9 = fmul float %2, %3  (classical)
  %10 = call i32 @cq_template_fadd_f32(i32 %7, i32 %8)    ; IR: %10 = fadd float %7, %8  [lane 0 of w]
  %11 = fadd float %9, %2    ; IR: %11 = fadd float %9, %2  (classical: lane 1 of w)
  %12 = call fastcc { i32, float } @__cq_q_twicef_10(i32 %10, float %11)    ; IR: %12, %13 = insertelement (lane 0 = %10, lane 1 = %11: no gate); %14 = call @twicef(%13), clone (lane 0 quantum)
  %13 = extractvalue { i32, float } %12, 0    ; IR: %14 lane 0  (handle)
  %14 = extractvalue { i32, float } %12, 1    ; IR: %14 lane 1  (classical)
  %15 = call i32 @cq_template_fadd_f32_hl(i32 %13, float %14)    ; IR: %15 = shufflevector %14, poison, <1, poison> (lane 0 = %14's lane 1: no gate); %16 = fadd <2 x float> %14, %15: lane 0 = %14[0] + %14[1]  [result rail]; lane 1 is poison (no gate)
  call fastcc void @__cq_q_twicef_10_unc(i32 %13, i32 %10, float %11)    ; IR: uncompute %14's lane 0
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_fadd_f32_unc(i32 %10, i32 %7, i32 %8)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %8, i32 %7, float %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fadd_f32_hl_unc(i32 %7, i32 %5, float %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %16 = call float @cqrt_measure_f32(i32 %15)    ; IR: %17 = extractelement %16, 0 (the lane-0 rail); %18 = cq_measure_f32(%17)
  ret float %16    ; IR: ret float %18
}

define internal fastcc { i32, float } @__cq_q_twicef_10(i32 %0, float %1) {
  %3 = call i32 @cq_template_fadd_f32(i32 %0, i32 %0)    ; IR: %2 = fadd <2 x float> %0, %0: lane 0 (the same rail in both slots)
  %4 = fadd float %1, %1    ; IR: %2: lane 1  (classical)
  %5 = fadd float %1, %1    ; IR: %3 = fadd <2 x float> %0, %0: lane 1 (classical); its lane 0 is read by nothing and gets no template (rule 3)
  %6 = call i32 @cqrt_alloc_f32(float 0.000000e+00)    ; IR: %4 = shufflevector %2, %3, <0, 3> (lane 0 = %2[0], lane 1 = %3[1]: no gate); ret  [result rail: lane 0]
  call void @cqrt_copy_f32(i32 %3, i32 %6)    ; IR: ret <2 x float> %4  [copy lane 0 out]
  call void @cq_template_fadd_f32_unc(i32 %3, i32 %0, i32 %0)    ; IR: uncompute %2's lane 0
  call void @cqrt_free(i32 %3)    ; IR: release it (|0>)
  %7 = insertvalue { i32, float } poison, i32 %6, 0    ; IR: ret <2 x float> %4: lane 0, the result handle
  %8 = insertvalue { i32, float } %7, float %5, 1    ; IR: ret <2 x float> %4: lane 1, classical
  ret { i32, float } %8    ; IR: ret <2 x float> %4
}

define internal fastcc void @__cq_q_twicef_10_unc(i32 %0, i32 %1, float %2) {
  %4 = call i32 @cq_template_fadd_f32(i32 %1, i32 %1)    ; IR: recompute %2's lane 0
  call void @cqrt_copy_f32(i32 %4, i32 %0)    ; IR: ret <2 x float> %4  [xor lane 0 out of %out]
  call void @cq_template_fadd_f32_unc(i32 %4, i32 %1, i32 %1)    ; IR: uncompute %2's lane 0
  call void @cqrt_free(i32 %4)    ; IR: release it (|0>)
  ret void
}

declare i32 @cqrt_alloc_f32(float)
declare void @cqrt_copy_f32(i32, i32)
declare void @cqrt_ry_f32(i32, double)
declare float @cqrt_measure_f32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_fadd_f32(i32, i32)
declare void @cq_template_fadd_f32_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f32_hl(i32, float)
declare void @cq_template_fadd_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_fmul_f32_hl(i32, float)
declare void @cq_template_fmul_f32_hl_unc(i32, i32, float)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
