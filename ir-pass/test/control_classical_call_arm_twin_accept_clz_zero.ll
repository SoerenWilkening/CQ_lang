; control_classical_call_arm_twin_accept_clz_zero.ll — ACCEPT (bd dm7f.21).
; `__builtin_clz(x)` with x possibly 0, its poison reaching a `noundef` sink:
;   __attribute__((noinline)) int g(int v){ return v ^ 5; }
;   __attribute__((noinline)) int h(unsigned x){ return g(__builtin_clz(x)); }
;   int ex(unsigned k){ unsigned q = 0; cq_theta(&q, 0.0); unsigned y = q; if (q > 3) y = h(k); return cq_measure(y); }
; IR: clang 19 -O1 of exactly that C, target attributes trimmed (R8).
;
; `ctlz(x, is_zero_poison=true)` is poison for x = 0, and no operand fact proves x
; non-zero, so the flag proof (FlagProof.cpp) leaves it a poison source; it reaches
; `@g`'s `noundef` parameter. The dm7f.21 brief asked for a decline here if the
; poison reached a sink a `freeze` cannot discharge. It does not: the only sink is
; a call argument, and after the twin no non-freezable sink is reachable from C
; (a divisor or pointer needs a non-constant divisor or a memory op, both refused by
; the strict body walk before the twin is asked; a value-constraining scalar
; parameter attribute has no C spelling). So it ACCEPTS, and that is sound
; (ANALYTIC, R2): for k != 0 the `freeze` is the identity and the twin returns
; `h(k)`; for k = 0 under a true guard the source executes `g(poison)`, immediate UB,
; so it has no behaviour to preserve; under a false guard the twin's arbitrary
; defined value is never merged (the controlled copy is the identity there).
; Decline neighbour (a contract no twin edit sheds):
; control_classical_call_arm_twin_reject_decl_own_noundef_range.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],
; CHECK:       define internal noundef i32 @__cq_specsafe_h(i32 noundef %0) unnamed_addr #0 !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %2 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %0, i1 true)
; CHECK-NEXT:    %.fr = freeze i32 %2
; CHECK-NEXT:    %3 = tail call i32 @g(i32 noundef %.fr)
; CHECK-NEXT:    ret i32 %3
; CHECK:       ![[TW]] = !{ptr @h}

define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define noundef i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %0, i1 true)
  %3 = tail call i32 @g(i32 noundef %2)
  ret i32 %3
}

declare i32 @llvm.ctlz.i32(i32, i1 immarg) #1

define i32 @ex(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @cq_theta_ui32(i32 noundef 0, double noundef 0.000000e+00) #3
  %3 = icmp ugt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #4
  ret i32 %8
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
