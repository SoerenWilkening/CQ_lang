; control_classical_call_arm_reject_inner_retattr_nofpclass.ll — DECLINE (bd test_C_libtooling-bwfp).
; R11 round 3 F1(c): `@hc` returns `0/0 = NaN` for `%x == 0` under `nofpclass(nan)`
; (no `noundef`), i.e. poison. `@pc` compares it and returns the `zext` under
; `noundef`: `pc(0)` executes `ret noundef poison`. LLVM 19's
; `hasPoisonGeneratingReturnAttributes` does not read `nofpclass`; the dataflow now
; asks `returnAttrsHold`, which admits only the inert set plus a proven `range`.
; Measured on the round-3 snapshot (sha 8c141046): hoisted into `entry`, opt rc=0.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal nofpclass(nan) double @hc(double %x) #0 {
entry:
  %m = fdiv double %x, %x
  ret double %m
}

define internal noundef i32 @pc(i32 noundef %x) #0 {
entry:
  %d = sitofp i32 %x to double
  %h = call double @hc(double %d)
  %b = fcmp oeq double %h, 1.000000e+00
  %v = zext i1 %b to i32
  ret i32 %v
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pc(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
