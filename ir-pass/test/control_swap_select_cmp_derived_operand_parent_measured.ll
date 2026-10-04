; control_swap_select_cmp_derived_operand_parent_measured.ll — ACCEPT, and a
; DECLINE → ACCEPT MOVER AGAINST THE FIRST TRACK-A.1 BUILD (Rule-13 round-1
; finding F-A1-3: an OVER-DECLINE of a circuit `main` compiles). Verbatim
; `clang -O1` from `review_a1_r1_probes/c1.c`:
;
;     int q = 0; cq_theta(&q, 0.5);
;     int t = q + 3;
;     int m = cq_measure(q);
;     int a = (t == 5) ? 2 : 5;
;     return m + cq_measure(a) + cq_measure(t);
;
; WHY IT MUST ACCEPT, measured on the oracle and unchanged here: `t` lowers OUT
; of place — `cq_template_add_i32_hl(%h, 3)` MINTS A FRESH RAIL — and the flag is
; minted from THAT rail (`%h_op`), never from the measured `%h`. `q`'s
; measurement fixes `t` through their entanglement, so the flag is deterministic
; and the emitted unitary is exactly what the source asks for
; (`free_pairing_check.py`: 4 rail mints, 1 free site, 1 verified, 0 violations).
;
; WHAT WENT WRONG, AND THE LESSON. Rung (ii)'s first spelling seeded from
; `condProvenance` — every tainted ANCESTOR of the condition — so it asked its
; question about `%h`, a register the control never reads, and refused. The seed
; is now the compare's DIRECT TAINTED OPERANDS (`condCmpOperandSeeds`), because
; the rung's question is "was the register THE CONTROL READS collapsed?". The
; class was also ASYMMETRIC, which is what made it a defect rather than a policy:
; `control_swap_select_cmp_parent_operand_derived_measured.ll` is the exact
; mirror — same two entangled rails, same one measurement, opposite roles — and
; it accepted throughout. It cannot be right that one of the two is refused.
;
; ⚠ THE NARROWING IS OF THE SEED, NEVER OF THE WIRE. The seed's own wire closure
; still crosses every name of the same physical register: a chained theta's arg-0
; (`control_swap_reject_select_cmp_measured_parent_name.ll`) and an IN-PLACE
; relabelling (`taint.InPlaceRailOps`). And it is about the WIRE rather than the
; SPELLING, which is why two of the four reported over-declines stay DECLINES:
; with `long long t = (long long) q;` or `if (t > 3)`, `clang -O1` folds the cast
; and rewrites the compare back onto `%q` ITSELF, so the direct operand IS the
; measured register — `control_phase_kickback_reject_cmp_derived_folded_to_parent.ll`
; is that program, and it is bd `r903` item (b) verbatim.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOPOST %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = add nsw i32 %1, 3
  %3 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %4 = icmp eq i32 %2, 5
  %5 = select i1 %4, i32 2, i32 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %7 = add nsw i32 %6, %3
  %8 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
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

; THE ASSERTION IS WHICH RAIL THE FLAG READS: the add mints `%h_op`, the measure
; collapses `%h`, and the flag is minted from `%h_op`.
; CHECK:      %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 3)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h)
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 5)
; The flag must NEVER be minted from the measured register — that is bd r903(b),
; and it is what the decline twin pins. WHOLE-FILE (a trailing `CHECK-NOT` would
; be windowed by the positives above it and assert nothing).
; NOPOST-NOT: call i32 @cq_template_icmp_eq_i32_hl(i32 %h,
; MCNT-COUNT-3: call i32 @cqrt_measure_i32(
; MCNT-NOT:     call i32 @cqrt_measure_i32(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; NOROUTE-NOT:  @cqrt_cswap
; NOROUTE-NOT:  call i32 @cq_theta
