; lowering_loop_break_hoisted_comparand.ll — POSITIVE emission (bd
; test_C_libtooling-8h7d.15, an R1 over-decline). A 7.4 value-arm `break` whose
; comparand is an EXPRESSION that `clang -O1` LICM hoists out of the break
; condition. The module below is `clang -O1`'s output for this C, unedited apart
; from the ModuleID / source_filename lines:
;
;     int break_hoisted_sum(int x, int pseed, int k, int n) {
;         int p = pseed; cq_theta(&p, 0.5);
;         int q = x; cq_theta(&q, 0.25);
;         for (int i = 0; i < n; i++) { q = q ^ 9; if (q == p + k) break; }
;         return cq_measure(q);
;     }
;
; THE SHAPE. LICM moves the invariant `p + k` (%9) into the loop's preheader, and
; because the zero-trip guard (%4, `n > 0`) has two successors the preheader stays
; a DEDICATED block (%8: one predecessor, an unconditional branch to the header)
; that the guard's zero-trip edge bypasses. Before the fix `emitBreakForward` took
; the rail phi's entry block (%8) for the guard and declined
; `cq loop lowering: early break body is not a provable rolled single-rail loop`
; (first at E13: the escape phi's zero-trip incoming comes from %4, not %8; E6 and
; E12 would refuse %8 too).
;
; THE FIX (E17). The guard is the dedicated preheader's single predecessor. The
; preheader's instructions are HOISTED into the guard (each must pass
; `isSafeToSpeculativelyExecute`, since it now also runs on the zero-trip path),
; R/idx/out are minted there, and E6/E12/E13 ask the guard. The module after the
; hoist is the canonical shape this emitter already lowers; the preheader keeps
; only its branch.
;
; THE TRACE ARGUMENT for the stream pinned below (R2; no simulator).
;  (1) The hoist is a program equivalence on the classical level: `add` cannot
;      trap and has no side effect, and its operands (p, k) are defined above the
;      guard. On the quantum level `cq_template_add_i32_hl(p, k)` writes p + k into
;      a fresh |0> register c (a basis permutation of (p, 0) to (p, p + k)) and
;      leaves p untouched. On the zero-trip path nothing reads c.
;  (2) The break construct U (from the `cq.brk.R` mint to the R/idx frees in
;      `cq.brk.tail`) is the gate sequence lowering_loop_break_qq_derived.ll pins
;      for a comparand derived before the guard (cleared by the 7.4 Rule-13 rounds
;      and the 1784 sign-off). c's handle appears in U ONLY as the second operand of
;      `cq_template_icmp_eq_i32` and its `_unc`, in the forward body and in the
;      `cq.brk.rev` clone: read as a control, never written, copied, swapped,
;      reverse-played or freed. For every basis input |q0>|p>|c>|0>_R|0>_idx|0>_out
;      U ends in |q0>|p>|c>|0>|0>|f(q0, c)>, f the source's break answer, c = p + k.
;      The clone in `cq.brk.rev` names c, which is legal only because c is now
;      defined in the guard (it dominates the exit merge); left in the preheader it
;      would be an ill-dominated module.
;  (3) Every `cqrt_free` inside U frees a register that is |0> on every basis
;      branch. c is left allocated and never freed (R5: it is not provably |0>).
;      That is the comparand-template leak lowering_loop_break_qq_derived.ll
;      documents for a pre-guard derivation (stage 2b: 1 template rail left
;      dirty); this landing adds the LICM-hoisted population to it and runs the
;      computation on the zero-trip path too (L9). The leaked c is entangled
;      with p, so a later NON-DIAGONAL gate on p sees a dephased p; that case
;      only warns (`cq rotation lowering: non-diagonal gate over a live derived
;      record`), and 8h7d.15 makes it reachable from C, including on the
;      zero-trip path where the source never copies p (measured on the `_Bool`
;      twin, lowering_loop_break_hoisted_bool_comparand.ll).
; MEASURED: linked and run, the trace of this module is byte-identical to main's
; trace of the hand-hoisted twin (the same module with %9 moved into %4 and %8
; deleted).
;
; RETIREMENT TRIGGER: when the spine uncomputes a 7.4 comparand template after the
; reverse-play, LEAK changes (an `_unc` and a free of c appear); re-derive it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=LEAK < %t.ll
;
; CHECK-LABEL: define i32 @break_hoisted_sum(
; CHECK: [[P:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[P]], double 5.000000e-01)
; CHECK-NEXT: [[RAIL:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[RAIL]], double 2.500000e-01)
; CHECK-NEXT: [[G:%[0-9]+]] = icmp sgt i32 %3, 0
; --- the hoisted comparand, now in the guard block, ahead of the 7.4 scratch
; CHECK-NEXT: [[C:%[a-z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 [[P]], i32 %2)
; CHECK-NEXT: %cq.brk.R = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.idx = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: br i1 [[G]], label %[[PH:[0-9]+]], label %[[EXIT:[0-9]+]]
; --- the dedicated preheader keeps only its branch
; CHECK: [[PH]]:
; CHECK-NEXT: br label %[[LOOP:[0-9]+]]
; CHECK: [[LOOP]]:
; CHECK: call void @cqrt_xorc_i32(i32 [[RAIL]], i32 9)
; CHECK-NEXT: [[FCMP:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 [[RAIL]], i32 [[C]])
; CHECK: call void @cqrt_toffoli(i32 [[FCMP]],
; CHECK: call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire, i32 [[RAIL]], i32 %cq.brk.R)
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 [[FCMP]], i32 [[RAIL]], i32 [[C]])
; CHECK-NEXT: call void @cqrt_free(i32 [[FCMP]])
; CHECK: [[EXIT]]:
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; --- the reverse-play reuses the forward guard
; CHECK: br i1 [[G]], label %cq.brk.rev, label %cq.brk.tail
; CHECK: cq.brk.rev:
; CHECK: [[BCMP:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 [[RAIL]], i32 [[C]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[BCMP]],
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_unc(i32 [[BCMP]], i32 [[RAIL]], i32 [[C]])
; CHECK: call void @cqrt_xorc_i32(i32 [[RAIL]], i32 9)
; CHECK: cq.brk.tail:
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
;
; --- c is never freed (R5): it is Ry-derived and not provably |0>.
; LEAK: [[C2:%[a-z0-9_.]+]] = call i32 @cq_template_add_i32_hl(
; LEAK-NOT: call void @cqrt_free(i32 [[C2]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_hoisted_sum(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %7 = icmp sgt i32 %3, 0
  br i1 %7, label %8, label %18

8:                                                ; preds = %4
  %9 = add nsw i32 %5, %2
  br label %10

10:                                               ; preds = %10, %8
  %11 = phi i32 [ 0, %8 ], [ %15, %10 ]
  %12 = phi i32 [ %6, %8 ], [ %13, %10 ]
  %13 = xor i32 %12, 9
  %14 = icmp eq i32 %13, %9
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %3
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10, !llvm.loop !6

18:                                               ; preds = %10, %4
  %19 = phi i32 [ %6, %4 ], [ %13, %10 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

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
