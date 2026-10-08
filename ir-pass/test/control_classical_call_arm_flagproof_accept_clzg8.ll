; control_classical_call_arm_flagproof_accept_clzg8.ll — ACCEPT (bd dm7f.21).
; A flag clang -O1 stamps BY CONSTRUCTION, which bwfp's dataflow counted as poison:
;   __attribute__((noinline)) int g(int v){ return v ^ 5; }
;   __attribute__((noinline)) int h(unsigned x){ return g(__builtin_clzg((unsigned char)x, 8)); }
;   int ex(unsigned k){ unsigned q = 0; cq_theta(&q, 0.0); unsigned y = q; if (q > 3) y = h(k); return cq_measure(y); }
; IR: clang 19 -O1 of exactly that C, target attributes trimmed (R8).
;
; The flag: `zext nneg i8 %3 to i32` on an 8-bit ctlz. Its value reaches `@g`'s
; `noundef` parameter, so if the flag could fail the hoisted `@h` would execute
; immediate UB on a basis state the guard excluded. It cannot: `isKnownNonNegative` of
; the OPERAND `ctlz.i8(%2, false)` (at most 8: bit 7 known zero); the ctlz's poison
; immarg is `false`, so it is total. FlagProof.cpp proves each flag from facts about
; the flagged instruction's OPERANDS with `UseInstrInfo=false` and no context, never
; from the instruction itself (whose known bits already assume the flag). No poison
; reaches a sink, so the call is hoisted AS WRITTEN: no speculation-safe twin is
; minted (the NOTWIN prefix), exactly as e0af16ed lowered it before bwfp.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=NOTWIN %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @h(i32 noundef %0)
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],
; NOTWIN-NOT:  specsafe

define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define noundef i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = trunc i32 %0 to i8
  %3 = tail call range(i8 0, 9) i8 @llvm.ctlz.i8(i8 %2, i1 false)
  %4 = zext nneg i8 %3 to i32
  %5 = tail call i32 @g(i32 noundef %4)
  ret i32 %5
}

declare i8 @llvm.ctlz.i8(i8, i1 immarg) #1

define i32 @ex(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @cq_theta_ui32(i32 noundef 0, double noundef 0.000000e+00) #4
  %3 = icmp ugt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #5
  ret i32 %8
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
