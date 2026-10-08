; control_predmux_strict_reject_ownflag_nneg.ll — DECLINE (bd dm7f.20).
; The mutant-killing row for the PredMux strict path's flag proof (bd dm7f.20): never
; route an instruction's own flag through itself. control_predmux_strict_accept_popc.ll's
; clang -O1 module with `@h`'s body replaced by `zext nneg (trunc %0 to i8)`: the
; byte is UNCONSTRAINED, so the `nneg` fails for k & 0x80, the result is poison and
; `h` is not total. The proof must ask about the OPERAND (`isKnownNonNegative` of the
; trunc knows nothing) and decline. Asking about the zext itself (always
; non-negative) would "prove" the flag and speculate a poison condition.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function ex i32 (i32): cq controlled lowering: control flow under quantum control

define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = trunc i32 %0 to i8
  %3 = zext nneg i8 %2 to i32
  ret i32 %3
}

declare i32 @llvm.ctpop.i32(i32) #1

define i32 @ex(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %11

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  %6 = icmp eq i32 %5, 2
  br i1 %6, label %7, label %9

7:                                                ; preds = %4
  %8 = sub nsw i32 %2, %0
  br label %11

9:                                                ; preds = %4
  %10 = add nsw i32 %2, %0
  br label %11

11:                                               ; preds = %7, %9, %1
  %12 = phi i32 [ %8, %7 ], [ %10, %9 ], [ %2, %1 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
