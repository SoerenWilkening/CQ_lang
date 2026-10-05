; control_guarded_store_ifelse_reject_quantum_value.ll — bd test_C_libtooling-dm7f.3
; DECLINE twin of control_guarded_store_ifelse_phase.ll: a QUANTUM stored value in
; a composed guarded-store region.
;
; SOURCE (shape of the clang -O1 IR, hand-trimmed):
;     if (c < 3) { arr[q & 7] = q; cq_phi(0.25); }
;     else       { arr[(q ^ 5) & 7] = 9; }
;
; The flatten hoists each arm's body into the pred and runs it on EVERY branch;
; for a tainted stored value that body includes the value's chain, and nothing
; discharges it after the guarded store (bd r2j3.9: a live copy of q on branches
; where the source made no record, a latent silent miscompile masked today only
; by the stale-record guard). The one-armed store-only region keeps that
; pre-existing path unchanged; a COMPOSED region (an if/else, or a phase beside
; the store) refuses it so dm7f.3 adds no customers to it (L9).
; RETIREMENT TRIGGER: lift the clause, and turn this file into an accept, in the
; change that closes r2j3.9.
; PINS (written to kill, not mutation-run in dm7f.3): dropping the quantum-value clause from
; `classifyGuardedStoreArm`'s composed-region fences.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: guarded store of a quantum value in a composed region under quantum control

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
  store i32 %q, ptr %gt, align 4
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
