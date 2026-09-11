; lowering_reject_guarded_store_cmp_blind_staler.ll — DECLINE (Track A.1, Rule-13
; ROUND-2 finding F-A1R2-1). The SECOND of the two CONFIRMED silent miscompiles,
; at the 7.5 GUARDED SHADOW STORE, PRE-EXISTING on `main` 0c7380c, plain
; `clang -O1` C, single TU:
;
;     static int guarded_local(int seed) {     /* review_a1_r2_probes/gs1.c */
;       int arr[8] = {0};
;       int q  = cq_theta(seed, 0.5);
;       int q2 = cq_theta(q, 0.9);             /* staler ON q's WIRE */
;       int i  = cq_theta(seed + 1, 0.5);
;       if (q < 3) { arr[i] = 7; }             /* the guarded Shadow store */
;       int v = arr[q2];
;       return cq_measure(v);
;     }
;
; WHAT `main` EMITTED (rc 0, verify-clean, STRICT stage 2b `0 violation(s)`):
;     cqrt_ry_i32(%h, 0.5) ; cqrt_ry_i32(%h, 0.9)
;     %h_cmp = cq_template_icmp_slt_i32_hl(%h, 3)      ; THE FLAG, post-Ry
;     cqrt_qram_store_i32_controlled(%h_cmp, ...)
; The source guards on `Ry(0.5)|x>`; the circuit guards on `Ry(1.4)|x>`, so the
; controlled store commits on a different set of amplitudes (Rule 2).
;
; SAME CAUSE AS THE I/O SINK's, one consumer over: `classifyGuardedStoreArm` is a
; PRE-PEEL that pushes its region and returns BEFORE the generic `recoverRegion`
; path ever reaches `condWireDisposition`, and `GuardedStoreArmEmit.cpp` contains
; no wire walk of its own (MEASURED). Its mint now records
; `CondReadKind::Unruled`, so `reverifyCmpCondReads` exempts nothing for it and
; rung (iii) refuses the sibling Ry that precedes the mint.
;
; ACCEPT CONTROL: `lowering_guarded_store_cmp_other_register_staler.ll` (probe
; `gs3.c`) — the same shape with the staler on a register the guard does not
; name, GREEN on all three binaries. RED-GREEN: the ORACLE and the pre-round-2
; checkpoint b439944 both return rc 0 on this module.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @guarded_local() {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %arr, i8 0, i64 32, i1 false)
  %q  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %i  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %c  = icmp slt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %si = sext i32 %i to i64
  %sp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %sp, align 4
  br label %merge

merge:                                            ; preds = %arm, %entry
  %li = sext i32 %q2 to i64
  %lp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %li
  %v  = load i32, ptr %lp, align 4
  %m  = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
