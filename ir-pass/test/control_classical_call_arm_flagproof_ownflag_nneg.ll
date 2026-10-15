; control_classical_call_arm_flagproof_ownflag_nneg.ll — ACCEPT, AS A TWIN (bd dm7f.21).
; The mutant-killing row for the flag proof's one rule: never route an
; instruction's own flag through itself.
;
; control_classical_call_arm_flagproof_accept_clzg8.ll's clang -O1 module with the
; 8-bit ctlz removed, so the `zext nneg i8 %2 to i32` reads `trunc i32 %0 to i8`
; directly: an UNCONSTRAINED byte. The `nneg` is then false for k & 0x80, the zext is
; poison, and the poison reaches `@g`'s `noundef` parameter. The flag proof must
; FAIL here (`isKnownNonNegative` of the OPERAND `%2` knows nothing), so `@h` is
; hoisted as its speculation-safe twin with that argument frozen. A proof that asked
; about the zext itself (`isKnownNonNegative(&I)`: a zext result is always
; non-negative) "proves" the flag, mints no twin, and hoists `g(poison)` (immediate
; UB) out of a zero-amplitude guard: that mutant fails the twin CHECKs below.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK:       call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[R]])
; CHECK:       define internal noundef i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK-NEXT:    %2 = trunc i32 %0 to i8
; CHECK-NEXT:    %3 = zext nneg i8 %2 to i32
; CHECK-NEXT:    %.fr = freeze i32 %3
; CHECK-NEXT:    %4 = tail call i32 @g(i32 noundef %.fr)
; CHECK-NEXT:    ret i32 %4

define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define noundef i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = trunc i32 %0 to i8
  %3 = zext nneg i8 %2 to i32
  %4 = tail call i32 @g(i32 noundef %3)
  ret i32 %4
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_ui32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp ugt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
