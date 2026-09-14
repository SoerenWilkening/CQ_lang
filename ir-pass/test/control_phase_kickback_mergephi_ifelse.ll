; control_phase_kickback_mergephi_ifelse.ll — ACCEPT (bd `3qps`, Track P). An
; IF/ELSE over a prep merge φ: `if (b1) cq_phi(A); else cq_phi(B);`.
;
; ⚠ THE NON-NEGOTIABLE THIS FILE EXISTS FOR: the ELSE arm fires on `b1 == 0`, and
; a `cqrt_x` bracket on the user's register is FORBIDDEN. It is emitted as the
; DIAGONAL `cqrt_rz_i1(h1, −B)` on `X·P(θ)·X = e^{iθ}·P(−θ)`, whose only
; difference is a GLOBAL phase (owner decision D2 discards it; an uncontrolled
; `cq_phi` is deleted on exactly that ground). `fneg` is exact in IEEE, so no
; rounding class is introduced. The `XCNT` prefix below is the pin: ZERO
; `cqrt_x` anywhere in the module.
;
; Three predicates would each break on a `cqrt_x(rail)`:
; `Uncomputation::preservesBorrowedParent` fails CLOSED on a gate it cannot name
; (a borrowing chain would freeze — a leak), `ChainWalk::isInPlaceGateOn` never
; recovers `cqrt_x`, and this emitter's region-level invariant ("no non-diagonal
; gate on any condition register") would be false.
;
; ⚠ RED ON THE ORACLE (`branch phase on a bare i1 condition`, `59ac5b7`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %ph, label %phf
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
phf:
  call void @cq_phi(double 1.100000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double -1.100000e-01), !cq.branchphase
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; XCNT-NOT: call void @cqrt_x(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-2: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-2: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
