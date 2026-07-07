; lowering_reject_qram_guarded_store_two_arm.ll — DECLINE (g5gi boundary): TWO
; guarded stores in the SAME arm block —
;   if (q < 3) { arr[i] = 7; arr[j] = 8; }
; g5gi's "multi-store" widening is TWO SEPARATE guarded-store DIAMONDS sharing a
; block (each a depth-1 single-store diamond); it does NOT cover two stores in ONE
; arm. `soleSideEffectStore` rejects the second store, so the arm is not a
; side-effect-only single-store shape: `classifyGuardedStoreArm` returns
; NotApplicable and `recoverRegion` declines the tainted diamond generically
; (the arm has a store but no merge φ). Generalizing to a multi-store arm (one
; shared flag, N recorded guarded stores) is a separate widening; until then this
; declines LOUDLY (over-declining is safe — Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_arm(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %j = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %f = icmp slt i32 %q, 3
  br i1 %f, label %arm, label %merge

arm:
  %si = sext i32 %i to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %g, align 4
  %sj = sext i32 %j to i64
  %gj = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sj
  store i32 8, ptr %gj, align 4
  br label %merge

merge:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
