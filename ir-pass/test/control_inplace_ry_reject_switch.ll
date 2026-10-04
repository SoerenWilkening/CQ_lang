; control_inplace_ry_reject_switch.ll — DECLINE: rotation arms under a
; tainted-scrutinee `switch` (control-in-place-PRD §4 R7 / §8; bd
; test_C_libtooling-drbq).
;
;     switch (q) { case 1: cq_theta(&r,.9); case 2: cq_theta(&r,.2); }
;
; The 4.5 switch has its own classifier (`SwitchClassify` G0-G11 +
; `SwitchArmProve`) and three emitters, reached from `detectControlRegions`'
; SwitchInst arm — the `br`-diamond classifier this increment extends is never
; consulted. N-way in-place rotation is not scoped in this epic at all (PRD §8:
; "switch (4.5) … unchanged, keep their routes/declines").
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; MIRRORED CHARACTER-FOR-CHARACTER (Rule 12). The earlier
; `error{{.*}}under quantum control` matched EVERY diagnostic in the family —
; measured green against the share-cond-flag fixture's stderr (round-1 review,
; lens L6 §5). NOTE `control flow` is the SHARED generic string (99 sites), so
; what this fixture asserts is NON-ACCEPTANCE, not fence identity: the 4.5
; `SwitchClassify` path owns the decline and this class never reaches
; `classifyArms`' rotation clause at all.
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  switch i32 %q, label %merge [ i32 1, label %c1
                                i32 2, label %c2 ]
c1:
  %g1 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
c2:
  %g2 = call i32 @cq_theta_si32(i32 %r, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r, %entry ], [ %g1, %c1 ], [ %g2, %c2 ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
