; control_inplace_rz_negated.ll — the §6a Rz peephole on a NEGATED (false-successor)
; phase arm (bd test_C_libtooling-drbq Inc 2a). Rule 9 polarity.
;
; `clang -O1` routinely makes the gate arm the FALSE successor, so the gate must
; fire on ¬flag. Both spellings of "fires on ¬f" use the SAME self-inverse
; `cqrt_x(flag)` bracket the swap route used, so they cannot drift — what changes
; is HOW MANY. The route bracketed EACH of its two `cqrt_cswap`s and therefore
; carried FOUR `cqrt_x`; control-in-place brackets the arm's GATE RUN once and
; carries TWO. That is the ONE count besides the route itself that Inc 2a moves,
; and it is the reason PRD §9.2's literal "the cqrt_x brackets … unchanged" is
; true of a non-negated arm and false here; `tools/golden_multiset_audit.py`
; models the -2 explicitly rather than waiving it.
;
; THE PAIR IS WHAT THIS PINS. A stray SINGLE `cqrt_x` would leave the flag
; inverted when the strip recomputes `q > 5`, so the strip would XOR onto the
; complement and `cqrt_free` would reset a rail holding |1> — a hidden measurement
; of an ancilla entangled with q (Rules 6/8).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The ROUTE'S ABSENCE, on its own prefix anchored at the function header. A
; trailing CHECK-NOT scans only past the LAST positive of its own prefix, and every
; route line lands BEFORE that, so it could never fire (bd memory
; filecheck-check-not-window-trap). The window reaches the declares too, hence the
; `call void @` anchors.
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact bracket count: TWO cqrt_x, no third.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %merge, label %arm
arm:
  %r1 = call i32 @cq_phi_si32(i32 %r, double %a)
  br label %merge
merge:
  %rm = phi i32 [ %r, %entry ], [ %r1, %arm ]
  %m1 = call i32 @cq_measure_si32(i32 %rm)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %o = add i32 %m1, %m2
  ret i32 %o
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; the ¬flag bracket, opened...
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R:[a-zA-Z0-9_.]+]], double %a)
; ...and closed, before the strip reads the UNinverted flag
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: phi i32

; CNT-COUNT-2: call void @cqrt_x(
; CNT-NOT:     call void @cqrt_x(
