; control_guarded_store_onearm_phase.ll — bd test_C_libtooling-dm7f.3 ACCEPT: a
; ONE-armed tainted diamond whose arm holds a guarded Shadow store AND a
; register-free `cq_phi` (the v2b shape).
;
; SOURCE (@main is the clang -O1 IR of this C, attributes, lifetime markers and
; TBAA trimmed):
;     int arr[8] = {0};
;     int c = argc + 1; cq_theta(&c, 0.5);
;     int q = argc + 2; cq_theta(&q, 0.5);
;     if (c < 3) { arr[q & 7] = 7; cq_phi(0.25); }
;     int p = argc + 3; cq_theta(&p, 0.5);
;     int v = arr[p & 7];
;     cq_theta(&c, -0.5);
;     return cq_measure(c) + cq_measure(q) + cq_measure(v);
; @negated (hand IR) takes the arm on the FALSE edge, as `clang -O1` does for
; `if (c >= 3) {} else {…}`-style conditions (Rule 9).
;
; WHAT WAS DECLINED. The taint-escape carve already deferred this one-armed store,
; but `classifyGuardedStoreArm` admitted only a STORE-only arm (the `cq_phi` call
; failed its purity gate) and the kickback classifier admits only a PHASE-only
; arm, so detection declined `control flow under quantum control` at the compare.
;
; THE STREAM (h = c's rail): f1 = icmp_slt(h,3); i = and(q,7);
; store_controlled(f1, A, i, 7); f2 = icmp_slt(h,3); rz_i1(f2,.25);
; icmp_slt_unc(f2,h,3); free(f2). The same emitter and argument as the if/else
; (control_guarded_store_ifelse_phase.ll): the store on its flag f1, the phase on
; its own ancilla f2, minted, kicked and stripped by the emitter, never on f1. In
; @negated the store's flag is the NEGATED mint (g5gi) and the phase's ancilla is
; cqrt_x-bracketed around the gate.
;
; DECLINE TWINS: as for control_guarded_store_ifelse_phase.ll.
;
; ⚠ THE `@main` HALF MOVED (bd test_C_libtooling-01po.25, batch 055) to
; control_guarded_store_onearm_phase_main.ll: since bd r2j3.7 `main` runs the helper's
; dead-record discipline and helper-parity copy-out, and that body now DECLINES.
; This file keeps the `@negated` subject, which still lowers.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll


; CHECK-LABEL: define i32 @negated(
; CHECK:      %[[NF1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %[[NC:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[NF1]],
; CHECK:      %[[NF2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[NC]], i32 3)
; CHECK-NEXT: call void @cqrt_x(i32 %[[NF2]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[NF2]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[NF2]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[NF2]], i32 %[[NC]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[NF2]])
; CHECK-NEXT: br label
; CHECK-NOT:  call void @cqrt_rz_i1(
; CHECK-NOT:  br i1


declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)


define i32 @negated(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %c = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp slt i32 %c, 3
  br i1 %f, label %m, label %arm

arm:
  %i = and i32 %q, 7
  %ix = zext nneg i32 %i to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ix
  store i32 7, ptr %g, align 4
  call void @cq_phi(double 2.500000e-01)
  br label %m

m:
  ret i32 0
}
