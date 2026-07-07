; lowering_reject_qram_guarded_store_side_effect.ll — DECLINE (iw81.7, Rule-13 [C1]):
; a guarded-store arm carrying a SECOND side effect besides the recognized
; `arr[i] = v` — here an `atomicrmw` (a `counter++` on a classical global). The
; flatten splices the WHOLE arm body into Pred and rewires unconditionally, so an
; un-declined atomic/fence would fire on BOTH branches (a classical side effect on
; the wrong branch — trace-invisible, the canonical silent miscompile). The arm must
; be SIDE-EFFECT-ONLY (exactly the one Shadow store); any other side-effecting op
; (`atomicrmw`/`cmpxchg`/`fence`/volatile/`mayHaveSideEffects`) declines LOUDLY. The
; atomic reads no tainted value, so `declineTaintEscapes` does NOT catch it — the
; `soleSideEffectStore` purity gate is the load-bearing fence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@counter = global i32 0, align 4

define i32 @side_effect(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp sgt i32 %q, 5
  br i1 %f, label %arm, label %merge

arm:
  %old = atomicrmw add ptr @counter, i32 1 seq_cst   ; a SECOND side effect (counter++)
  %si = sext i32 %i to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %g, align 4
  br label %merge

merge:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: cq controlled lowering: {{.*}}under quantum control
