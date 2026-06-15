; control_swap_reject_cond_datause_dead.ll — DECLINE probe (ziov, PERMANENT): the
; tainted condition compare is used as control AND data, but the data lineage is
; DEAD WITHIN THE FUNCTION — neither measured nor escaped.
;
; `%c = icmp sgt q, 5` feeds the `br` (control) AND `%d = zext %c`, but `%d`'s
; lineage (`%dead = add %d, 7`) is never measured, returned, nor passed to
; cq_invert — a quantum bit computed, then orphaned. Sharing the flag here would
; leave it ALLOCATED AND ENTANGLED with q with no downstream owner (Rule 6/8).
;
; ziov.2 PROPOSED lifting this decline by sharing one flag and emitting a DEFERRED
; `icmp_inv` strip + free at the post-dominator of all flag uses. That plan was
; reviewed (2026-06-15) and CLOSED won't-fix: it is a verify-clean SILENT
; MISCOMPILE. Each data op mints a FRESH rail (`cq_template_zext`/`add` →
; `cqrt_alloc_handle`), so `%d`/`%dead` are COPIES of `q>5` entangled with q. A
; flag-ONLY strip cleans the flag but leaves those copies — a which-region record
; on q that DEPHASES the arm's phase under any later interference (SCOPING §3a's
; flag-strip is coherent ONLY when the flag is the SOLE ancilla; §3 line 184).
; The shape is also UNREACHABLE from clang -O1 (a truly-dead lineage is DCE'd to
; bare `icmp; br`; a live one escapes/measures = the WI-1 ShareOk accept). So this
; declines LOUDLY and PERMANENTLY (over-declining is always safe; Prime Directive).
; A correct accept would need full fan-out-aware data-lineage uncompute (reverse-
; play `%d`/`%dead`→|0>, free, THEN strip the flag once) — not built. The
; escaped/measured twins (control_swap_cond_datause_{escape,measured}.ll) ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use neither escaped nor measured under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32            ; DATA use of the condition compare
  %dead = add i32 %d, 7            ; DEAD: never measured, returned, or inverted
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
