; lowering_loop_break_post_phase_answer.ll — POSITIVE emission (bd
; test_C_libtooling-tinh, an R1 over-decline found by the bd 3by9 Rule-11 review
; round 1). A branch phase keyed on the 7.4 break ANSWER, placed AFTER the loop.
; The module below is `clang -O1`'s output for this C, unedited apart from the
; ModuleID / source_filename lines:
;
;     int break_post_phase_answer(int x, int pseed, int n) {
;         int p = pseed; cq_theta(&p, 0.5);
;         int q = x; cq_theta(&q, 0.25);
;         for (int i = 0; i < n; i++) { q = q ^ 9; if (q == p) break; }
;         if (q == 5) cq_phi(0.3);
;         return cq_measure(q);
;     }
;
; Before the fix this declined `cq loop lowering: early break preserves a phase
; answer`: B3 asks `lineageCarriesBranchPhase` of the escape phi's incomings, and
; the phase's key `%17 = (%16 == 5)` reads the escape phi %16, whose lineage holds
; the rail. `-O1`'s FOLDED twin (`if (q == 5) cq_phi(.3); else cq_phi(.5);`, an
; unconditional `cq_phi(select)` no tainted branch controls) was accepted with a
; correct stream, so the two spellings disagreed. B3 now passes the loop header
; as the construct: a branch phase whose block cannot reach it runs only after
; the construct has finished (or on a path that never enters it), so it is a
; later gate and is not counted. A phase that can reach the header still counts:
; the same program with the kickback BEFORE the loop stays loud
; (lowering_reject_break_pre_phase_answer.ll).
;
; THE TRACE ARGUMENT for the stream pinned below (R2; no simulator).
;  (1) The break construct U (from the `cq.brk.R` mint to the R/idx frees at the
;      head of `cq.brk.tail`) is the gate sequence lowering_loop_break_qq.ll pins
;      (cleared by the 7.4 Rule-13 rounds). For every basis input
;      |q0>|p>|0>_R|0>_idx|0>_out it ends in |q0>|p>|0>|0>|f(q0, p)>, f the
;      source's break answer: the rail is walked back to q0, R and idx are |0>
;      and freed, and `out` holds the value the source's q holds after the loop.
;  (2) The kickback lands in `cq.brk.tail` after those frees (the reverse-play
;      split puts every original instruction of the exit merge after the
;      construct): `f = [out == 5]` XORed into a fresh |0> flag (a basis
;      permutation), `cqrt_rz_i1(f, 0.3)` (diagonal: a relative e^{i 0.3} on the
;      f = 1 branch, up to a global phase), the `_unc` strip (the same XOR, so f is
;      |0> on every basis branch) and ONE `cqrt_free(f)` of that provably-|0> flag
;      (R5). Net: D = diag(e^{i 0.3 [out == 5]}), nothing else.
;  (3) The key `out` holds the source's q on every branch, so D is exactly the
;      source's `if (q == 5) cq_phi(0.3)` applied after the loop, and the stream is
;      D after U. The 923w hazard (a key computed INSIDE the loop leaving with its
;      full-trip value) does not arise: the key reads only the answer, and E16
;      lowers any other in-loop value read after the loop as a control-merge
;      register holding the source's value (bd 8h7d.17) or refuses it. The
;      stream equals the
;      folded twin's with its ¬-arm kickback (`cqrt_x`, `cqrt_rz_i1(f, 0.5)`,
;      `cqrt_x`) removed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=PHASE < %t.ll
;
; CHECK-LABEL: define i32 @break_post_phase_answer(
; CHECK: %cq.brk.R = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; CHECK: cq.brk.rev:
; CHECK: cq.brk.tail:
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK-NEXT: [[F:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.out, i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[F]], i32 %cq.brk.out, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 [[F]])
; CHECK-NEXT: [[M:%[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; CHECK-NEXT: ret i32 [[M]]
;
; --- exactly one phase gate, after the construct; no bracket (the phase is on
;     the true arm), no swap.
; PHASE-COUNT-1: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_x(
; PHASE-NOT: @cqrt_cswap

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_post_phase_answer(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:                                                ; preds = %3, %7
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i32 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i32 %9, 9
  %11 = icmp eq i32 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7, !llvm.loop !6

15:                                               ; preds = %7, %3
  %16 = phi i32 [ %5, %3 ], [ %10, %7 ]
  %17 = icmp eq i32 %16, 5
  br i1 %17, label %18, label %19

18:                                               ; preds = %15
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %19

19:                                               ; preds = %18, %15
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
