; control_swap_select_cmp_parent_operand_derived_measured.ll — ACCEPT, THE MIRROR
; that made F-A1-3 a defect rather than a policy (Track A.1, Rule-13 round-1).
; Verbatim `clang -O1` from `review_a1_r1_probes/c7.c`:
;
;     int q = cq_theta(0, 0.5);
;     int t = q + 3;
;     int m = cq_measure(t);              /* the DERIVED rail is measured */
;     int a = (q == 5) ? 2 : 5;           /* the PARENT is the control    */
;     return m + cq_measure(a) + cq_measure(q);
;
; Same two entangled rails as
; `control_swap_select_cmp_derived_operand_parent_measured.ll`, same one
; measurement, roles swapped — and it ACCEPTED on `main` 0c7380c, on the first
; Track-A.1 build and here. With rung (ii) seeded from the provenance CONE the
; two verdicts were OPPOSITE, which cannot both be right: if the ground is "the
; measurement collapses the entangled pair" this file is an over-accept, and if
; it is "the register the control READS was collapsed" its mirror was an
; over-decline. The seed is now the compare's direct operands, and the pair agrees.
;
; It is also the STOP pin for the wire closure in the other direction:
; `railWireNamesBackward` collects the first non-theta parent and does NOT enter
; its operands (an out-of-place template mints a different register), so the
; measurement of `%h_op` is not read as a measurement of `%h`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = add nsw i32 %1, 3
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %4 = icmp eq i32 %1, 5
  %5 = select i1 %4, i32 2, i32 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %7 = add nsw i32 %6, %3
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %9 = add nsw i32 %7, %8
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}

; CHECK:      %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 3)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h_op)
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; MCNT-COUNT-3: call i32 @cqrt_measure_i32(
; MCNT-NOT:     call i32 @cqrt_measure_i32(
; NOROUTE-NOT:  @cqrt_cswap
; NOROUTE-NOT:  call i32 @cq_theta
