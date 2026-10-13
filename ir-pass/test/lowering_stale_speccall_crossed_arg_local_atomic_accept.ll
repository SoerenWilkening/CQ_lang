; lowering_stale_speccall_crossed_arg_local_atomic_accept.ll — ACCEPT (bd
; test_C_libtooling-57ch.7, batch 053; OWNER RULING 2026-10-13, bd memory
; owner-ruling-stale-reads-batch053-2026-10-13 item 2).
;
;   __attribute__((noinline)) void bump(int *p) { __atomic_fetch_add(p, 1, __ATOMIC_SEQ_CST); }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int a = 0; bump(&a);             // CROSSED: an atomic on main's never-escaping local
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + a;
;   }
;
; The atomic is in `bump`, on its parameter; `bump` does not capture it, and the
; pointer `main` passes is its local `a`, whose address never escapes `main`. The
; ruling: such an atomic is NOT an observable ordered event (the 2026-10-08
; function-local clarification applied at the call site), so the clone's gates may
; cross it (StaleReadPlacement.h clause (d), `localPointerArgs`). Before batch 053
; the walk of `bump`'s body met an atomic on an argument and refused. Decline twin
; (the callee publishes the pointer): lowering_stale_speccall_reject_crossed_arg_captured_atomic.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:.*]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call void @bump(ptr noundef nonnull
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define void @bump(ptr nocapture noundef %0) local_unnamed_addr #0 {
  %2 = atomicrmw add ptr %0, i32 1 seq_cst, align 4
  ret void
}

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #2 {
  %1 = alloca i32, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  call void @bump(ptr noundef nonnull %1)
  %4 = tail call i32 @f(i32 noundef %2)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #6
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #6
  %7 = add nsw i32 %6, %5
  %8 = load i32, ptr %1, align 4
  %9 = add nsw i32 %7, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 %9
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

attributes #0 = { mustprogress nofree noinline norecurse nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
