; lowering_stale_speccall_reject_call_between.ll — DECLINE (bd test_C_libtooling-r2j3.6):
; a stale lifted call with a call that may NOT RETURN between its staling gate and it.
;
;   #include <stdio.h>
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     puts("x");                       // not `willreturn`
;     int r = f(q);                    // reads the PRE-Ry record
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; Placing `f(q)` above `puts` would run the lifted call (and emit its gates) on a
; trace where `puts` never returns and the source never reaches it, so the 57ch (A)
; placement refuses (StaleReadPlacement.h clause (d): every instruction it moves
; above must return normally, asked with `isGuaranteedToTransferExecutionToSuccessor`)
; and the stale fence declines. LLVM cannot prove `puts` returns; that makes this
; refusal conservative, an OVER-DECLINE under NORTHSTAR goal 1 kept loud.
; RETIREMENT TRIGGER (L7): a placement that may cross a call LLVM cannot prove
; returns (e.g. by knowing the C library's contract) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

@.str = private unnamed_addr constant [2 x i8] c"x\00", align 1

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  %4 = tail call i32 @f(i32 noundef %1)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
attributes #4 = { nofree nounwind }
