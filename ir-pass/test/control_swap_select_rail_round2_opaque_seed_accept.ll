; control_swap_select_rail_round2_opaque_seed_accept.ll — ACCEPT (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1's
; DISCRIMINATOR; the reviewer's probe `ll/e11` verbatim). The same two-sibling
; shape as `control_swap_reject_select_rail_round2_sibling_theta.ll` whose seed
; `%x` is classical at round 1 AND STAYS CLASSICAL (an opaque `load volatile` of
; a global `i1` — no `%out` anywhere). Both thetas are then SOURCE thetas at
; FINAL taint too, so `lowerRotations` mints TWO SEPARATE registers and the
; select's control read is on its own rail: the accept is CORRECT and the fix
; must not take it.
;
; THIS IS WHAT MAKES `reverifyRailCondReads` A RE-VERIFICATION AND NOT OPTION 3
; (the review's blunt "treat any non-`Constant` arg-0 as chained", which costs
; exactly this program). The two `cqrt_alloc_i1(i1 %x)` mints and the two
; independent `cqrt_ry_i1` below are the pin: with one rail there would be one
; alloc and the `cqrt_cnot` would follow both rotations.
;
; GREEN ON BOTH BINARIES (f8d29e8 and the fix), byte-identical.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.ll
; RUN: %filecheck %s --check-prefix=CNCNT < %t.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.ll

@gbit = global i1 false

declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @main() {
entry:
  %x = load volatile i1, ptr @gbit
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %zz
  ret i32 %t
}

; TWO registers, each rotated once, and the merge controls on a copy of the
; FIRST one only.
; ORD: %h = call i32 @cqrt_alloc_i1(i1 %x)
; ORD-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; ORD-NEXT: %[[N_h2:h[0-9]*]] = call i32 @cqrt_alloc_i1(i1 %x)
; ORD-NEXT: call void @cqrt_ry_i1(i32 %[[N_h2]], double 9.000000e-01)
; ORD-NEXT: %bf = call i32 @cqrt_alloc_i1(i1 false)
; ORD-NEXT: call void @cqrt_cnot(i32 %h, i32 %bf)
; ORD-NEXT: %out = call i32 @cqrt_alloc_i32(i32 0)
; ORD-NEXT: call void @cqrt_xorc_i32_controlled(i32 %bf, i32 %{{[0-9a-zA-Z_.]+}}, i32 2)
; ORD-NEXT: call void @cqrt_x(i32 %bf)
; ORD-NEXT: call void @cqrt_xorc_i32_controlled(i32 %bf, i32 %{{[0-9a-zA-Z_.]+}}, i32 5)
; ORD-NEXT: call void @cqrt_x(i32 %bf)
; ORD-NEXT: call void @cqrt_cnot(i32 %h, i32 %bf)
; ORD-NEXT: call void @cqrt_free(i32 %bf)
; ORD-NEXT: %[[N_m3:m[0-9]*]] = call i1 @cqrt_measure_i1(i32 %[[N_h2]])

; TWO i1 register mints (whole file) — one rail would be one.
; ACNT-COUNT-2: call i32 @cqrt_alloc_i1(i1 %x)
; ACNT-NOT: call i32 @cqrt_alloc_i1(i1 %x)

; EXACTLY TWO rotations in the whole module (the ORD chain above pins WHICH
; rail each one names): an injected third `cqrt_ry_i1` anywhere — including
; after the measure, where the ORD chain cannot see it — reddens this.
; RYCNT-COUNT-2: call void @cqrt_ry_i1(
; RYCNT-NOT: call void @cqrt_ry_i1(

; The copy flag is minted and un-copied exactly once, and it is the ONLY free.
; CNCNT-COUNT-2: call void @cqrt_cnot(
; CNCNT-NOT: call void @cqrt_cnot(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; No non-diagonal gate on either user register, no route, no adjoint.
; NOX-NOT: call void @cqrt_x(i32 %h)
; NOX-NOT: call void @cqrt_x(i32 %h1)
; NOX-NOT: @cqrt_cswap
; NOX-NOT: _unc(
; NOX-NOT: _inv(
; NOX-NOT: call i1 @cq_theta
