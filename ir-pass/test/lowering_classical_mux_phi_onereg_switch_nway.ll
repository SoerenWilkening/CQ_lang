; lowering_classical_mux_phi_onereg_switch_nway.ll — ACCEPT: the N-ARY (N>2)
; one-register merge phi (test_C_libtooling-sbt1.3, Phase 7.1 Increment C). The
; natural classical N-way `switch` around an in-place quantum gate on ONE
; register:
;     switch (classical_k) { case 1: q=cq_phi(q,a);  break;
;                            case 2: q=cq_phi(q,b);  break;
;                            default:               break; }
;     measure(q);
; (pre-3qlq register form; the 3qlq migration deleted both phases, global phases
; under a classical scrutinee, so every case block is now EMPTY). It survives
; clang -O1 as a switch with one merge phi whose 3 incomings all denote the SAME
; register %q: the phi is a pure SSA renaming. The N-ary lift (the Increment C
; generalization of liftOneRegisterMergePhi) proves every edge's chain lives in
; its own case block AND no arm gate can reach the merge through ANY OTHER edge
; whose record omits it (the generalized (7a) over all j != i), then RAUWs the
; phi to the wire base and erases it.
;
; Rule-13 trace clearance: the scrutinee is CLASSICAL — each shot takes exactly
; one case; the lift adds/moves/removes NO gate, only an SSA name disappears —
; no superposed control, no flag, no controlled gates.
;
; N==2 reduces EXACTLY to the prior `1-i` complement (the arity-2 fixtures
; lowering_classical_mux_phi_onereg*.ll are behaviorally unchanged); the third-
; edge hole a naive `1-i`-only extension would leave is pinned by
; lowering_reject_classical_mux_phi_onereg_nway_loop.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; ONE allocation only (the single register), then its Ry in entry:
; CHECK:      call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NOT:  call i32 @cqrt_alloc_i32
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; The case blocks survive (empty since 3qlq):
; CHECK:      arm1:
; CHECK:      arm2:
; The merge measures the ONE handle; the renaming phi is GONE:
; CHECK:      merge:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  phi i32
; CHECK-NOT:  cq_phi_si32
; CHECK-NOT:  cq_theta_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  switch i32 %k, label %merge [               ; CLASSICAL scrutinee
    i32 1, label %arm1
    i32 2, label %arm2
  ]
arm1:
  br label %merge
arm2:
  br label %merge
merge:
  %p = phi i32 [ %q, %entry ], [ %q, %arm1 ], [ %q, %arm2 ]  ; one register, 3 SSA names
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
