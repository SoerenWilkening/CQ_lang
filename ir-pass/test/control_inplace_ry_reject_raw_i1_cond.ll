; control_inplace_ry_reject_raw_i1_cond.ll — DECLINE: control on a RAW i1 QUBIT,
; with no compare to mint a flag from (PRD shape S4, owner Q6 deferred; bd
; test_C_libtooling-drbq §8).
;
;     _Bool c = cq_theta((_Bool)0, 1.1); int r = cq_theta(0,.3);
;     if (c) r = cq_theta(r, .9);
;
; Every accepted tainted-control region in this compiler mints its flag AT A
; COMPARE (`cq_template_icmp_<pred>_<W>_hl`) and strips it with that compare's
; `_unc`. A bare `br i1 %theta` has no compare, so there is nothing to mint and
; nothing to strip — the register IS the control. Controlling on it directly is a
; real (3-gate cheaper) capability and is DEFERRED with its own PRD; it is NOT a
; physics wall. The `cq_phi` twin of this source declines identically today, which
; is why the deferral costs nothing this increment.
;
; Transcribed from `clang -O1`. This fixture exists to pin that the new
; rotation-arm clause did not accidentally claim the shape: the classifier's very
; first gate is `isa<CmpInst>(Region.Condition)`, unchanged.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 1.100000e+00)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %c, label %arm, label %merge
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
