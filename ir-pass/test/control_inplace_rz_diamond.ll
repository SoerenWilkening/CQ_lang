; control_inplace_rz_diamond.ll — ACCEPT spec, the §6a Rz CONTROL-IN-PLACE
; PEEPHOLE on a one-content-arm PHASE diamond (bd test_C_libtooling-drbq Inc 2a,
; control-in-place-PRD §12.2). THE FLAGSHIP FIXTURE OF THE INCREMENT.
;
; `if (q > 5) r = cq_phi(r, a)` on a register DISJOINT from the condition. Until
; Inc 2a this lowered to the swap route — mint, |0> work-rail alloc, cswap in,
; verbatim uncontrolled Rz on the rail, cswap back, rail free, strip, flag free.
; It now emits ONE `cqrt_rz_i32_controlled(flag, r, a)` on the user's own register
; and NOTHING ELSE CHANGES: same mint, same strip, same flag free, same order.
;
; THE TWO ARE THE SAME UNITARY, not an approximation. With the work rail at |0>,
; `cswap(f,r,w) · Rz_w(θ) · cswap(f,r,w)` applies Rz(θ) to r exactly on the f=1
; branch, and on f=0 applies Rz(θ) to a rail still holding |0> — which under this
; project's `Rz = diag(1, e^{iθ})` convention is the identity with NO global-phase
; residue. So the peephole is an equality. (The Ry stem could never route at all —
; `Ry(θ)|0> ≠ |0>` hands the inactive rail back dirty and entangled, PRD §2 — which
; is why control-in-place is the MECHANISM there and a PEEPHOLE here.)
;
; WHAT THIS PINS BEYOND THE SYMBOL: the register is untouched by anything else
; (no alloc, no cswap, no copy), the flag is minted BEFORE the gate and stripped
; AFTER it, and there is EXACTLY ONE cqrt_free — the flag. There is no work rail
; to free any more, and the uncompute spine must not add a second free (a spurious
; free of an entangled register is a hidden measurement, Rules 6/8).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The ROUTE'S ABSENCE, on its own prefix anchored at the function header so the
; window is the whole function: a trailing CHECK-NOT scans only past the LAST
; positive of its own prefix, and every route line would land BEFORE that, so it
; could never fire (bd memory filecheck-check-not-window-trap).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact free count: ONE (the flag), no second anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %o = add i32 %m1, %m2
  ret i32 %o
}

; mint the flag from the tainted compare — byte-identical to the routed form
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; the arm gate, CONTROLLED, IN PLACE, on the user's own register %[[R]]
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R:[a-zA-Z0-9_.]+]], double %a)
; strip: Rz is diagonal on BOTH branches, so q == q0 and icmp_inv(q) returns the
; flag to |0> — the same argument the route made, minus the route
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the merge phi was RAUW'd to the base: the measure reads the rotated register
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; no second free after the flag free
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @example
; the five route lines are GONE — no work rail, no swap either way
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: call void @cqrt_x(
; and method-B never applies to a phase arm (a copy dephases it, Rule 7)
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: phi i32

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
