; lowering_stale_speccall_reject_crossed_arg_captured_atomic.ll — DECLINE (bd
; test_C_libtooling-57ch.7, batch 053; owner rulings 2026-10-08 and 2026-10-13).
;
;   int *seen;
;   __attribute__((noinline)) void bump(int *p) { seen = p; __atomic_fetch_add(p, 1, __ATOMIC_SEQ_CST); seen = 0; }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int a = 0; bump(&a);             // CROSSED: bump publishes p before its atomic
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + a;
;   }
;
; The 2026-10-13 ruling admits an atomic in a callee on a NOCAPTURE pointer argument
; that points at a never-escaping caller local. Here `bump` stores the pointer to a
; global before its atomic, so the parameter is captured (`PointerMayBeCaptured`
; asked of the callee's own argument, never a call-site attribute) and the atomic
; may be visible outside: an observable ordered event, which gate code never
; crosses. The placement refuses and the stale fence declines.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept with a warning.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@seen = local_unnamed_addr global ptr null, align 8

define void @bump(ptr noundef %0) local_unnamed_addr #0 {
  store ptr %0, ptr @seen, align 8
  %2 = atomicrmw add ptr %0, i32 1 seq_cst, align 4
  store ptr null, ptr @seen, align 8
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
  %4 = call i32 @f(i32 noundef %2)
  %5 = call i32 @cq_measure_si32(i32 noundef %4) #6
  %6 = call i32 @cq_measure_si32(i32 noundef %3) #6
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

attributes #0 = { mustprogress nofree noinline norecurse nounwind willreturn memory(write, argmem: readwrite, inaccessiblemem: none) }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
