; control_classical_call_arm_reject_poisonbr_callee.ll — TOTALITY reject, the
; TERMINATOR-SKIP case (bd wve8). `isSpeculatablePureCalleeBodyWalk` `continue`s on
; every terminator and only ever checks that it IS a `br`/`ret`; it never asks
; whether a conditional branch's CONDITION can be poison. Since
; `isSpeculatableDataflow` admits a variable-amount `shl`/`lshr`/`ashr` and
; `fptosi`/`fptoui` unconditionally (that predicate's own header says so), a body
; can compute a poison `i1` and branch on it — and `br i1 poison` is IMMEDIATE UB,
; executed on a path the source shielded once the 6.5 arm hoists the call.
; `%s = shl i32 1, %x` is poison for `%x >= 32`, so `%c` is poison and the `br` is
; UB on exactly those inputs.
;
; WHAT `isSpeculatableTotalCallee` ACTUALLY DOES ABOUT IT: it refuses a
; CONDITIONAL BRANCH outright in the callee body. An unconditional `br` still
; passes — it has no condition and cannot be UB — so this is a rule about `br i1`,
; not about multi-block bodies as such.
;
; *** WHY NOT THE OBVIOUS CHECK. MEASURED — DO NOT RE-TRY IT. *** The first draft
; asked `isGuaranteedNotToBeUndefOrPoison` on the branch condition, and THIS
; FIXTURE ACCEPTED WITH IT IN PLACE. Instrumented on this exact body, LLVM 19
; answers `gnp(%c) = 1` while `gnp(%s = shl i32 1, %x) = 0`. `icmp` cannot CREATE
; poison, so bottom-up the answer must be 0; it is 1 because ValueTracking also
; reasons from USES — `%c` is a `br` condition, a use that is UB on poison, so a
; well-defined program implies `%c` is not poison. That is the question asked
; backwards. Same family as the `canCreateUndefOrPoison` no-op recorded in
; LiteralIntegrity.h: the name matches the obligation, the answer does not.
;
; *** HONEST SEVERITY, BECAUSE THIS PROJECT HAS RETRACTED POWERLESS
; JUSTIFICATIONS BEFORE. *** This is a LangRef closure, NOT an exhibited crash,
; and it is weaker than its QROM sibling in two measured ways: (1) the one attempt
; to reach it from clang -O1 C failed — instcombine folded the diamond to
; straight-line `shl`+`add`, so the arm never survived to the pass, and one failed
; probe is not a proof of unreachability either way; (2) at the SHIPPED stage-3
; link there is no runtime consequence, because that stage is deliberately `-O0`
; (run_slice.sh) and the backend just materializes the masked x86 shift. It is
; closed anyway for one reason: "pure + TOTAL + terminating" is relied on at a site
; that speculates the whole call, so it has to be TRUE there rather than
; true-modulo-a-footnote. Do not quote this fixture as evidence of a miscompile;
; quote control_classical_call_arm_reject_qrom_callee.ll for that.
;
; ARM-KILL, committed as its own file: control_classical_call_arm_accept_poisonselect_callee.ll
; keeps the SAME poison-capable `shl` and the SAME `icmp`, computes the SAME value,
; and replaces ONLY the conditional branch with a `select` — and it LOWERS. So the
; decline here is the `br i1`, not the `shl`, not the poison, not the visible body
; and not the call. A multi-block callee is not excluded either: an unconditional
; `br` passes (no condition, so it cannot be UB).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @pf(i32 noundef %x) #0 {
entry:
  %s = shl i32 1, %x            ; poison when %x >= 32
  %c = icmp eq i32 %s, 7        ; poison
  br i1 %c, label %t, label %f  ; IMMEDIATE UB — the walk used to skip this
t:
  ret i32 1
f:
  ret i32 2
}

define i32 @example(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; NOTE, so nobody adds a vacuous assertion here: there is deliberately NO
; `CHECK-NOT` for the emitted stream. On a `DS_Error` the diagnostic handler exits
; before the module is printed, so cq-opt writes ZERO bytes to stdout and a
; CHECK-NOT over this stream can never match under ANY behaviour of the gate —
; it would read as a second, independent assertion while asserting nothing. The
; decline is fully pinned by `not` (the exit code) plus the message above.
