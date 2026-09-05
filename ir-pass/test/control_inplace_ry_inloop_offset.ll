; control_inplace_ry_inloop_offset.ll — ACCEPT: the in-loop Ry arm with a dtzb
; IN-PLACE VALUE self-update (`q += 3`) on the CONDITION register (bd
; test_C_libtooling-drbq Inc 3).
;
;     for (...) { if (q == 5) r = cq_theta(r, .9); q = q + 3; }
;
; WHY THIS SHAPE IS ON ITS OWN. `collapseRailPhisIn` step (3) MARKS every in-place
; value rail self-update into `taint.InPlaceRailOps`, and that line is not
; bookkeeping: without it `lowerOps` emits the add OUT of place into a rail nothing
; reads and the whole loop computes on `q` where the source says `q + 3` — a
; measured silent miscompile (bd 8h7d.5), `opt` exit 0, verify-clean, strict
; stage-2b CLEAN, whose only outward sign was one M-A warning. The Ry arm changes
; what else is on the OTHER rail; this fixture asserts that the marking still
; happens and the add still lowers as `cqrt_addc_i32`.
;
; A dtzb add is NOT a `cq_theta`, so the condition wire gains no non-diagonal gate
; and `condWireDisposition` returns `None` — the P1 fence is not consulted.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the offset is IN PLACE on the condition handle, not a fresh rail:
; CHECK: call void @cqrt_addc_i32(i32 %[[Q]], i32 3)
;
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: cq_template_add_i32_hl
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %qn    = add i32 %q, 3
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %ma = call i32 @cq_measure_si32(i32 %qn)
  %mb = call i32 @cq_measure_si32(i32 %rm)
  %sum = add i32 %ma, %mb
  ret i32 %sum
}
