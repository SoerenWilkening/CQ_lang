; control_angle_select_reject_cmp_data_use.ll — DECLINE (S4): the condition
; compare is ALSO read as DATA (bd drbq Inc 2b).
;
;     int f = (q == 5);                       // a data use of the compare
;     cq_theta(&r, q == 5 ? .9 : .3);      // clang -O1 CSEs the two tests
;     ... cq_measure(f);
;
; THE FIXTURE THAT FENCES S4's `Cond->hasOneUse()`. Its sibling
; `..._reject_cmp_shared_with_region.ll` cannot: there the ziov
; condition-data-use guard fires first from the `br` region and owns the
; message. Here there is no region, so this clause is the only refusal —
; measured by stubbing it out, which turns this fixture red and nothing else.
;
; WHY IT MATTERS BEYOND BOOKKEEPING. The emitter erases the compare only when it
; is `use_empty()`; with a surviving data use it stays, and `lowerOps` then lowers
; it into a SECOND `cq_template_icmp_eq_i32_hl` flag rail that this stream neither
; strips nor frees — an unpaired rail entangled with `q`. The `ShareCondFlag`
; mechanism exists for exactly this composition on the `br` path (mint once, feed
; the data use the same handle, SKIP the strip because the data lineage owns it);
; the angle-select path has no such arrangement and declines until it does.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %z = zext i1 %c to i32
  %mz = call i32 @cq_measure_si32(i32 %z)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %x = add i32 %mz, %mt
  ret i32 %x
}
