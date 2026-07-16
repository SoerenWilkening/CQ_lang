; spec_reject_diamond_nested_compound.ll — Phase 6 / issue 5po2 (I1 over-accept
; probe): a DEPTH-2 NESTED diamond in a lifted callee stays declined. PredMux
; DOES claim a nested region (NestedTainted), but flattens it to a select whose
; condition is a COMPOUND boolean (`c1 ∧ ¬c2` — a toffoli conjunction), which the
; two-arm `lowerCloneSelect` does not lower (it requires a direct `icmp`
; condition). The surviving tainted `select` then trips the `buildClone`
; "no tainted select survives" backstop → loud decline. Nested / compound-
; condition diamonds are a later increment; I1 is single-level simple-icmp only.
; Guards the surviving-select over-accept backstop (never wrap a raw select).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %r0 = add i32 %b, 3
  %c1 = icmp sgt i32 %b, 5
  br i1 %c1, label %outer, label %merge
outer:
  %r1 = add i32 %b, 1
  %c2 = icmp slt i32 %b, 9
  br i1 %c2, label %inner, label %merge
inner:
  %r2 = add i32 %b, 2
  br label %merge
merge:
  %rm = phi i32 [ %r0, %entry ], [ %r1, %outer ], [ %r2, %inner ]
  ret i32 %rm
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: cq specialization: callee contains tainted control flow under quantum lift
