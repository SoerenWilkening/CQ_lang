; spec_accept_clone_read_in_discharge_window.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-rhk5; Rule-13 r3A F-XA-4, probe `d4.c`). The 2-TU program, as
; `tests/e2e/run_slice_multi.sh` links it:
;
;     lib:   int h(int a, int k) { return k + 1; }
;     main:  q = m & 7; cq_theta(&q, .5); p = q * 3; u = p ^ q; s = h(m, q);
;            if (u == 10) cq_phi(PI); ms = cq_measure(s); cq_theta(&q, .7);
;            return ms + cq_measure(q);
;
; `p = 3q` and `u = 3q ^ q` are a derived chain whose only consumer is the kickback
; compare; the M-B INTERIOR partition discharges both after the flag strip, with
; `q` as the BORROWED parent. The clone call `__cq_q_h_10(0, q)` sits INSIDE that
; discharge window, and until bd rhk5 `preservesBorrowedParent` counted it as a
; MUTATION of `q` (it proved read-only exactly two gate shapes, and a clone call is
; neither), so clause (d) refused, the component leaked, and `3q`, `3q ^ q` stood
; allocated and ENTANGLED with `q` across `cqrt_ry_i32(h, 0.7)` — a Rule-8 wrong
; unitary, `opt` exit 0, one lyyf-(B) warning. MEASURED ON THE ORACLE (main
; 9a230646): the warning, no `xor_i32_unc`, no `mul_i32_hl_unc`, stage-2b CENSUS
; `2 left dirty`. Its hand-inlined twin (`s = q + 1`) discharges both and warns
; nothing — hand-inlining a pure callee must not change the circuit.
;
; THE FIX IS A PROOF, NOT A NAME TEST: `cloneCallPreservesArg` (ChainWalk.h) walks
; the clone's lowered body and admits the call only because every use of the
; formal `%k` is a forward producer (`add_i32_hl`) or an adjoint READ slot
; (`add_i32_hl_unc` slot 1). The clone body below is pinned UNCHANGED — the fix
; moves the caller's discharge, never the callee.
;
; THE TWIN, AND WHY THE TRACE IS NOT BYTE-IDENTICAL TO IT: the clone's Bennett
; copy-out adds four lines, and `-O1` sinks the twin's inlined add past the region
; while the call stays where it was written. `tools/trace_twin_equiv.py` decides
; the precise relation (same circuit up to that contraction and commuting
; independent gates); the e2e pair `e2e-spec-clone-read-in-window-twin-equivalent`
; runs it on the committed goldens.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %s = call i32 @h(i32 %m, i32 %q)
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %ms = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %r = add nsw i32 %k, 1
  ret i32 %r
}

; No M-A warning: nothing is standing at the second Ry any more. `opt` exits zero.
; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %h = call i32 @cqrt_alloc_i32(i32 %a)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; LOWER-NEXT: %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; LOWER-NEXT: %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
; The clone call stays where the user wrote it — inside the discharge window.
; LOWER-NEXT: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase
; LOWER-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; THE DISCHARGE the oracle did not emit: both chain rails reversed LIFO and freed,
; AFTER the strip (their last reader) and BEFORE the second Ry.
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: %m2 = call i32 @cqrt_measure_i32(i32 %s)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; LOWER-NEXT: %m3 = call i32 @cqrt_measure_i32(i32 %h)
;
; The clone body, UNCHANGED from the oracle: compute, copy out, uncompute, free.
; Its formal `%k` is only ever READ — that is the whole licence.
; CLONE-LABEL: define internal i32 @__cq_q_h_10(i32 %a, i32 %k)
; CLONE-NEXT: %h_op = call i32 @cq_template_add_i32_hl(i32 %k, i32 1)
; CLONE-NEXT: %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
; CLONE-NEXT: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %k, i32 1)
; CLONE-NEXT: call void @cqrt_free(i32 %h_op)
; CLONE-NEXT: ret i32 %cqq.out
