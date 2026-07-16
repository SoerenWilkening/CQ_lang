; spec_reject_diamond_store_arm.ll — Phase 6 / issue 5po2 (I1 over-accept probe):
; a memory STORE inside a diamond ARM (not the entry block) must still decline.
; The I1 scanBody loosening walks EVERY block of a multi-block body, so a
; non-value construct in any arm is caught precisely — a store is irreversible
; (no reversible copy), declined `NonReversibilizable (memory access)`, NOT
; silently lifted into a clone. Guards the all-blocks whitelist walk.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, ptr %p) {
entry:
  %c1 = icmp sgt i32 %b, 5
  br i1 %c1, label %then, label %else
then:
  store i32 %b, ptr %p
  %a1 = add i32 %b, 1
  br label %merge
else:
  %a2 = add i32 %b, 3
  br label %merge
merge:
  %r = phi i32 [ %a1, %then ], [ %a2, %else ]
  ret i32 %r
}

define i32 @example(i32 %u0, ptr %p) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, ptr %p)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access)
