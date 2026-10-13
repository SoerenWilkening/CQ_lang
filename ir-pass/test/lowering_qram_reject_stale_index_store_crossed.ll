; lowering_qram_reject_stale_index_store_crossed.ll — DECLINE (bd
; test_C_libtooling-57ch.3, batch 053): a stale QRAM LOAD that would have to cross
; a store to the same local array is not placed.
;
;   int main(void) {
;     int arr[8] = {0};
;     long s = 0L; cq_theta(&s, .9); long j = s & 7;
;     long q = 0L; cq_theta(&q, .5);
;     long q2 = q; cq_theta(&q2, .3);
;     arr[j] = 5;                      // a store to the array the stale load reads
;     return (int)cq_measure(arr[q]) + (int)cq_measure(q2);   // bare index
;   }
;
; Since 57ch.3 a stale QRAM access is placed before its staling gate (accept twins:
; the lowering_qram_reject_stale_index_*.ll family, whose verdicts that change
; inverted). Here the load of `arr[q]` would move above the store `arr[j] = 5`:
; the array-order rule of 57ch (A) (StaleReadPlacement.h clause (e): a reading
; instruction crosses no write) refuses, since the load must see the store. The
; read needs the pre-gate label of `q` AFTER the store, which is 57ch (B).
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept with a warning.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %1, i8 0, i64 32, i1 false)
  %2 = tail call i64 @cq_theta_sl(i64 noundef 0, double noundef 9.000000e-01) #5
  %3 = and i64 %2, 7
  %4 = tail call i64 @cq_theta_sl(i64 noundef 0, double noundef 5.000000e-01) #5
  %5 = tail call i64 @cq_theta_sl(i64 noundef %4, double noundef 3.000000e-01) #5
  %6 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %3
  store i32 5, ptr %6, align 4
  %7 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %4
  %8 = load i32, ptr %7, align 4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  %10 = tail call i64 @cq_measure_sl(i64 noundef %5) #4
  %11 = trunc i64 %10 to i32
  %12 = add nsw i32 %9, %11
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %1) #4
  ret i32 %12
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }
