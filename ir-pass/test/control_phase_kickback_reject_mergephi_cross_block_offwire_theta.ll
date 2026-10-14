; control_phase_kickback_reject_mergephi_cross_block_offwire_theta.ll — **NOW AN ACCEPT**
; (bd `test_C_libtooling-dm7f.53`, closing bd `dm7f.62`).
;
; ⚠ The `reject_` in the name is history (bd `gahu` precedent, L8).
;
; THE SHAPE: a cross-block prep-merge-phi kickback with a chained
; `cq_theta_i1(%b0, …)` in the gap — a Ry on the PREP'S CONTROL `b0`, which is
; NOT on the condition phi's rail (`condProvenance(%b1) = {%b1, %t}`). The old
; header pinned this as the proof that the WIRE-BLIND positional scan survived
; Track P′. dm7f.53 replaced that scan, for a claimed phi defined outside
; `Pred`, by the WIRE-SCOPED `crossBlockPhiLeafMintable` — the question the phi
; LEAF already asks — so the root and the leaf spell one question once. Its
; ground is `crossBlockCompareMintable`'s (drbq.12): availability (every name of
; the phi's rail in the gap is a member) and G6 (the phi is read later, so M-C
; refuses an in-place `add`/`xor` that could alias it). It is NOT the
; `railCondWireDisposition` ground the old header warned against (that one
; drops the gap question entirely; this one asks it per rail).
;
; Trace check: b0 Ry(.5); t prepped under b0 (cRy .25 on a fresh rail); b0
; Ry(.7) in the gap — t's rail untouched; the kickback `cqrt_rz_i1` on t's rail.
; `if (b1) cq_phi(.9)` reads t after the gap, which is exactly t's state.
; The on-wire twin `…_cross_block_theta.ll` still declines.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %gap1
gap1:
  %x = call i1 @cq_theta_i1(i1 %b0, double 7.000000e-01)
  br label %gap2
gap2:
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %x)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK:      call void @cqrt_ry_i1(i32 %[[H0]], double 0x3FE6666666666666)
; CHECK:      call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
;
; Whole-file, pure negatives.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: call void @cqrt_free(
; NOROUTE-NOT: call i1 @cq_theta_i1(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: = phi
