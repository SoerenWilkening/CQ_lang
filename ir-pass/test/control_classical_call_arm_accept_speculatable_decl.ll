; control_classical_call_arm_accept_speculatable_decl.ll — ACCEPT via LLVM's own
; totality answer (bd wve8): an OPAQUE declaration is admitted by the 6.5
; classical-call arm if and only if it carries `speculatable`.
;
; This module is control_classical_call_arm_reject_opaque_callee.ll with
; `speculatable` added to attribute group #0 — plus a different callee name and
; its own CHECK lines, so it is the arm-kill made permanent rather than a
; byte-for-byte copy. That file DECLINES; this one lowers, and the ONE functional
; difference is the attribute (verified in both directions). The pair isolates the
; token that answers "may this call be executed on a path the source did not
; take", and proves the decline over there is not about opacity, the diamond
; shape, the argument, or purity.
;
; WHY `speculatable` IS THE RIGHT TOKEN AND NOTHING WEAKER IS. LangRef defines it
; as asserting that the function has no effects besides computing its result AND
; no undefined behavior — the exact conjunction this site needs — and warns that a
; function wrongly marked speculatable may have its UB observed even at a dead
; call site. (Paraphrased deliberately: the wording could not be checked verbatim
; on this machine, and an earlier draft of this file MIS-QUOTED it by one article
; inside the quote marks. A fabricated quotation in shipped source is worse than
; none.) The one verbatim quotation lives in the gate comment: LLVM's own
; `isSafeToSpeculativelyExecute` demands this attribute for a call over the reason
; "The called function could have undefined behavior or side-effects, even if
; marked readnone nounwind".
;
; *** REACH — TWO DRAFTS OF THIS PARAGRAPH WERE WRONG, IN OPPOSITE DIRECTIONS.
; READ THE THIRD. ***
;  * Draft 1 said "C has NO spelling for `speculatable`, so this row has ZERO
;    population". The premise is FALSE: clang stamps the attribute on the
;    INTRINSICS it emits for builtins (`__builtin_abs` -> `llvm.abs.i32` carries
;    `mustprogress nocallback nofree nosync nounwind speculatable willreturn
;    memory(none)` at -O1).
;  * Draft 2 concluded from that premise-correction that
;    `if (q > 3) y = __builtin_abs(a);` therefore LOWERS THROUGH THIS ROW and the
;    disjunct is "load-bearing for ordinary C". ALSO FALSE, and it was an
;    inference from an exit code rather than a measurement. That C never reaches
;    this gate: clang -O1's own SimplifyCFG speculates the lone `speculatable`
;    call into a `select`, so the module contains ZERO `br i1`, the pure-callee
;    proof is queried ZERO times, and the accept comes from the 4.4 tainted-SELECT
;    owner. Measured.
;  * THE TRUTH, AND IT IS STRUCTURAL RATHER THAN ACCIDENTAL: an arm that is
;    exactly one `speculatable` call is exactly the shape SimplifyCFG speculates
;    into a select, which hands it to 4.4; and an arm SimplifyCFG DECLINES to
;    speculate has >= 2 instructions and fails 6.5's own arm-shape gate. Those two
;    facts squeeze the C witness out from both sides. 13 further builtin probes
;    (popcount, clz, ctz, bswap32/64, rotate, fabs, sqrt, ...) produced no witness
;    either — every one either lost its branch or kept two arm instructions.
; So: NO MEASURED C WITNESS AT THIS GATE, for a stated structural reason, over 14
; probes. That is NOT the same claim as "zero population" and must not be
; simplified back into it. The row is retained because it is LLVM's own answer to
; the exact question this gate asks, and it is pinned HERE at the IR level. The
; row with real reach is the strict body walk (`isSpeculatableTotalCallee`) —
; every one of the twelve 6.5 accept sites in the e2e layer is body-proved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @spec_f(i32) #0

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @spec_f(i32 0)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) speculatable }

; the full §5a controlled-XOR copy merge stream, with the call hoisted ahead of
; the flag mint:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 0.000000e+00)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @spec_f(i32 0)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[RH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; clone-orthogonal, and no surviving diamond:
; CHECK-NOT: @__cq_q_
; CHECK-NOT: phi i32
; ACC-NOT: under quantum control
