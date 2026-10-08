; control_predmux_strict_accept_inl_add.ll — ACCEPT (bd dm7f.20).
; An inlined `+1u` helper the PredMux strict classical-call path declined (bd dm7f.20):
;   unsigned lo(unsigned x){ return x & 255u; }
;   __attribute__((noinline)) int h(int x){ return (int)(lo((unsigned)x) + 1u); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.5); int y = q; if (q > 3) { if (h(k) == 2) y = q - k; else y = q + k; } return cq_measure(y); }
; IR: clang 19 -O1 of exactly that C, target attributes trimmed (R8).
;
; Measured causes, two: (1) `add nuw nsw i32 (x & 255), 1`: `totalCall` asked
; `canCreateUndefOrPoison(I)` with flags on, which counts both flags as poison. Both
; hold by construction: the operand `and %0, 255` is at most 255, so neither wrap can
; happen. `createsPoison` proves each flag from the OPERANDS with flags off
; (`computeOverflowForUnsignedAdd`/`SignedAdd`), never from the add itself. (2) the
; clang-stamped `range(i32 1, 257)` on `@h` (CQ_PREDMUX_DBG: "classical call return
; range unproven @h"): `computeConstantRange` does no arithmetic for `add` and known
; bits give [0, 511]. `rangeProven` now composes LLVM's `ConstantRange` transfer
; functions over the operands ([0, 256) + 1 = [1, 257), `overflowingBinaryOp` under
; the `nuw` only because every flag in the cone is proven, `coneFlagsProven`).
; Decline twin: control_predmux_strict_reject_range_narrow.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @h(i32 noundef %0)
; CHECK:       icmp {{eq|ne}} i32 %[[R]], 2
; CHECK:       call i32 @cq_template_and_i1_hl(
; CHECK:       call void @cqrt_copy_i32_controlled(

define noundef range(i32 0, 256) i32 @lo(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 255
  ret i32 %2
}

define range(i32 1, 257) i32 @h(i32 noundef %0) local_unnamed_addr #1 {
  %2 = and i32 %0, 255
  %3 = add nuw nsw i32 %2, 1
  ret i32 %3
}

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

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
