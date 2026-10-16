; control_guarded_store_ifelse_phase.ll — bd test_C_libtooling-dm7f.3 ACCEPT: a
; tainted if/else with a guarded Shadow store in EACH arm and a register-free
; `cq_phi` in one arm.
;
; SOURCE (@main is the clang -O1 IR of this C, attributes, lifetime markers and
; TBAA trimmed):
;     int arr[8] = {0};
;     int c = argc + 1; cq_theta(&c, 0.5);
;     int q = argc + 2; cq_theta(&q, 0.5);
;     if (c < 3) { arr[q & 7] = 7; cq_phi(0.25); }
;     else       { arr[(q ^ 5) & 7] = 9; }
;     int p = argc + 3; cq_theta(&p, 0.5);
;     int v = arr[p & 7];
;     cq_theta(&c, -0.5);
;     return cq_measure(c) + cq_measure(q) + cq_measure(v);
; @phase_else is the same region with the phase in the ELSE arm (hand IR).
;
; WHAT WAS DECLINED. The taint-escape carve deferred a guarded store only in a
; ONE-armed diamond (`guardedShadowStoreShapeImpl` (b)), so the true arm's gep
; declined `cq taint escape: tainted value reaches an unsupported instruction`;
; and `classifyGuardedStoreArm` admitted neither an if/else nor a `cq_phi` beside
; a store.
;
; THE STREAM (h = c's rail, i = q & 7, A = the array):
;   f1 = icmp_slt(h,3);  store_controlled(f1, A, i, 7)
;   f3 = icmp_sge(h,3);  j = xor(i,5);  store_controlled(f3, A, j, 9)
;   f2 = icmp_slt(h,3);  rz_i1(f2, .25);  icmp_slt_unc(f2,h,3);  free(f2)
; THE ARGUMENT. With the state Σ_x a_x |x>_h |…>:
;   * f1 = [x<3] and f3 = [x>=3] are minted from the PRE-store h; a guarded store
;     is a no-op on its cell when its flag is 0, so exactly one store fires per
;     basis branch, the true arm's on x<3 and the else arm's on x>=3. f3 is a
;     NEGATED MINT, not `cqrt_x` around f1: the spine strips f3 with its own
;     `icmp_sge_unc` (and would reverse its store through it), so f3 must DENOTE
;     the else predicate.
;   * f2 is a fresh |0> ancilla: rz_i1 puts e^{iθ[x<3]} on the branch (a global
;     phase aside), and the strip returns f2 to |0> on every branch because no gate
;     between the mint and the strip writes h (the stores write A only). The phase
;     NEVER rides f1/f3: a branch-phase gate is an opaque consumer to the uncompute
;     spine (`ChainWalk.h`), which would leave that flag unstripped — a live copy of
;     [x<3] across the later Ry(-0.5) on h, dephasing it.
;   * both store flags are stripped (the r2j3.1 interior partition) BEFORE the
;     later Ry(-0.5) on h, so no record of h's basis survives across it.
;   * @phase_else: the else arm fires on ¬f2, so the gate is cqrt_x-bracketed on
;     the ancilla (`emitKickbackGroup`, the one spelling).
;
; MUTANTS this file kills (measured, dm7f.3): M1, the phase riding the true arm's
; STORE flag (no fresh f2, no emitter strip) — the hazard above; M2, the else
; arm's store flag minted un-negated (`icmp_slt` where `icmp_sge` is owed).
;
; DECLINE TWINS: control_guarded_store_ifelse_reject_quantum_value.ll (a quantum
; stored value in a composed region, bd r2j3.9's path),
; control_guarded_store_ifelse_reject_trapping_op.ll (a trapping classical op the
; flatten would run on every branch), …_reject_quantum_angle.ll (Rule 3),
; control_guarded_store_reject_round2_{angle,value}.ll (L1: classical at round 1,
; quantum after round 2). The original reproducer WITH its later Ry on q accepts:
; control_guarded_store_ifelse_phase_full_repro.ll, and so does its in-arm index
; neighbour, control_guarded_store_ifelse_inarm_index_later_ry.ll (bd 01po.7).
;
; ⚠ THE `@main` HALF MOVED (bd test_C_libtooling-01po.25, batch 055) to
; control_guarded_store_ifelse_phase_main.ll: since bd r2j3.7 `main` runs the helper's
; dead-record discipline and helper-parity copy-out, and that body now DECLINES.
; This file keeps the `@phase_else` subject, which still lowers.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll


; ---- @phase_else: the else arm's phase fires on ¬f2 — the cqrt_x bracket on the
; ANCILLA f2, enclosing only the gate.
; CHECK-LABEL: define i32 @phase_else(
; CHECK:      %[[EF1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[EC:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[EF1]],
; CHECK:      %[[EF3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %[[EC]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[EF3]],
; CHECK:      %[[EF2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[EC]], i32 3)
; CHECK-NEXT: call void @cqrt_x(i32 %[[EF2]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[EF2]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[EF2]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[EF2]], i32 %[[EC]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[EF2]])
; CHECK-NEXT: br label


; ---- Per function: ONE phase gate, three condition mints, no raw control left,
; (the @main half of this block moved with @main, 01po.25).
; CNT-LABEL:   define i32 @phase_else(
; CNT-COUNT-1: call void @cqrt_rz_i1(
; CNT-NOT:     call void @cqrt_rz_i1(
; CNT-NOT:     br i1
; CNT-NOT:     call void @cq_phi(

; ---- The phase gate carries the branch-phase membership record.
; MDTAG: call void @cqrt_rz_i1({{.*}}), !cq.branchphase

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)


define i32 @phase_else(i32 %u0, i32 %u1) {
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
  br label %m

e:
  %j = xor i32 %i, 5
  %ie = zext nneg i32 %j to i64
  %ge = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ie
  store i32 9, ptr %ge, align 4
  call void @cq_phi(double 2.500000e-01)
  br label %m

m:
  ret i32 0
}
