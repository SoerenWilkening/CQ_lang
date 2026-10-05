; control_swap_abort_park_inplace_ry.ll — bd test_C_libtooling-x61g ACCEPT: an
; abort park followed by an in-place gate on the PARKED register.
;
; SOURCE (each function is the clang -O1 IR of its C, attributes trimmed):
;   @slice          int q = u; cq_theta(&q,.5); if (q > 5) abort();
;                   cq_theta(&q,.3); return cq_measure(q);
;   @slice_negated  int q = u; cq_theta(&q,.5);
;                   if (q <= 5) { cq_theta(&q,.3); return cq_measure(q); } abort();
;                   (-O1 emits `icmp slt q, 6` with the sink on the FALSE edge:
;                   orientation B)
;   @slice_two_gates  as @slice with `cq_theta(&q,.3); cq_theta(&q,.2);` after it
;
; WHAT WAS DECLINED. `classifyAbortPark`'s sole-live-register guard counted SSA
; NAMES: the post-gate name `%6 = cq_theta(%2, .3)` has a user in the remainder,
; `%6 != Q`, so the park declined `control flow under quantum control`. But
; `lowerRotations` lowers a `cq_theta` whose arg-0 is tainted IN PLACE and RAUWs
; its result onto the arg-0 handle, so `%6` IS the routed register, and the park
; routes that register's rail. The guard now asks `railWireNamesBackward` (the
; one spelling of "every SSA name of this physical register") whether the live
; name's wire passes through Q.
;
; THE TRACE (orientation A; h = Q's rail, f = flag, g = graveyard):
;   ry(h,.5)                    Σ_x a_x |x>_h
;   f = icmp_sgt(h,5)           Σ_x a_x |x>_h |[x>5]>_f
;   g = alloc(0); cswap(f,h,g)  Σ_{x<=5} a_x |x>_h|0>_f|0>_g + Σ_{x>5} a_x |0>_h|1>_f|x>_g
;   tape_write(t,f)             the abort indicator is committed
;   ry(h,.3)                    f=0: Σ_{x<=5} a_x Ry(.3)|x>_h, the source's surviving
;                               state; f=1: Ry(.3)|0>_h beside |1>_f|x>_g, the aborted
;                               tail, orthogonal on f and never interfered with
;                               (f and g are GraveyardRails: no strip, no free)
;   measure(h)                  on f=0, the source's distribution given no abort
; The gate MUST fire on h, the handle the cswap leaves holding the survivor;
; a gate on `g`, or on a fresh rail, is a different program. Orientation B is
; the same with the cswap and the tape write ¬f-bracketed (abort on q >= 6).
;
; The `cq rotation lowering: non-diagonal gate over a live derived record`
; WARNING (the park's flag is a live record of h when the post-park Ry fires)
; is deliberately NOT pinned here: bd aako/gl3x exempts the park's flag record
; when its tape write precedes the gate. Exit status 0 is what this file pins.
;
; DECLINE TWINS: control_swap_reject_abort_inplace_ry_before_park.ll (the same
; gate moved before the park: a stale flag, refused by `reverifyCmpCondReads`),
; control_swap_reject_abort_inplace_ry_other_register.ll (an in-place chain on a
; SECOND register across the park) and
; control_swap_reject_abort_derived_copy_live.ll (a derived copy minted before
; the park, live after it).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll

; ---- orientation A: the ordered stream, the post-park Ry on the routed handle.
; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[GRAVE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[Q]], i32 %[[GRAVE]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[TAPE]], i32 %[[FLAG]])
; CHECK-NEXT: br label %[[REM:[0-9]+]]
; CHECK:      [[REM]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.000000e-01)
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: ret i32 %[[M]]

; ---- orientation B: the ¬flag brackets, then the same post-park Ry on Q.
; CHECK-LABEL: define i32 @slice_negated(
; CHECK:      %[[TAPEB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:      %[[QB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QB]], double 5.000000e-01)
; CHECK-NEXT: %[[FLAGB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[QB]], i32 6)
; CHECK-NEXT: %[[GRAVEB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAGB]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FLAGB]], i32 %[[QB]], i32 %[[GRAVEB]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAGB]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAGB]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[TAPEB]], i32 %[[FLAGB]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAGB]])
; CHECK-NEXT: br label %[[REMB:[0-9]+]]
; CHECK:      [[REMB]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QB]], double 3.000000e-01)
; CHECK-NEXT: %[[MB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[QB]])
; CHECK-NEXT: ret i32 %[[MB]]

; ---- a two-gate chain: both Ry fire on Q, in source order, after the park.
; CHECK-LABEL: define i32 @slice_two_gates(
; CHECK:      %[[QC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:      call void @cqrt_cswap(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[QC]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call i32 @cqrt_tape_write_i1(
; CHECK:      call void @cqrt_ry_i32(i32 %[[QC]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QC]], double 2.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[QC]])

; Per function EXACTLY two rails (Q and the graveyard) and ONE cswap: the
; post-park gate mints no fresh rail.
; CNT-LABEL:   define i32 @slice(
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-LABEL:   define i32 @slice_negated(
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-LABEL:   define i32 @slice_two_gates(
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(

; Nothing is freed (the graveyard and flag are kept, Q is measured) and every
; abort arm is erased (whole-file scan).
; NOFREE-NOT: call void @cqrt_free(
; NOFREE-NOT: call void @abort()
; NOFREE-NOT: unreachable

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = icmp sgt i32 %2, 5
  br i1 %3, label %4, label %5
4:
  tail call void @abort()
  unreachable
5:
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %7
}

define i32 @slice_negated(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = icmp slt i32 %2, 6
  br i1 %3, label %4, label %7
4:
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  ret i32 %6
7:
  tail call void @abort()
  unreachable
}

define i32 @slice_two_gates(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = icmp sgt i32 %2, 5
  br i1 %3, label %4, label %5
4:
  tail call void @abort()
  unreachable
5:
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %8
}
