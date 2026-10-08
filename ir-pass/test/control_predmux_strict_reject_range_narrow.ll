; control_predmux_strict_reject_range_narrow.ll — DECLINE (bd dm7f.20).
; The decline twin of control_predmux_strict_accept_inl_add.ll (bd dm7f.20): the
; same clang -O1 module with `@h`'s `range(i32 1, 257)` narrowed to
; `range(i32 1, 256)`. `(x & 255) + 1` reaches 256, where the narrowed range
; makes the result POISON, so `h` is not total. The composed range proof
; (`composedRange`: [0, 256) + 1 = [1, 257) under the proven `nuw`) must not
; prove the narrowed range, and the strict path keeps refusing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function ex i32 (i32): cq controlled lowering: control flow under quantum control

define noundef range(i32 0, 256) i32 @lo(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 255
  ret i32 %2
}

define range(i32 1, 256) i32 @h(i32 noundef %0) local_unnamed_addr #1 {
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
