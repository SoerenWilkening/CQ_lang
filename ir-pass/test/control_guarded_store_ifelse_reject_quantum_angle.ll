; control_guarded_store_ifelse_reject_quantum_angle.ll — bd test_C_libtooling-dm7f.3
; DECLINE twin of control_guarded_store_ifelse_phase.ll: a QUANTUM-derived phase
; angle in a guarded-store region.
;
; SOURCE (shape, hand IR):
;     if (c < 3) { arr[q & 7] = 7; cq_phi((double)q); }
;     else       { arr[(q ^ 5) & 7] = 9; }
;
; Rule 3: a rotation angle is classical today; a quantum-derived one must lower as
; an angle register driving a bit-controlled ladder (bd 94ad) and until then fails
; loudly. `classifyGuardedStoreArm` refuses it with the string and at the gate
; `classifyPhaseKickback` uses for a phase-only arm. Without the clause the region
; would hand `emitKickbackGroup` the tainted `sitofp` as `cqrt_rz_i1`'s angle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %c = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp slt i32 %c, 3
  %i = and i32 %q, 7
  br i1 %f, label %t, label %e

t:
  %it = zext nneg i32 %i to i64
  %gt = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %it
  store i32 7, ptr %gt, align 4
  %ang = sitofp i32 %q to double
  call void @cq_phi(double %ang)
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
