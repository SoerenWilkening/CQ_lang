; control_angle_select_forward_rail_cycle_frozen.ll — ACCEPT (bd 3paw). An Ry
; angle select on `r`, then a CLASSICAL counting loop that rotates the SAME rail
; on every trip. The IR below is the `clang -O1` output of (attributes and
; `!llvm.loop` dropped, nothing else touched):
;
;     int slice(int u0, int u1, int n) {
;       int q = u0; cq_theta(&q, .5);  int r = u1; cq_theta(&r, .25);
;       cq_theta(&r, q == 5 ? .9 : .3);                // the 2b gate on r
;       for (int i = 0; i <= n; i++) cq_theta(&r, .1); // FORWARD gate, in a cycle
;       return cq_measure(q) + cq_measure(r);
;     }
;
; and `@slice_dead` is the same program returning `cq_measure(q)` only, so `r`
; is dead after the loop.
;
; WHAT IT PINS. The select's by-difference stream on `r` (`ry(r, .3)`, the flag
; mint from `q == 5`, `cqrt_ry_i32_controlled(f, r, fl(.9-.3))`, the `_unc`
; strip, the flag's free), all in `entry`; then the loop body's in-place
; `ry(r, .1)` on the SAME handle, rolled; and no reverse-play and no free of
; `r`'s rail anywhere (R6: a rail that carries a controlled Ry is frozen,
; `ChainWalk::railCarriesControlledRotation`). `@slice_dead` is the half where
; the freeze is load-bearing: its uncontrolled twin (`.3` written unconditionally)
; declines `cq uncompute: tainted handle live range crosses a loop backedge`,
; because the spine would have to reverse-play a dead rail that a loop rotated;
; the frozen rail is left allocated instead (R5's accepted leak).
;
; WHY IT DECLINED BEFORE bd 3paw (the re-spell trigger bd jttf left here).
; `lowerLoops` runs before detection, and Case-A's persistent-rail collapse
; (`tryCaseA`) RAUWs the loop header φ and the exit φ — both post-gate names of
; `r` — to the rail's ROOT mint `%5`, which is also the select's base. The
; consumer `%8` is left with no user, and the loop's `cq_theta(%5, .1)` and the
; exit `cq_measure(%5)` read the base by SSA identity. S7's rail prong then saw
; the loop gate as a member of the BASE's wire on a cycle and declined `control
; flow inside a loop body`; with that prong skipped alone, S9 declines next
; (`stale rail record read past a controlled Ry`, measured: bd 3paw mutant M3).
; Both read names the collapse re-spelt, not the pre-gate register.
; The fix (`classifyAngleSelect`, bd 3paw): on a rail some loop's collapse
; CLAIMED (`TaintSet::ClaimedRailRoots`), a member or reader that the consumer
; `T` DOMINATES is skipped by S7's rail prong and by S9. The fence that judged
; those reads ran on the PRE-collapse IR with `T` in its gate set: `tryCaseA`'s
; `staleRailRecordRead`, which asks every reader of every rail value (a member
; rail φ on each incoming edge since bd g35c), plus its fan-out guard for a
; second in-place gate on a pre-`T` name. Before g35c a member φ was never asked
; and this skip let a zero-trip stale record through (bd g35c). Decline twins:
; `control_angle_select_reject_forward_rail_cycle_zero_trip_{stale,ret}.ll` (the
; pre-gate alias reaching a measure / `ret` through the exit φ),
; `control_angle_select_reject_forward_rail_cycle_stale_alias.ll` (the pre-gate
; alias rotated in the loop, through the header φ) and
; `control_angle_select_reject_backward_rail_cycle.ll` (the loop BEFORE `T`,
; which the dominance conjunct keeps loud).
;
; SEMANTIC EVIDENCE (R2). The source's unitary on `r` is `Ry(.25)`, then `Ry(.9)`
; on `q == 5` and `Ry(.3)` otherwise, then `Ry(.1)` n+1 times; the stream below
; is `Ry(.25)·Ry(.3)·cRy_f(fl(.9-.3))·Ry(.1)^(n+1)` with `f = [q == 5]` minted
; from `q`'s rail and stripped by its `_unc` while `q` is unchanged (no gate
; touches `q`'s rail between mint and strip). `f = 1` gives `Ry(.3+fl(.9-.3))`,
; i.e. `Ry(.9)` up to the 2^-54 rad by-difference residual the 2b family
; documents; `f = 0` gives `Ry(.3)`. The loop gate lowers to `cqrt_ry_i32(h_r,
; .1)` on the one handle (`lowerRotations` RAUWs every chained `cq_theta` on the
; rail to it). Linked witness: e2e `slice_control_angle_select_ry_forward_loop`
; (n = 2, three trips) has a golden byte-identical to its hand-unrolled
; by-difference twin `slice_control_angle_select_ry_forward_loop_unrolled_twin`,
; which the pre-3paw compiler already lowered; STRICT stage 2b, 1 verified free.
;
; HISTORY. This file was written (bd drbq Inc 2b, round-2 Rule-13 review, lens R1
; item 2) to pin S7's forward-rail gap in the pre-3qlq register form; 3qlq
; deleted the in-loop gate and jttf found the register-free re-spelling above
; declined. The original IR (a phase select, an empty loop) is in git history.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.ll
; RUN: %filecheck %s --check-prefix=CRYCNT < %t.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.ll
; RUN: %filecheck %s --check-prefix=LOOPRY < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp eq i32 %4, 5
  %7 = select i1 %6, double 9.000000e-01, double 3.000000e-01
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %7)
  %9 = icmp slt i32 %2, 0
  br i1 %9, label %10, label %15

10:
  %11 = phi i32 [ %8, %3 ], [ %18, %15 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %14 = add nsw i32 %13, %12
  ret i32 %14

15:
  %16 = phi i32 [ %19, %15 ], [ 0, %3 ]
  %17 = phi i32 [ %18, %15 ], [ %8, %3 ]
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 1.000000e-01)
  %19 = add nuw i32 %16, 1
  %20 = icmp eq i32 %16, %2
  br i1 %20, label %10, label %15
}

define i32 @slice_dead(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp eq i32 %4, 5
  %7 = select i1 %6, double 9.000000e-01, double 3.000000e-01
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %7)
  %9 = icmp slt i32 %2, 0
  br i1 %9, label %10, label %12

10:
  %11 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %11

12:
  %13 = phi i32 [ %16, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %15, %12 ], [ %8, %3 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 1.000000e-01)
  %16 = add nuw i32 %13, 1
  %17 = icmp eq i32 %13, %2
  br i1 %17, label %10, label %12
}

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — hand-derived from `emitAngleSelectRegion`
; (twin `R(base, B)` before the consumer, the mint at the consumer, the strip and
; the free after it) and `lowerRotations`, before the fix existed. Handles are
; bound at their definition and referenced after, so the chain asserts operand
; IDENTITY: the controlled Ry, the strip and the free name the flag the mint
; produced, and the loop's Ry names `r`'s handle. Block labels are LLVM's.
; CHECK-LABEL: define i32 @slice(
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = icmp slt i32 %2, 0
; CHECK-NEXT: br i1 %[[G]], label %[[EXIT:[a-zA-Z0-9_.]+]], label %[[LOOP:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[EXIT]]:
; CHECK-NEXT: %[[MQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: %[[MR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = add nsw i32 %[[MR]], %[[MQ]]
; CHECK-NEXT: ret i32 %[[S]]
; CHECK: {{^}}[[LOOP]]:
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: add nuw i32 %[[I]], 1
; CHECK-NEXT: icmp eq i32 %[[I]], %2
; CHECK-NEXT: br i1
; CHECK-NEXT: }
;
; CHECK-LABEL: define i32 @slice_dead(
; CHECK-NEXT: %[[DQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[DQ]], double 5.000000e-01)
; CHECK-NEXT: %[[DR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[DR]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[DR]], double 3.000000e-01)
; CHECK-NEXT: %[[DF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[DQ]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[DF]], i32 %[[DR]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[DF]], i32 %[[DQ]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[DF]])
; CHECK-NEXT: %[[DG:[a-zA-Z0-9_.]+]] = icmp slt i32 %2, 0
; CHECK-NEXT: br i1 %[[DG]], label %[[DEXIT:[a-zA-Z0-9_.]+]], label %[[DLOOP:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[DEXIT]]:
; CHECK-NEXT: %[[DMQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[DQ]])
; CHECK-NEXT: ret i32 %[[DMQ]]
; CHECK: {{^}}[[DLOOP]]:
; CHECK-NEXT: %[[DI:[a-zA-Z0-9_.]+]] = phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[DR]], double 1.000000e-01)
; CHECK-NEXT: add nuw i32 %[[DI]], 1
; CHECK-NEXT: icmp eq i32 %[[DI]], %2
; CHECK-NEXT: br i1
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (no positive may enter this prefix: a positive
; windows every negative after it).
; NOROUTE-NOT: double -
;   ^ no reverse-play of `r` (or of anything): every angle this file writes is positive
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: call void @cqrt_rz_
;   ^ the Ry stem emits no phase gate
; NOROUTE-NOT: call void @cqrt_x(
;   ^ a select always means "true value when the flag is 1": no polarity bracket
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call i32 @cq_measure_
;   ^ every front-end call is lowered
;
; COUNTS — one pattern per prefix, `-COUNT-n` then `-NOT` pins exactly n.
; One controlled Ry and one flag free per function; the free is the FLAG's (the
; CHECK chain names it), so `r`'s rail is never freed.
; CRYCNT-COUNT-2: call void @cqrt_ry_i32_controlled(
; CRYCNT-NOT:     call void @cqrt_ry_i32_controlled(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; The loop gate, once per function body (rolled, not unrolled):
; LOOPRY-COUNT-2: call void @cqrt_ry_i32({{.*}}, double 1.000000e-01)
; LOOPRY-NOT:     call void @cqrt_ry_i32({{.*}}, double 1.000000e-01)
