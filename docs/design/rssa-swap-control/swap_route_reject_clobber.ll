; swap_route_reject_clobber.ll — DESIGN SPEC, the §3c rejection
; ===========================================================================
; The one shape the swap-route emitter must DECLINE loudly even after it accepts
; tainted `if`/`if-else`/nested control: an arm that VALUE-CHANGES a quantum
; variable the branch condition transitively reads (SCOPING.md §3c). The flag is
; `icmp(q0)`; once the arm overwrites q's computational-basis value, the flag
; references a value no longer present in any live register, and for a
; non-injective map (e.g. `if(q==1) x(q)` → constant 0) NO control model and NO
; Bennett copy can produce a clean, disentangled answer (conservation of
; information). Model-independent: control-in-place reaches the identical bind.
;
; This is distinct from control_tainted_diag.ll (the transitional stub that
; declines ALL tainted control until the emitter lands). When the emitter lands,
; THIS case stays a permanent decline; the phase-arm diamond/if-else become accepts.
;
; NOT rejected (for contrast — these lower normally, see swap_route_if_diamond.ll):
;   - `if (q>5) { rz(q,a); }`     phase op on a condition var (value preserved)
;   - `if (q>5) { p = p+3; }`     value op on a NON-condition var (q untouched)
;   - `if (q>5) { p = q+1; }`     merely READS the condition var
;
; SOURCE INTENT (the rejected shape):
;     q : quantum handle
;     if (q > 5) { q = q + 3; }   // arm value-changes q, which the condition reads
;     measure q
;
; Detection is pure SSA-value analysis BEFORE any mutation (Rule 9): the arm
; defines a value-changing redefinition (`add`, not a rotation) of %q, and %q is
; in the transitive taint provenance of the branch condition.
; ===========================================================================

; RUN (once the emitter lands; the diagnostic string is matched character-for-
; character per Rule 12):
; ; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ; CHECK: error{{.*}}arm rewrites a condition operand under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = add i32 %q, 3        ; VALUE-changes %q — clobbers the condition's input
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
