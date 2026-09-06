; lowering_reject_inplace_rail_stale_w2_xor_commuted_handir.ll — DECLINE. bd
; test_C_libtooling-eqpx (P1). THE WORST FORM OF THE SAME DEFECT: with the
; operands COMMUTED the emitted gate mutates THE WRONG REGISTER, and the source's
; own `cq_measure` then measures a register the program never wrote.
;
; ⚠ HAND IR, AND THE HEADER SAYS SO. This is `..._w2_xor_derived.ll`'s module with
; ONE operand order swapped (`%19 = xor i32 %18, %9` -> `%19 = xor i32 %9, %18`)
; and nothing else. THREE plain-C spellings were tried by the eqpx investigation
; (`n19_xor_commuted_src.c`, `n20_xor_commuted_add1.c`, `n21_xor_commuted_nonphi.c`)
; and LLVM 19 `clang -O1` canonicalizes the phi-carried operand back to the LHS in
; every one, so the wrong-REGISTER half is HAND-IR-ONLY AS MEASURED. (Those three
; DO reach the wrong-IMMEDIATE half from plain C, and are covered by the plain-C
; fixtures in this family.) It is committed because operand order is not a fence:
; `inPlaceValueRailOperand` returns `TL ? L : R`, and `rewriteInPlaceValueRail`
; re-derives the same pick at Phase 2 — so the moment the immediate turns tainted,
; WHICH register gets mutated is decided by a `Tainted.count(L)` that answers
; about the wrong value.
;
; MEASURED on frozen `main`@16b15b3 (byte-identical on the oracle 52d7764):
;     call void @cqrt_xorc_i32(i32 %h_op, i32 %h2)
;                                   ^^^^^^ the `and` RAIL is mutated in place
;                                            ^^^^ and `r`'s register is the "immediate"
; trace `cqrt_xorc_i32(h6, 1)` x3 and then `cqrt_measure_i32(h6)` — the source's
; `cq_measure(r)` measures the `and` rail; `r`'s own register is never touched.
; `opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s)`, 21 trace lines.
;
; G2 under FINAL taint answers this one for the same reason it answers the others:
; BOTH operands are tainted by then, `TL == TR`, and `inPlaceValueRailOperand`
; returns null.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: in-place rail op no longer provable at lowering

; CHECK-NOT: cqrt_xorc_i32
; CHECK-NOT: cq_template_xor_i32

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  %9 = and i32 %8, 7
  br label %16

10:                                               ; preds = %16
  %11 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %15 = add nsw i32 %13, %14
  ret i32 %15

16:                                               ; preds = %16, %7
  %17 = phi i32 [ 0, %7 ], [ %20, %16 ]
  %18 = phi i32 [ %3, %7 ], [ %19, %16 ]
  %19 = xor i32 %9, %18
  %20 = add nuw nsw i32 %17, 1
  %21 = icmp eq i32 %20, 3
  br i1 %21, label %10, label %16, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
