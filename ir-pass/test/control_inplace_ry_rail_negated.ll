; control_inplace_ry_rail_negated.ll — ACCEPT: the in-place controlled-Ry arm on
; a bare `_Bool` (rail-root) condition with the arm on the FALSE successor —
; `if (!b) r = cq_theta(r, .9);` (bd test_C_libtooling-l4x4, sub-increment
; l4x4.b, probe `t7`). Transcribed from `clang -O1`, which gives this source an
; ORIENTATION-B diamond (`br i1 %c, merge, arm`), so the shape is plain-C
; reachable and is the increment's ONE genuine design decision.
;
; THE COMPARE FORM SPENDS A `cqrt_x(flag)` BRACKET HERE AND THIS ONE MAY NOT
; (probe `t7c`, measured). `3qlq.4`'s invariant is "never a `cqrt_x` on a user
; register, EVER" — `Uncomputation::preservesBorrowedParent` admits an
; uncontrolled `cqrt_rz_` on a borrowed parent BY NAME and fails CLOSED on
; anything else, so a bracket would freeze every chain that borrows the
; register — and the phase path's escape hatch does NOT exist for `Ry`:
; `X·P(θ)·X = e^{iθ}·P(−θ)` is an identity about a DIAGONAL gate.
;
; SO NEGATION IS ANTI-CONTROL BY Ry ADDITIVITY (SCOPE §2.3 option A):
;
;     cqrt_ry_i32(h_r, θ)                    ; b = 0 → Ry(θ)
;     cqrt_ry_i32_controlled(h_b, h_r, −θ)   ; b = 1 → Ry(θ)·Ry(−θ) = I
;
; which is the source's unitary on BOTH branches. `−θ` is an IEEE SIGN FLIP, not
; an `fsub`, so the Inc-2b by-difference rounding fence
; (`kAngleSelectMaxRoundingRad`, the ½·ulp(A−B) argument) has NO SUBJECT here and
; its constant-arms-only narrowing is not imported. It is width-safe because
; `cqrt_ry_<W>` is TENSORED: each of the W qubits independently sees
; `Ry(θ)Ry(−θ) = I`. The one literal hazard that IS real — an `undef` angle
; occupying two emitted slots (bd `xy9n`) — is refused in `classifyArms` before
; any mutation; see `control_inplace_ry_reject_rail_negated_undef_angle.ll`.
;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4: both decline
; `bare i1 register condition` at `classifyArms`' first gate.
;
; THE TWO-GATE FORM IS ALSO THE e2e WITNESS: `slice_control_inplace_ry_bool_negated`
; and its MANUAL twin `..._negated_twin` (`r = cq_theta(r,θ); if (b) r =
; cq_theta(r,−θ);`) are byte-identical traces, gated by `compare_files`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare double @cq_measure_f64(double)

define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double -9.000000e-01)
;
; ---------------------------------------------------------------------------
; THE NEGATIVES ARE WHOLE-FILE AND PURE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 lesson:
; a POSITIVE directive inside a prefix WINDOWS every negative one of that
; prefix, so every count lives in its own CNT prefix and no `-NOT` shares a
; prefix with a positive). `NOX` is THE NON-NEGOTIABLE: bd `3qlq.4`'s invariant
; is "never a `cqrt_x` on a user register", and the rail path has no ancilla to
; put one on either, so the whole-file form is both stronger and true.
; NOX-NOT: call void @cqrt_x(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = phi
; NOMINT-NOT: cq_template_icmp
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; RYCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}(
; RYCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}(
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
