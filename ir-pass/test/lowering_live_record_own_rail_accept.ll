; lowering_live_record_own_rail_accept.ll — M-A clause 5, measured from C (bd
; test_C_libtooling-aako, 2026-10-05): a non-diagonal gate on the record's OWN
; rail, where no other rail records the value, is silent. Its neighbour, a gate
; on a rail that a DIFFERENT live rail records, still warns.
;
; THE QUESTION aako ASKED. The jttf re-spell saw this warning on
; lowering_loop_iter_local_temp.ll and control_classical_call_arm_accept_onward_phase.ll
; and read it as "the gate is on the record's own rail". MEASURED with a
; record-dump build of `warnLiveRecordRotations`, the record that trips each is a
; DIFFERENT rail from the gate's:
;   * iter_local_temp: the gate is `ry(t, .5)` on the `xor` rail; the record is
;     `q`'s `cqrt_alloc_i32` rail, the xor's parent, never observed. That is
;     lowering_reject_live_record_io_tape_chained_theta.ll's ruled canonical case.
;   * onward_phase: the gate is `ry(%out, .25)`; the records are `q`'s rail (which
;     determines %out through the merge flag) and the two `cqrt_alloc_i32(seed)`
;     copy sources. Only `q`'s rail is a real record (see that file's header).
; Both warnings name real dephasing in the emitted stream, and both files now pin it.
;
; WHY THE OWN RAIL IS ALREADY SILENT. Clause 5 (`RecordSet::push`, `V == Wire`)
; drops the wire by SSA identity, and at this late slot every name of the wire IS
; the one handle: an in-place `cq_theta` lowers to a void `cqrt_ry` and its result
; is replaced by the handle, so the -O1 header and exit phis of @own_rail_loop_carried
; (`%10 = phi [%11, latch], [%3, entry]`, the theta result routed as a new SSA
; name) are gone, and the one-register merge phi is lifted earlier (bd 5j5,
; lowering_reject_live_record_anc_router_phi.ll). So no own-rail exemption is
; needed in `recordIsExemptAt`: there is no case for it to decide.
;
; THE DISCRIMINATING PAIR is @parent_dead_inplace vs @parent_dead_loop, ONE C body:
;     int q = x; cq_theta(&q, 0.25); int t = q ^ 9; cq_theta(&t, 0.5);
; Straight-line, `q` is dead after the xor, so M-C lowers `t = q ^ 9` IN PLACE
; (`cqrt_xorc_i32(h, 9)`) and the gate on `t` is a gate on `q`'s own rail:
;     sum_a c_a |a>  -xorc->  sum_a c_a |a^9>  -ry->  coherent; no other rail.
; Silent. Inside the loop (iter_local_temp's body) M-C does not fire: the xor is the
; out-of-place `cq_template_xor_i32_hl`, the state at the gate is
;     sum_a c_a |a>_q |a^9>_t
; `q`'s rail is a basis record of `t`, so `t`'s reduced state is diagonal and the
; Ry acts on a mixture. That warning is correct about the stream. Whether the
; iteration-local loop should discharge `q` (M-B) or reassign in place (M-C) is a
; capability question, reported with aako, not settled here.
; @parent_observed is the out-of-place twin that is silent for the other reason:
; `q * 5` is measured after the gate, so `q`'s rail is the program's own data
; (clause 3).
;
; RETIREMENT TRIGGER (L7): if the record walk ever reaches the wire under a second
; SSA name (an unlifted one-register router, or an in-place gate that returns a
; fresh handle), @own_rail_loop_carried or @own_rail_chain will warn, and the fix
; is to build clause 5 on the wire closure (bd memory
; fence-the-wire-not-the-ssa-name), not to widen an exemption.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; int q = u; cq_theta(&q, 0.5); cq_theta(&q, 0.3); return 0;
define noundef i32 @own_rail_chain(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #0
  ret i32 0
}

; int q = u; cq_theta(&q, 0.5); for (i < n) cq_theta(&q, 0.3); return cq_measure(q);
define i32 @own_rail_loop_carried(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %8, label %5

5:
  %6 = phi i32 [ %3, %2 ], [ %11, %8 ]
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #1
  ret i32 %7

8:
  %9 = phi i32 [ %12, %8 ], [ 0, %2 ]
  %10 = phi i32 [ %11, %8 ], [ %3, %2 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 3.000000e-01) #0
  %12 = add nuw nsw i32 %9, 1
  %13 = icmp eq i32 %12, %1
  br i1 %13, label %5, label %8
}

; int q = x; cq_theta(&q, 0.25); int t = q ^ 9; cq_theta(&t, 0.5); return 0;
define noundef i32 @parent_dead_inplace(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #0
  %3 = xor i32 %2, 9
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #0
  ret i32 0
}

; ... the same, then return cq_measure(q * 5);
define i32 @parent_observed(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #0
  %3 = xor i32 %2, 9
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #0
  %5 = mul nsw i32 %2, 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #1
  ret i32 %6
}

; for (i < n) { int q = x; cq_theta(&q, 0.25); int t = q ^ 9; cq_theta(&t, 0.5); }
; (lowering_loop_iter_local_temp.ll's body, verbatim)
define void @parent_dead_loop(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %5, label %4

4:
  ret void

5:
  %6 = phi i32 [ %10, %5 ], [ 0, %2 ]
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #0
  %8 = xor i32 %7, 9
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #0
  %10 = add nuw nsw i32 %6, 1
  %11 = icmp eq i32 %10, %1
  br i1 %11, label %4, label %5
}

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }

; Two gates on the one rail, nothing else minted.
; CHECK-LABEL: define {{.*}}@own_rail_chain(
; CHECK-NEXT: %[[CH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[CH]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[CH]], double 3.000000e-01)

; The theta result's two phis collapse onto the handle: the in-loop gate and the
; exit measurement both name it.
; CHECK-LABEL: define {{.*}}@own_rail_loop_carried(
; CHECK-NEXT: %[[LH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[LH]], double 5.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[LH]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[LH]], double 3.000000e-01)

; M-C in place: the xor is `cqrt_xorc` on q's rail and the gate lands there too.
; CHECK-LABEL: define {{.*}}@parent_dead_inplace(
; CHECK-NEXT: %[[PH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PH]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[PH]], i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PH]], double 5.000000e-01)

; Out of place: q's rail stands at the gate and is read (then measured) after it.
; CHECK-LABEL: define {{.*}}@parent_observed(
; CHECK-NEXT: %[[OH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[OH]], double 2.500000e-01)
; CHECK-NEXT: %[[OT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[OH]], i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[OT]], double 5.000000e-01)
; CHECK-NEXT: %[[OM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[OH]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OM]])

; The loop body: out of place, so q's rail is a separate, dead record of t.
; CHECK-LABEL: define {{.*}}@parent_dead_loop(
; CHECK:      %[[DH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[DH]], double 2.500000e-01)
; CHECK-NEXT: %[[DT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[DH]], i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[DT]], double 5.000000e-01)

; Silent on the four own-rail / observed shapes; the loop body warns, once.
; WARN-NOT: in function own_rail_chain
; WARN-NOT: in function own_rail_loop_carried
; WARN-NOT: in function parent_dead_inplace
; WARN-NOT: in function parent_observed
; WARN:     warning: {{.*}}in function parent_dead_loop void (i32, i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning
