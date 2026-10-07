; spec_accept_select_body.ll — Phase 6 / issue 5po2: a tainted `select` INSIDE a
; specialization-lifted callee, the first in-body control shape the clone path
; lowered (5po2; the clone lowers far more since, e.g. bd p3kd.7.1 / p3kd.7.2).
; `helper(b) = (b<5)?b:0`
; — the canonical `clang -O1` lowering of `int a=0; if(b<5) a+=b; return a` — is
; lifted into the reversible clone `@__cq_q_helper_1` as a 4.4 controlled-XOR copy
; `out = flag ? b : 0`, then Bennett-wrapped: copy-out → self-inverse reverse
; (the controlled copy re-applied zeroes the out rail, the compare `_unc` zeroes
; the flag) → free both scratch rails → return the escaping basis copy. The flag
; is kept LIVE across the body (no local strip); the Bennett reverse plays its
; adjoint. See EmitInverse (`cqrt_copy_<W>_controlled` = self-inverse) +
; SpecializeReject::isAdmissibleCloneSelect (was isLiftableSelect until bd
; p3kd.7.1) + Specialization::lowerCloneSelect.
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list, so the select goes
; through main's 4.4 path (CondTreeEmit flag + SelectMergeEmit controlled-copy
; merge). The retired clone-only `lowerCloneSelect` one-copy fast path for a
; constant-zero false arm (named above) no longer exists: the `0` arm is
; materialized as a |0> rail `ZERO` and copied on the X-bracketed ¬flag like any
; constant arm. Main's merge strips its own flag (trailing `cqrt_x`, compare `_unc`,
; free); inside a clone the Bennett wrap elides that strip, so the forward ends with
; the bracket OPEN and the flag holding [b>=5], and the exact mirror closes it.
; Hand trace, |b>: flag=[b<5]; sel ^= flag·b; flag→¬; sel ^= ¬[b<5]·0, so
; sel=(b<5)?b:0 = helper(b); out=sel. The mirror XORs 0 back, flips the flag to
; [b<5], XORs flag·b back (sel=0), and the `_unc` zeroes the flag: all three scratch
; rails are |0> at their frees. ZERO is allocated with the zero constant, so it is
; proven |0> and freed (contrast spec_accept_select_nonzero_false.ll, where the
; |7> rail stays allocated). The whole clone body is pinned CHECK-NEXT through `}`,
; which also replaces the old tail CHECK-NOTs (they scanned only the text after the
; clone's `ret`, and the diagnostics they named go to stderr, never into %t; a
; decline fails the RUN line itself through cq-opt's non-zero exit).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %b, i32 0
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; Caller: theta → alloc+ry; the call retargets to the mangled clone; phase +
; measure land on the clone's tainted result.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; Clone: the reversible select embedding, the whole body in order.
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %b, i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT:  %[[ZERO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[ZERO]], i32 %[[SEL]])
; Bennett copy-out (the flag strip was elided: no `cqrt_x` closes the bracket here).
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; The exact mirror: copies replayed (self-inverse) inside the bracket, then the
; compare `_unc` zeroes the flag.
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[ZERO]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %b, i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %b, i32 5)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[ZERO]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
