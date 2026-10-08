; control_classical_call_arm_flagproof_accept_popc_dbl.ll — ACCEPT (bd dm7f.21).
; A flag clang -O1 stamps BY CONSTRUCTION, which bwfp's dataflow counted as poison:
;   __attribute__((noinline)) double g(double v){ return v * 0.5; }
;   __attribute__((noinline)) int h(unsigned x){ return (int)g((double)__builtin_popcount(x)); }
;   int ex(unsigned k){ unsigned q = 0; cq_theta(&q, 0.0); unsigned y = q; if (q > 3) y = h(k); return cq_measure(y); }
; IR: clang 19 -O1 of exactly that C, target attributes trimmed (R8).
;
; The flag: `uitofp nneg i32 %2 to double` on the popcount. Its value reaches `@g`'s
; `noundef` parameter, so if the flag could fail the hoisted `@h` would execute
; immediate UB on a basis state the guard excluded. It cannot: `isKnownNonNegative` of
; the OPERAND `ctpop(%0)`: its known bits put the result in [0, 32], so the sign bit
; is clear. FlagProof.cpp proves each flag from facts about the flagged instruction's
; OPERANDS with `UseInstrInfo=false` and no context, never from the instruction itself
; (whose known bits already assume the flag). No poison reaches a sink, so the call is
; hoisted AS WRITTEN: no speculation-safe twin is minted (the NOTWIN prefix), exactly
; as e0af16ed lowered it before bwfp.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=NOTWIN %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @h(i32 noundef %0)
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],
; NOTWIN-NOT:  specsafe

define noundef double @g(double noundef %0) local_unnamed_addr #0 {
  %2 = fmul double %0, 5.000000e-01
  ret double %2
}

define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %0)
  %3 = uitofp nneg i32 %2 to double
  %4 = tail call double @g(double noundef %3)
  %5 = fptosi double %4 to i32
  ret i32 %5
}

declare i32 @llvm.ctpop.i32(i32) #1

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
