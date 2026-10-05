; control_guarded_store_ifelse_reject_trapping_op.ll — bd test_C_libtooling-dm7f.3
; DECLINE twin of control_guarded_store_ifelse_phase.ll: a classical op the source
; runs only inside one arm, and that may TRAP.
;
; SOURCE (shape of the clang -O1 IR, hand-trimmed; k and d are classical):
;     if (c < 3) { arr[q & 7] = k / d; cq_phi(0.25); }
;     else       { arr[(q ^ 5) & 7] = 9; }
;
; A classical computation cannot be conditioned on a quantum flag, so the flatten
; runs the arm's `sdiv` on EVERY branch: with d == 0 the compiled program traps on
; a path where the source never divided. Every UNTAINTED instruction of a composed
; region's arms must therefore be speculatable (`isSafeToSpeculativelyExecute`, the
; value arm's classical-cone condition fn1q K4); this one is not, and the region
; declines at it. (The shipped ONE-armed store-only region hoists its arm the same
; way and does not ask; that pre-existing gap is reported with dm7f.3.)
; PINS (written to kill, not mutation-run in dm7f.3): dropping the speculation clause from
; `classifyGuardedStoreArm`'s composed-region fences.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %u0, i32 %u1, i32 %k, i32 %d) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %c = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp slt i32 %c, 3
  %i = and i32 %q, 7
  br i1 %f, label %t, label %e

t:
  %v = sdiv i32 %k, %d
  %it = zext nneg i32 %i to i64
  %gt = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %it
  store i32 %v, ptr %gt, align 4
  call void @cq_phi(double 2.500000e-01)
  br label %m

e:
  %j = xor i32 %i, 5
  %ie = zext nneg i32 %j to i64
  %ge = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ie
  store i32 9, ptr %ge, align 4
  br label %m

m:
  ret i32 0
}
