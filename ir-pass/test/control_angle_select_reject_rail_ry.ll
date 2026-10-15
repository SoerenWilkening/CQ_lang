; control_angle_select_reject_rail_ry.ll — DECLINE (bd 3qlq.4, follow-on 1b-C):
; the Ry-stem ANGLE SELECT on a bare rail — `if (b) cq_theta(&r, A); else
; cq_theta(&r, B);` folded to one theta with a selected angle. By difference this
; would be `ry(h, B)` + `cqrt_ry_<W>_controlled(h_b, h, A−B)` controlled on the
; register; the controlled-Ry family's fences (R4 disjoint wires, the structural
; freeze, S7–S9) were argued for a MINTED flag and are re-argued for a borrowed
; one in 1b-C, not here. Declined (not `NotApplicable`, which the caller reports
; as `rotation angle`, the wrong reason) with `kBareRailCondReason`.
;
; ⚠ NOTE ADDED BY bd `test_C_libtooling-l4x4` sub-increment l4x4.b (2026-09-11):
; **1b-C WAS SPLIT, AND THIS FILE BELONGS TO THE HALF THAT HAS NOT LANDED.** The
; DIAMOND and the controlled STATE PREP on a rail lower now (l4x4.b); the Ry-stem
; ANGLE SELECT is **l4x4.a** and is a separate increment, so this file's verdict
; and its string are DELIBERATELY UNCHANGED. It is not an omission and not a
; regression: `classifyAngleSelect` was not touched by l4x4.b beyond nothing at
; all, and the whole-corpus sweep against the F2 base measured exactly two
; movers, neither of them this one. Read the sentence above as "…are re-argued
; for a borrowed one in l4x4.a".

;
; ⚠ FLIPPED TO AN ACCEPT BY bd test_C_libtooling-dm7f.54 (2026-10-15). THE NAME IS
; KEPT (gahu precedent, L8): it is the l4x4.a shape, and the header above is its
; history. It lowers, but NOT by difference and NOT controlled on the register:
; the owner ruling `owner-ruling-angle-select-xbracket-2026-10-13` (each arm's
; angle in exactly one controlled gate, no `cqrt_x` on a user register) is met
; with a CNOT COPY flag, `CondTreeEmit`'s `CopyRailRoot` (the r9e5 4.4-select
; flag): `bf = |0>; cnot(b, bf); ry_c(bf,r,.9); x(bf); ry_c(bf,r,.3); x(bf);
; cnot(b, bf); free(bf)`. ANALYTIC: b = 1 -> r gets Ry(.9), b = 0 -> Ry(.3),
; on the prepped `r`; bf = b on every branch and returns to 0, a proven-|0>
; free; b sees control slots only and is never freed. The if/else twin
; `control_inplace_ry_reject_rail_ifelse.ll` (also flipped, name kept) emits
; the identical stream.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  %a = select i1 %b, double 9.000000e-01, double 3.000000e-01
  %r2 = call i32 @cq_theta_si32(i32 %r, double %a)
  %n = call i32 @cq_measure_si32(i32 %r2)
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %s = add i32 %n, %z
  ret i32 %s
}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[B]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[B]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK-NOT:  call void @cqrt_free(

; NEG-NOT: = select
; NEG-NOT: cq_theta_
; NEG-NOT: cq_phi
