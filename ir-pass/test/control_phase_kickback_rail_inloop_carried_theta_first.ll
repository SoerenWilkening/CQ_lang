; control_phase_kickback_rail_inloop_carried_theta_first.ll — ACCEPT, and it pins
; a SHIPPED stream that nothing else in the tree pins (bd boi6 H-10, scoped
; 2026-09-11 SCOPE_boi6.md §0.4, re-measured 2026-09-13 on the ORACLE
; build/ir-pass/cq-opt sha256 fbbe0820… at e96f89c).
;
; THE SHAPE: a LOOP-CARRIED `_Bool` rail whose region condition is the IN-BODY
; chained `cq_theta_i1` (the theta BEFORE the region in the body), i.e. boi6
; probe `p2`:
;     bool b = (bool)0; cq_theta(&b, .5);
;     for (int i = 0; i < 3; i++) { cq_theta(&b, .2); if (b) cq_phi(.7); }
; This is the ONE shape where the Inc-1b kickback already fires on a rail whose
; wire crosses a BACK EDGE: the condition is a genuine `cq_theta_i1` CALL (so
; `isCondRailLeaf` admits it), while the rail's identity is carried by the header
; phi `%b`, which `collapseFlattenedLoopRails` RAUWs to the root mint. The
; emitted body is ONE `cqrt_ry_i1` + ONE `cqrt_rz_i1` per activation, rolled: no
; mint, no `_unc` strip, no `cqrt_free`, no `cqrt_x` on a user register, and the
; lowered IR size is independent of the trip count (MEASURED: 50 lowered lines at
; K=3 and 50 at K=1000, `wc -l` on the `-O1` C twin's lowered module).
;
; WHY IT IS PINNED HERE AND NOT LATER: it is the DISCRIMINATOR for bd `boi6.a`.
; `boi6.a` admits the header PHI itself as a rail leaf (`p1`, the theta AFTER the
; region, today `branch phase on a bare i1 condition`). This file's stream must
; stay BYTE-UNCHANGED across that widening — if it moves, the widening changed a
; shipped circuit. Pin first, widen second.
;
; ⚠ RETIREMENT TRIGGER (L8): when bd `boi6.a` lands, this file STAYS AN ACCEPT
; and its CHECK lines stay character-for-character identical. What changes is its
; SIBLING `control_phase_kickback_reject_bare_i1_loop_phi.ll`, which becomes an
; accept whose header-phi condition lowers to the SAME `cqrt_rz_i1(%h, θ)` in the
; same block. If THIS file's output moves when `boi6.a` lands, stop: the
; widening is not stream-preserving and the clearance argument is void.
;
; ⚠ NOT RUN THROUGH `lit`: written by the Track-L SCOPING agent (PROTOCOL.md
; "scoping" row forbids it). Every CHECK line below was derived from the ORACLE's
; actual output on THIS EXACT FILE
; (`cq-opt -load-pass-plugin … -passes=cq-lowering -S`), never guessed. The
; landing agent must run `lit --filter` once before committing.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br label %header
header:
  %i = phi i32 [ 0, %entry ], [ %inc, %latch ]
  %b = phi i1 [ %b0, %entry ], [ %b1, %latch ]
  %b1 = call i1 @cq_theta_i1(i1 %b, double 2.000000e-01)
  br i1 %b1, label %arm, label %latch
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %latch
latch:
  %inc = add nuw nsw i32 %i, 1
  %ex = icmp eq i32 %inc, 3
  br i1 %ex, label %exit, label %header
exit:
  %m = call i1 @cq_measure_i1(i1 %b1)
  %z = zext i1 %m to i32
  ret i32 %z
}

; The root mint is in the PREHEADER and the carried phi is GONE (collapsed):
; CHECK:      entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:      header:
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = phi i32 [ 0, %entry ], [ %{{[a-zA-Z0-9_.]+}}, %header ]
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H]], double 0x3FE6666666666666), !cq.branchphase
; CHECK:      br i1 %{{[a-zA-Z0-9_.]+}}, label %exit, label %header
; CHECK:      {{.*}} = call i1 @cqrt_measure_i1(i32 %[[H]])

; ---- Whole-file negatives. PURE-NEGATIVE prefixes: no positive line may sit
; ---- inside one, or every later negative in it is WINDOWED (the Inc-4 F-L6-1
; ---- lesson, CLAUDE.md Rule 12(a)). Counts live in their OWN prefixes.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: cqrt_cnot
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: call i1 @cq_theta_i1(
; NOROUTE-NOT: phi i1
; XCNT-NOT: call void @cqrt_x(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_
; ACNT-COUNT-1: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
