; control_classical_call_arm_reject_frozen_arg_range.ll — DECLINE (bd 9hea).
; ARM: the ARM-KILL for `control_classical_call_arm_accept_frozen_poison_arg.ll`, and
; the row that pins bd 9hea's fence as a WHITELIST rather than a blacklist.
;
; Byte-identical to the accept row except that `@pf`'s parameter carries
; `range(i32 0, 10)` beside its `noundef`. That single attribute must flip the verdict
; back to a loud decline.
;
; *** WHY `freeze` DOES NOT DISCHARGE A CO-LOCATED ATTRIBUTE. *** `freeze` promises
; only that the result is SOME defined value — it does not promise a value that
; satisfies anything else the parameter asserts. A defined value outside
; `range(i32 0, 10)` makes the parameter POISON again, and poison in a `noundef`
; parameter operand is the immediate-UB case the clause exists to refuse. So freezing
; would launder the appearance of the problem without discharging it. The same applies
; to `nonnull`, `align`, `derefereceable`, `dereferenceable_or_null` and `nofpclass`:
; every one of them says a POISON VALUE is passed when violated.
;
; THE FENCE IS SPELLED AS A WHITELIST ON PURPOSE (the bd s6ao discipline, and the same
; reasoning bd 615s applies one file over). `freeze` discharges the obligation ONLY
; when the parameter's sole poison-relevant attribute is `noundef`. Spelled as a
; BLACKLIST — "decline if `range` or `nonnull` or `align` or `nofpclass`" — the clause
; would SILENTLY ACCEPT the fifth such attribute LLVM adds, which is exactly the
; failure mode bd s6ao's post-mortem names. Spelled as a whitelist it over-declines
; that attribute instead, which is always safe (Prime Directive).
;
; HONEST ABOUT THE OVER-DECLINE: this row may be refusing more than it must. Whether
; LLVM 19 really treats a `range`-violating DEFINED value as poison at a parameter is
; not resolved here — `Attributes.td` carries no semantics prose and nothing was
; measured — so the conservative direction was taken deliberately rather than argued.
; If someone measures it, this cell is the one to revisit, and the accept side of the
; whitelist is where the widening would go. Filed as the residue of bd 9hea.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; identical to the accept row's callee except for the parameter's `range`.
define internal i32 @pf(i32 noundef range(i32 0, 10) %x) #0 {
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @example(i32 noundef %u0, i32 noundef %n) {
entry:
  %p = shl i32 1, %n                ; poison for %n >= 32
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 noundef range(i32 0, 10) %p)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; NOTE, so nobody adds a vacuous assertion here: there is deliberately NO `CHECK-NOT`
; for the emitted stream. On a `DS_Error` the diagnostic handler exits before the
; module is printed, so cq-opt writes ZERO bytes to stdout and a CHECK-NOT over this
; stream can never match under ANY behaviour of the gate.
