; carried_fence_inloop.ll — cq-merge-selftest input (NOT a lit test: `Inputs/`
; is excluded; ctest `ir-pass-merge-discharge-selftest` runs it). bd
; test_C_libtooling-r2j3.36: the carried-merge fence (MergeCarriedFence.h)
; used to look only AFTER the loop exit, so a non-diagonal gate INSIDE the
; loop on a register already entangled with a leaked carried merge rail
; (this trip's, after its merge writes, or an earlier trip's, across the back
; edge) passed. Every C spelling of the `_loud` shapes is declined upstream
; today (`rail bank: written from more than one store site`, `cell walk
; re-executed by an enclosing loop`, the control / stale fences; reviewer
; probes revU7 pA–pE, 2026-10-15); 01po.19 S4–S7 remove the first two, so this
; driver is the only place the in-loop fence can be pinned.
;
; The loud shapes (reviewer probe in brackets):
;   * pa_bank_cell_ry_loud     [pA] the shipped rolled slice, plus a Ry on the
;                              bank cell b0[0] (a LOAD: never fresh) every trip
;                              after the merge;
;   * pb_cond_inloop_ry_loud   [pB] a Ry on the condition register inside the
;                              loop, after the merge that records it;
;   * pc_rail_inloop_ry_loud   [pC] per-trip fresh condition; a Ry on the merge
;                              rail itself after its writes;
;   * pd_phi_top_ry_loud       [pD] a Ry on the carried φ at the TOP of the
;                              trip, before this trip's merge: only the back
;                              edge carries the earlier trip's record there;
;   * pe_nested_cell_loud      [pE] the slice in an outer loop: the inner
;                              trip's controlled Ry targets the re-read bank
;                              cell (a load), which the first outer trip's
;                              merges recorded;
;   * fresh_coupled_ry_loud    a per-trip fresh register CNOT-coupled to the
;                              carried φ and THEN rotated in the same trip;
;   * backedge_fresh_ry_loud   a register allocated before the loop, rotated
;                              at the top of each trip and coupled to the
;                              carried φ later in the trip: from trip 2 on the
;                              Ry acts on an entangled register (only the back
;                              edge sees the coupling).
; The quiet controls (no over-decline):
;   * slice_kept               the shipped lowering of
;                              slice_control_cascade_loop_carried_handle.c,
;                              verbatim: its per-trip controlled Ry targets a
;                              register allocated fresh that trip;
;   * fresh_per_trip_kept      a plain Ry on a fresh per-trip register, coupled
;                              to the record only after the Ry;
;   * inloop_allowlisted_kept  inside the loop, after the merge, the protected
;                              registers only get `cqrt_rz`, `cqrt_x`, a
;                              controlled copy and a controlled Rz's control;
;   * prerecord_ry_kept        before the loop, the condition register is
;                              coupled and then rotated: no merge write can
;                              precede that Ry, so no record exists yet.

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1 zeroext)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_x(i32)
declare void @cqrt_rz_i32(i32, double)
declare void @cqrt_rz_i32_controlled(i32, i32, double)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare zeroext i1 @cqrt_measure_i1(i32)

; [pA] the shipped slice + `cq_theta(&b0[0], .3)` after the merge, per trip.
define i32 @pa_bank_cell_ry_loud() #0 !dbg !902 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 2)
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 2)
  call void @cqrt_free(i32 %h_cmp)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %a, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %cell = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %i
  store i32 %h, ptr %cell, align 4
  %c0 = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 0
  %ld = load i32, ptr %c0, align 4
  call void @cqrt_ry_i1(i32 %ld, double 3.000000e-01), !cq.selftest.fires !0, !dbg !903
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; [pB] θ(&c,.5); for (i<3) { if (c > i) a -= 3; θ(&c,.2); }
define i32 @pb_cond_inloop_ry_loud(i32 %u) #0 !dbg !904 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h, double 2.000000e-01), !cq.selftest.fires !0, !dbg !905
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

; [pC] for (i<3) { bool b = 0; θ(&b,.5); if (b) a -= 3; r += M(b); θ(&a,.1); }
define i32 @pc_rail_inloop_ry_loud() #0 !dbg !906 {
entry:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %b = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %b, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %b)
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %a, i32 %out)
  call void @cqrt_x(i32 %b)
  %mb = call i1 @cqrt_measure_i1(i32 %b)
  call void @cqrt_ry_i32(i32 %out, double 1.000000e-01), !cq.selftest.fires !0, !dbg !907
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; [pD] for (i<3) { θ(&a,.1); bool b = 0; θ(&b,.5); if (b) a -= 3; r += M(b); }
define i32 @pd_phi_top_ry_loud() #0 !dbg !908 {
entry:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  call void @cqrt_ry_i32(i32 %a, double 1.000000e-01), !cq.selftest.fires !0, !dbg !909
  %b = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %b, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %b)
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %a, i32 %out)
  call void @cqrt_x(i32 %b)
  %mb = call i1 @cqrt_measure_i1(i32 %b)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; [pE] for (j<2) for (i<3) { if (a >= 3) θ(&b0[i],.5); if (b0[i]) a -= 3; }
; with the bank cells allocated before the nest: the second outer trip's
; controlled Ry targets a cell register the first outer trip's merges record.
define i32 @pe_nested_cell_loud() #0 !dbg !910 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  %z0 = call i32 @cqrt_alloc_i1(i1 false)
  %z1 = call i32 @cqrt_alloc_i1(i1 false)
  %z2 = call i32 @cqrt_alloc_i1(i1 false)
  %e0 = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 0
  store i32 %z0, ptr %e0, align 4
  %e1 = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 1
  store i32 %z1, ptr %e1, align 4
  %e2 = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 2
  store i32 %z2, ptr %e2, align 4
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %outer
outer:
  %j = phi i32 [ 0, %entry ], [ %j1, %olatch ]
  %ao = phi i32 [ %seed, %entry ], [ %out, %olatch ]
  br label %loop
loop:
  %i = phi i64 [ 0, %outer ], [ %i1, %loop ]
  %a = phi i32 [ %ao, %outer ], [ %out, %loop ]
  %cell = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %i
  %ld = load i32, ptr %cell, align 4
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 2)
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %ld, double 5.000000e-01), !cq.selftest.fires !0, !dbg !911
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 2)
  call void @cqrt_free(i32 %h_cmp)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %ld, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %a, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %ld, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %olatch, label %loop
olatch:
  %j1 = add nuw nsw i32 %j, 1
  %odone = icmp eq i32 %j1, 2
  br i1 %odone, label %exit, label %outer
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; a fresh per-trip register coupled to the carried φ, THEN rotated.
define i32 @fresh_coupled_ry_loud() #0 !dbg !912 {
entry:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %b = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %b, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %b)
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %a, i32 %out)
  call void @cqrt_x(i32 %b)
  %mb = call i1 @cqrt_measure_i1(i32 %b)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %a, i32 %g)
  call void @cqrt_ry_i1(i32 %g, double 3.000000e-01), !cq.selftest.fires !0, !dbg !913
  %mg = call i1 @cqrt_measure_i1(i32 %g)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; %g allocated BEFORE the loop: rotated at the top of each trip, coupled to the
; carried φ later in the trip. Trip 2's Ry acts on an entangled %g.
define i32 @backedge_fresh_ry_loud() #0 !dbg !914 {
entry:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  call void @cqrt_ry_i1(i32 %g, double 3.000000e-01), !cq.selftest.fires !0, !dbg !915
  %b = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %b, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %b)
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %a, i32 %out)
  call void @cqrt_x(i32 %b)
  %mb = call i1 @cqrt_measure_i1(i32 %b)
  call void @cqrt_cnot(i32 %a, i32 %g)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %mg = call i1 @cqrt_measure_i1(i32 %g)
  ret i32 %m
}

; (R11 round 1, F3 ii) the coupling reaches a per-trip fresh %g only through an
; ALIAS (a φ in the latch block), then %g is rotated: loud. A freshness scan
; over the alloc's own users alone would call %g fresh.
define i32 @alias_coupled_ry_loud() #0 !dbg !916 {
entry:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %mid ]
  %a = phi i32 [ %seed, %entry ], [ %out, %mid ]
  %g = call i32 @cqrt_alloc_i1(i1 false)
  br label %mid
mid:
  %gp = phi i32 [ %g, %loop ]
  call void @cqrt_cnot(i32 %a, i32 %gp)
  call void @cqrt_ry_i1(i32 %g, double 3.000000e-01), !cq.selftest.fires !0, !dbg !917
  %mg = call i1 @cqrt_measure_i1(i32 %g)
  %b = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %b, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %b)
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %a, i32 %out)
  call void @cqrt_x(i32 %b)
  %mb = call i1 @cqrt_measure_i1(i32 %b)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; the shipped lowering of slice_control_cascade_loop_carried_handle.c, verbatim.
define i32 @slice_kept() #1 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
exit:
  %c0 = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 0
  %l0 = load i32, ptr %c0, align 4
  %m0 = call zeroext i1 @cqrt_measure_i1(i32 %l0)
  %c2 = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 2
  %l2 = load i32, ptr %c2, align 4
  %m2 = call zeroext i1 @cqrt_measure_i1(i32 %l2)
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
loop:
  %i = phi i64 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 2)
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 2)
  call void @cqrt_free(i32 %h_cmp)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %a, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  %cell = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %i
  store i32 %h, ptr %cell, align 4
  br i1 %done, label %exit, label %loop
}

; a plain Ry on a fresh per-trip register, coupled to the record only after.
define i32 @fresh_per_trip_kept() #1 {
entry:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %b = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %b, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %b)
  call void @cqrt_copy_i32_controlled(i32 %b, i32 %a, i32 %out)
  call void @cqrt_x(i32 %b)
  %mb = call i1 @cqrt_measure_i1(i32 %b)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; inside the loop, after the merge: only diagonal / permutation / control uses.
define i32 @inloop_allowlisted_kept(i32 %u, i32 %w) #1 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %hx = call i32 @cqrt_alloc_i32(i32 %w)
  call void @cqrt_ry_i32(i32 %hx, double 1.570000e+00)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %hx, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_rz_i32(i32 %h, double 3.000000e-01)
  call void @cqrt_x(i32 %hx)
  %g = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_rz_i32_controlled(i32 %hx, i32 %g, double 2.000000e-01)
  %mg = call i32 @cqrt_measure_i32(i32 %g)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; before the loop the condition register is coupled, then rotated: no merge
; write can precede that Ry.
define i32 @prerecord_ry_kept(i32 %u, i32 %w) #1 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  %hy = call i32 @cqrt_alloc_i32(i32 %w)
  call void @cqrt_ry_i32(i32 %hy, double 7.000000e-01)
  call void @cqrt_cnot(i32 %hy, i32 %h)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

attributes #0 = { "cq-selftest-expect"="loud" "cq-selftest-message"="cq merge discharge: non-diagonal gate on a register a leaked loop-carried merge rail records" }
attributes #1 = { "cq-selftest-expect"="kept" }

!0 = !{}
!1 = !{i32 1}

; debug info: only the tagged call carries a !dbg line (cq-merge-selftest
; checks the diagnostic fired at that line).
!llvm.dbg.cu = !{!890}
!llvm.module.flags = !{!891}
!890 = distinct !DICompileUnit(language: DW_LANG_C11, file: !892, producer: "hand", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly)
!891 = !{i32 2, !"Debug Info Version", i32 3}
!892 = !DIFile(filename: "carried_fence_inloop.ll", directory: "ir-pass/test/Inputs/merge_selftest")
!893 = !DISubroutineType(types: !{})
!902 = distinct !DISubprogram(name: "pa_bank_cell_ry_loud", scope: !892, file: !892, line: 101, type: !893, scopeLine: 101, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!903 = !DILocation(line: 101, scope: !902)
!904 = distinct !DISubprogram(name: "pb_cond_inloop_ry_loud", scope: !892, file: !892, line: 102, type: !893, scopeLine: 102, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!905 = !DILocation(line: 102, scope: !904)
!906 = distinct !DISubprogram(name: "pc_rail_inloop_ry_loud", scope: !892, file: !892, line: 103, type: !893, scopeLine: 103, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!907 = !DILocation(line: 103, scope: !906)
!908 = distinct !DISubprogram(name: "pd_phi_top_ry_loud", scope: !892, file: !892, line: 104, type: !893, scopeLine: 104, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!909 = !DILocation(line: 104, scope: !908)
!910 = distinct !DISubprogram(name: "pe_nested_cell_loud", scope: !892, file: !892, line: 105, type: !893, scopeLine: 105, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!911 = !DILocation(line: 105, scope: !910)
!912 = distinct !DISubprogram(name: "fresh_coupled_ry_loud", scope: !892, file: !892, line: 106, type: !893, scopeLine: 106, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!913 = !DILocation(line: 106, scope: !912)
!914 = distinct !DISubprogram(name: "backedge_fresh_ry_loud", scope: !892, file: !892, line: 107, type: !893, scopeLine: 107, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!915 = !DILocation(line: 107, scope: !914)
!916 = distinct !DISubprogram(name: "alias_coupled_ry_loud", scope: !892, file: !892, line: 108, type: !893, scopeLine: 108, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!917 = !DILocation(line: 108, scope: !916)
