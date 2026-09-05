; control_swap_inloop_two_registers.ll — ACCEPT (bd test_C_libtooling-8h7d.5,
; Rule-13 round 1, finding OD1). TWO INDEPENDENT QUANTUM REGISTERS, each with its
; own tainted `if`, in ONE classically-bounded loop.
;
;     a = cq_theta(a, .5);  b = cq_theta(b, .25);
;     for (…) { if (a == 5) a = cq_phi(a, PI);
;               if (b == 3) b = cq_phi(b, PI);
;               a = cq_theta(a, -.5);  b = cq_theta(b, -.25);
;               a = cq_theta(a,  .5);  b = cq_theta(b,  .25); }
;     return cq_measure(a) + cq_measure(b);
;
; `clang -O1` verbatim (two loop-carried register phis in one header, two
; sequential diamonds, the arms value-propagated to `cq_phi(5, …)` / `cq_phi(3,
; …)`). It DECLINED at ba35c1f — "condition predates a non-diagonal gate under
; quantum control" — because `WireWalk::phiTracksWire` asked whether ANY
; `cq_theta` sat between an incoming and its edge, so each register's rotations
; refused the OTHER register's barrier and neither could ever be claimed. Nothing
; about that decline was about either register's own wire; the shape was simply
; unreachable.
;
; THE FIXTURE PINS BOTH HALVES OF THE GROUPING RULE, and they pull in opposite
; directions, which is why it is worth a file:
;   * the STALENESS test is per WIRE — `%b`'s Ry may not stale `%a`'s record
;     (finding OD1), else this program never lowers;
;   * the RECORD-LIVENESS fence groups rail chains by their ROOT MINT — two
;     chains rooted at ONE mint are one physical register and MUST interfere
;     (lowering_reject_inloop_rail_alias_shared_mint.ll, which is red for exactly
;     that reason). Two mints, two registers, no interference. Coarsen the fence
;     to one group per loop and this file goes red; drop the root grouping and its
;     twin goes green with a miscompile.
;
; The emitted stream is the two per-register streams in SOURCE order on two
; handles, and gates on distinct wires commute, so the rolled body is the same
; circuit the hand-unrolled form would emit.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  br label %7

3:                                                ; preds = %19
  %4 = tail call i32 @cq_measure_si32(i32 noundef %23)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %24)
  %6 = add nsw i32 %5, %4
  ret i32 %6

7:                                                ; preds = %0, %19
  %8 = phi i32 [ 0, %0 ], [ %25, %19 ]
  %9 = phi i32 [ %2, %0 ], [ %24, %19 ]
  %10 = phi i32 [ %1, %0 ], [ %23, %19 ]
  %11 = icmp eq i32 %10, 5
  br i1 %11, label %12, label %14

12:                                               ; preds = %7
  call void @cq_phi(double 0x400921FB54442D18)
  br label %14

14:                                               ; preds = %12, %7
  %16 = icmp eq i32 %9, 3
  br i1 %16, label %17, label %19

17:                                               ; preds = %14
  call void @cq_phi(double 0x400921FB54442D18)
  br label %19

19:                                               ; preds = %17, %14
  %21 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef -5.000000e-01)
  %22 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef -2.500000e-01)
  %23 = tail call i32 @cq_theta_si32(i32 noundef %21, double noundef 5.000000e-01)
  %24 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef 2.500000e-01)
  %25 = add nuw nsw i32 %8, 1
  %26 = icmp eq i32 %8, 0
  br i1 %26, label %7, label %3, !llvm.loop !6
}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}

; TWO rails, both minted outside the loop:
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK:     %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[B]], double 2.500000e-01)
;
; ONE rolled body; both register phis collapsed, only the classical induction
; variable survives in the header:
; CHECK:     %{{.*}} = phi i32 [ 0, %0 ], [ %{{.*}}, %{{.*}} ]
; CHECK-NOT: phi
; region 1, on rail A:
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[A]], double 0x400921FB54442D18)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[A]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; region 2, on rail B:
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[B]], i32 3)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[B]], double 0x400921FB54442D18)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[B]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; the four post-region rotations, in SOURCE order, on the two handles:
; CHECK:     call void @cqrt_ry_i32(i32 %[[A]], double -5.000000e-01)
; CHECK:     call void @cqrt_ry_i32(i32 %[[B]], double -2.500000e-01)
; CHECK:     call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK:     call void @cqrt_ry_i32(i32 %[[B]], double 2.500000e-01)
;
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: rail record read past an in-place gate
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
