; lowering_measure_round2_sixfive_handle.ll — ACCEPT, and THE L1 PIN for bd
; test_C_libtooling-21mg verdict (d): a measure operand that is CLASSICAL at
; round 1 and TAINTED at the round-2 fixpoint must lower as a MEASURE OF THE
; HANDLE, never as a classical passthrough.
;
; WHY THIS FIXTURE EXISTS. 21mg gives `lowerMeasures` a second disposition keyed
; on `taint.Tainted`, and CLAUDE.md CORRECTNESS RISK §3 (L1) says any stage that
; reads taint between the two rounds of control detection has a ROUND-2-FALSE
; premise. The 6.5 classical-call arm's merge rail `%out` is exactly that value:
; `ClassicalCallArmEmit.cpp:226` records it in `taint.UntaintedMergeRails` and
; `repropagateControlMerges` re-seeds taint FROM it — so at round 1 this measure's
; operand is an untainted i32, and only after the fixpoint is it a rail.
;
; THE OBLIGATION IS DISCHARGED BY ORDER, NOT BY A PREDICATE: `lowerMeasures` is
; called AFTER `repropagateControlMerges` in BOTH entry points
; (`CQLoweringPass.cpp` — `repropagateControlMerges` then
; `lowerRotations`/`lowerOps`/`lowerMeasures`, in `run()` and in
; `runOnFunction()`), so the taint it reads is FINAL.
;
; ⚠ RETIREMENT TRIGGER. If `lowerMeasures` is ever hoisted above
; `repropagateControlMerges` — or a third entry point wires it before the fixpoint
; — this module stops emitting `cqrt_measure_i32(%out)` and instead RETURNS THE
; RAW i32 HANDLE as data: the user's measurement vanishes, the trace loses a line,
; and `opt -verify` is perfectly clean. That is the verify-clean silent miscompile
; this file is here to make loud. What goes red is the `MCNT` count and the
; `NOBARE` line below; do not "fix" either by regenerating.
;
; The shape is `control_classical_call_arm_accept.ll`'s (which pins the 6.5 stream
; itself, and whose own `cq_measure_si32(%y)` is this same round-2 rail — so that
; fixture is a second, independent witness). This one deliberately asserts ONLY
; the measure disposition, so it stays green under any future re-spelling of the
; 6.5 copy-merge stream and red only on the ordering defect above.
;
; SOURCE INTENT: `int y = q; if (q > 5) y = pure_f(7); return cq_measure(y);`
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOBARE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; DEFINED, not declared — the 6.5 arm HOISTS this call out of its quantum guard,
; so it needs a TOTALITY proof as well as a purity one and a visible pure body is
; what supplies it (bd wve8, `isSpeculatableTotalCallee`).
define i32 @pure_f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pure_f(i32 7)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; the scrutinee rail, then the merge rail minted as the |0> out rail, and the
; measure fires ON THE LATTER. (The scrutinee alloc+ry is pinned because without
; it an injected DELETION of the first `cqrt_alloc` was MISSED by 0 of 3 prefixes
; — injection matrix, 2026-09-13.)
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK:     ret i32 %[[M]]

; EXACTLY ONE measurement gate, in its own prefix (Rule 12 (a)), at ANY width —
; counting the i32 spelling alone MISSED an injected `cqrt_measure_i1` with 0 of 3
; prefixes (injection matrix, 2026-09-13):
; MCNT-COUNT-1: call {{.*}}@cqrt_measure_
; MCNT-NOT:     call {{.*}}@cqrt_measure_

; and the function must NOT return a bare i32 rail handle — which is precisely
; what the classical path would produce if it ever claimed this operand (the RAUW
; would make `ret` yield `%out`, the handle, with no measure anywhere):
; NOBARE-NOT: call{{.*}}@cq_measure_
; NOBARE:     call i32 @cqrt_measure_i32(

; the 6.5 copy-merge's bracket and teardown counts. They are not this fixture's
; subject — `control_classical_call_arm_accept.ll` owns the 6.5 stream — but
; without them an injected `cqrt_x` / `cqrt_free` on the scrutinee rail was MISSED
; by 0 of 3 prefixes (injection matrix, 2026-09-13), and an extra bracket or a
; free of the scrutinee is a hidden measurement (Rule 6), not a cosmetic change.
; EXACTLY THREE rails: the scrutinee, the |0> out rail, and the materialized
; classical call result. A FOURTH means a rail minted for something classical
; (without this an injected `cqrt_alloc_i32` / `cqrt_alloc_f64` was MISSED by 0 of
; 5 prefixes — injection matrix, 2026-09-13):
; ACNT-COUNT-3: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_

; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(

; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: undef/poison literal
