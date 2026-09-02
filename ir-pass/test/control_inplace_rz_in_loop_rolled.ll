; control_inplace_rz_in_loop_rolled.ll — the §6a Rz peephole INSIDE a
; classically-bounded loop, lowered ROLLED (bd test_C_libtooling-drbq Inc 2a over
; the bd 8h7d.5 in-loop path; control-in-place-PRD §12.2 lists the rolled loop in
; scope).
;
; `for (i = 0; i <= n; i++) if (q > 5) q = cq_phi(q, b);` — one physical register,
; one back edge, IR size independent of the trip count. The 8h7d.5 machinery is
; unchanged: `flatRegionRollableInLoop` narrows the d8jl decline,
; `collapseFlattenedLoopRails` collapses the loop-carried rail phi after the
; flatten, and the per-activation `provablyBefore` reading fences the record
; walks. What Inc 2a changes is only the five route lines inside the body.
;
; WHY THIS SHAPE NEEDED ITS OWN FIXTURE AND IS NOT COVERED BY THE DIAMOND. Inc 2a
; keeps the arm's `@cq_phi` ALIVE and moves it into the pred (hoist-and-defer),
; where the route re-minted a fresh gate on a work rail and ERASED the original.
; Inside a loop that is a structural difference, not a cosmetic one: the hoisted
; call is still in `taint.GateCalls` with the register at arg 0, so the round-2
; rail fan-out guard started counting the region's OWN arm gate as a SECOND
; in-place mutator of the rail and loudly rejected every rolled Grover in the
; tree (`kMsgRailFanout`, mirrored character-for-character below). `LoopLowering::isHoistedRegionArmGate` is the repair — it excludes exactly
; the gates the two in-place emitters recorded in `taint.ControlledRotations`, and
; nothing else. If that exclusion is deleted, THIS FILE goes red with
; `loop-carried rail has multiple in-place consumers`, not with a wrong stream.
;
; WHAT IS PINNED: the rolled CFG survives (a back edge and ONE copy of the body),
; the register is the SAME handle across the whole loop, and every ancilla — now
; just the flag — is minted, used, stripped and freed INSIDE the iteration, so
; nothing dirty crosses the back edge (Rule 6). The hand-unrolled twin's byte
; identity is checked at the e2e layer by the `cmp` twin gates and
; `tools/loop_twin_matrix.py`; this file is the IR-level pin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The route's ABSENCE. NO positive anchor, so the window is the whole module —
; not a dead trailing span (bd memory filecheck-check-not-window-trap).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exactly ONE flag mint and ONE controlled gate in the module: the body is emitted
; ROLLED, so a trip-count-proportional stream would trip these.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT2 < %t.cqd0.ll
; The pass must not have DECLINED — no diagnostic on stderr.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 >/dev/null \
; RUN:   | %filecheck %s --check-prefix=SILENT --allow-empty

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @rolled(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qm, %merge ]       ; loop-carried routed base
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]      ; classical induction
  %c1 = icmp sgt i32 %q, 5                             ; TAINTED condition
  br i1 %c1, label %mid, label %merge
mid:
  %g = call i32 @cq_phi_si32(i32 %q, double %b)        ; phase arm (Rz)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %q, %loop ]
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n                      ; classical loop bound
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; ONE register, minted before the loop
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; the classical induction phi survives; the RAIL phi does NOT (round-2 collapse)
; CHECK:     %{{.*}} = phi i32 [ 0, %entry ], [ %{{.*}}, %loop ]
; CHECK-NOT: phi i32 [ %[[H]]
; the body: mint, ONE controlled gate IN PLACE on the register, strip, free
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double %b)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; still a loop — one back edge, one stream
; CHECK:     br i1 %{{.*}}, label %{{.*}}, label %[[LOOP:[a-zA-Z0-9_.]+]]
; and the exit measure reads the SAME register
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])

; no swap route survives inside the body
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)

; ROLLED, not unrolled: exactly one mint and one controlled gate for any %n.
; CNT-COUNT-1:  = call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:      = call i32 @cq_template_icmp_sgt_i32_hl(
; CNT2-COUNT-1: call void @cqrt_rz_i32_controlled(
; CNT2-NOT:     call void @cqrt_rz_i32_controlled(

; the shapes this path used to decline as, and the fan-out guard's message —
; none of them may appear
; SILENT-NOT: under quantum control
; SILENT-NOT: control flow inside a loop body
; SILENT-NOT: loop-carried rail has multiple in-place consumers
; SILENT-NOT: error
