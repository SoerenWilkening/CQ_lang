; control_predmux_strict_reject_abs.ll — DECLINE (bd dm7f.20).
; `abs` stays declined on the PredMux strict path (bd dm7f.20), and it is not a
; precision gap: clang 19 -O1 of exactly
;   __attribute__((noinline)) int h(int x){ return x < 0 ? -x : x; }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.5); int y = q; if (q > 3) { if (h(k) == 2) y = q - k; else y = q + k; } return cq_measure(y); }
; (target attributes trimmed) is `llvm.abs.i32(%0, i1 true)`: INT_MIN is POISON,
; and nothing constrains `k`, so `h` is not total and `classicalCallCanBeSpeculated`
; (every defined input gives a defined result) is false by its own definition. The
; 6.5 arm accepts the same call because it never merges a poison result on a
; shielded state; PredMux feeds the result into a flattened select condition.
; HONEST SCOPE: an interim decline (R1). Executing `abs(INT_MIN)` is not UB, so a
; PredMux hoist that freezes the speculated result (one stable freeze shared by the
; forward and inverse uses, p3kd.7.7) would lower it; filed as a dm7f.20 follow-up.
; Retire this row when that lands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function ex i32 (i32): cq controlled lowering: control flow under quantum control

define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @llvm.abs.i32(i32 %0, i1 true)
  ret i32 %2
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
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

declare i32 @llvm.abs.i32(i32, i1 immarg) #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
