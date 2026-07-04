; control_classical_call_arm_accept_onward_byref_prestore.ll — ACCEPT + Rule-13 UAF
; regression (bd 0vvq Increment 1): a 6.5 classical-call arm whose UNTAINTED merge
; `%out` feeds an onward `frexp` whose exponent cell has a DEAD PRE-CALL whole-cell
; store `store i32 %y, ptr %ecell` (clang's `int e = y; frexp((double)y, &e);`) that
; the frexp overwrites.
;
; THE UAF THIS GUARDS (found by the 0vvq Rule-13 sweep, 3-lens convergence, fixed by
; the symmetric Stores scrub in `lowerByRefMath`): the pre-call store's VALUE is `%y`
; = the round-2 control-merge rail `%out`, so after the second propagation the STORE
; INSTRUCTION is in `taint.Tainted` (a plain user of the tainted `%out`). `analyzeCell`
; accepts it as a dead pre-call whole-cell store (it dominates the call) and the
; teardown erases it. Before the fix, the teardown scrubbed the loads + the call from
; `taint.Tainted` but NOT the stores — so the freed `StoreInst*` dangled in the taint
; set, and the 0vvq round-2 re-propagation (which seeds its work-list from the LIVE
; `taint.Tainted`) copied the freed pointer and dereferenced it via `V->users()` — a
; use-after-free (silent under the default allocator, SIGSEGV under guard malloc). The
; fix scrubs Stores symmetrically. This fixture pins that the shape LOWERS clean (the
; pre-store forwarded away, the frexp lowered, verify-clean).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
declare double @frexp(double, ptr)
define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %ecell = alloca i32
  store i32 %y, ptr %ecell                          ; TAINTED (round-2) dead pre-call store
  %d = sitofp i32 %y to double
  %fr = call double @frexp(double %d, ptr %ecell)
  %e = load i32, ptr %ecell
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; %out build, sitofp cast, frexp markers, measure; the tainted pre-store is GONE:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[OUT]])
; CHECK:     %[[EXP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_frexpexp_f64_to_i32(i32 %[[CAST]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[EXP]])
; CHECK-NOT: store i32
; CHECK-NOT: call double @frexp
