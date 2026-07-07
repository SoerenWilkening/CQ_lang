; lowering_reject_qram_guarded_store_swapped.ll — DECLINE (iw81.7): a guarded Shadow
; store whose arm is the FALSE successor of the branch (`clang -O1` swaps the
; successors for `if (q != 3)` → `icmp eq; br eq, Merge, Arm`, Rule 9). The store then
; fires on ¬flag, which needs the flag brackets threaded through the guarded
; `_controlled_unc` — a safe additive follow-on NOT in the v1 accept shape. v1 accepts
; ONLY the un-negated (TRUE-successor) store arm; the swapped arm declines LOUDLY
; (over-declining is safe — Prime Directive). The store is a genuine GuardedStoreArm
; shape (so the recognizer OWNS it and declines precisely, never a silent skip).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @swapped(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp eq i32 %q, 3
  br i1 %f, label %merge, label %arm              ; store arm is the FALSE successor

arm:
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

; CHECK: cq controlled lowering: guarded store on a swapped branch under quantum control
