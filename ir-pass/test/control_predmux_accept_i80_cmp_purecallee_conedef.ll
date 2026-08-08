; control_predmux_accept_i80_cmp_purecallee_conedef.ll — ACCEPT (bd 3c6m.14.1).
;
; SURFACE S4 — `coneDefinedAfterFlagDrop`, and THE ONE NOBODY HAD ENUMERATED.
; Not in the ticket, not in the bd 3c6m.61 source comment ("(a) E4's
; call-admission AND (b) exported as isSpeculatablePureCallee"), not in bd memory
; [[predmux-shared-predicate-leak-3c6m61]] ("one unparameterized clause widened
; THREE accept surfaces"). It was found by re-running the grep that memory
; prescribes instead of trusting the count it records — which is exactly what
; that memory says to do, and the count is now FIVE.
;
; WHAT IT GATES. `clang -O1` emits `a && b` as the poison-shielded
; `select i1 %a, i1 %b, i1 false`, which never observes `%b` when `%a` is false.
; The flatten canonicalizes that to a plain `and`, which DOES observe it — sound
; only if `%b` is provably DEFINED on those states. `coneDefinedAfterFlagDrop`
; is that proof, reached from `isSupportedCondTree` (E6's branch-condition claim
; gate) and from the `StrandedCondPhi` W witness. A call in the shielded cone is
; admitted iff it is a total function, i.e. iff the shared pure-callee proof
; passes — so an `icmp i80` inside `@leaf` was, pre-change, enough to make the
; whole region unclaimable at E6:
;   CQ_PREDMUX_DBG: pure-callee leaf fails at:   %eq = icmp eq i80 %m, 555
;   CQ_PREDMUX_DBG: leave @probe entry=entry merge=merge gate=E6-condtree at: br i1 %sc
; Note the GATE: `E6-condtree`, not `E4-dataflow`. A different gate, a different
; question, a different claim decision — which is why it needs its own fixture
; and could not ride S1's.
;
; WHY WIDENING IT IS RIGHT RATHER THAN MERELY HARMLESS: this proof is about
; DEFINEDNESS, and its own whitelist already admits `isa<CmpInst>` INLINE at any
; width, i80 included. A callee rejected only for carrying an `icmp i80` was
; being held to a stricter standard than the identical compare written inline —
; the widening removes that inconsistency rather than creating a new licence.
; (`icmp` is total: it has no poison-generating flags to drop and no undefined
; inputs, at 80 bits exactly as at 32.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s \
; RUN:  --implicit-check-not='br i1' --implicit-check-not='select i1'
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: env CQ_PREDMUX_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG --allow-empty

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
e:
  %z = zext i32 %a to i80
  %m = and i80 %z, 4294967295
  %eq = icmp eq i80 %m, 555
  %w = zext i1 %eq to i32
  ret i32 %w
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @leaf(i32 %q)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false     ; clang -O1's poison-shielded `a && b`
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:                                    ; 2 merge phis = the W3 claim witness
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m2
}

; The short-circuit select became the 3c6m.12 Toffoli conjunction of the two
; compare flags; the --implicit-check-not='select i1' on the RUN line is the
; canonicalization assertion (no i1 select survives).
;
; PRECISION, because the first draft of this line got it wrong and a Rule-13 lens
; caught it: the proof does NOT hoist anything. `%r = call @leaf` already sits in
; `entry`, ahead of the branch, so it already ran unconditionally in the input —
; and it must, since `%sc` is the region ENTRY terminator's condition and its
; whole backward cone dominates the branch by construction.
; `coneDefinedAfterFlagDrop` licenses OBSERVING the shielded value inside the
; rewritten `and`, never EXECUTING its producer somewhere it did not run.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_leaf_1(i32 %[[Q]])

; The TWO arm values, bound to the instructions that produce them. The Rule-13
; judge showed the first draft left the flag=1 copy source anonymous and CHECKed
; neither producer, so BOTH of this shape's verify-clean corruptions passed
; green: crossing the two merges' arm values, and replacing merge-1's arm value
; with the raw rail. Nothing in a copy-source slot may be a wildcard.
; CHECK:      %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 7)
; CHECK:      %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)

; Both conjuncts, named and in order, and the AND rail they land on. `%[[A]]`
; must read the RAIL and `%[[B]]` the CALL RESULT — swapping them would build the
; conjunction of the wrong two predicates, verify-clean.
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 0)
; CHECK:      %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])

; MERGE 1 (%p): controlled on the CONJUNCTION rail, flag=1 takes %[[ADD]],
; ¬flag takes the rail.
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[ADD]], i32 %[[OUT]])
; CHECK:      call void @cqrt_x(i32 %[[G]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:      call void @cqrt_x(i32 %[[G]])

; Rule 6 — the AND rail is cleared by the SAME Toffoli (self-inverse) before it
; is freed, then each conjunct is stripped by its out-first `_unc` naming the
; rail the next line frees.
; CHECK:      call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK:      call void @cqrt_free(i32 %[[G]])
; CHECK:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[B]], i32 %[[R]], i32 0)
; CHECK:      call void @cqrt_free(i32 %[[B]])
; CHECK:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[A]], i32 %[[Q]], i32 3)
; CHECK:      call void @cqrt_free(i32 %[[A]])

; MERGE 2 (%p2): its own freshly-minted conjunction rail, and flag=1 takes
; %[[MUL]] — NOT %[[ADD]]. Crossing the two merges' arm values is verify-clean
; and was the judge's mutant X; binding both sources here is what catches it.
; CHECK:      %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:      %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 0)
; CHECK:      %[[G2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_toffoli(i32 %[[A2]], i32 %[[B2]], i32 %[[G2]])
; CHECK:      %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[MUL]], i32 %[[OUT2]])
; CHECK:      call void @cqrt_x(i32 %[[G2]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[Q]], i32 %[[OUT2]])

; The two merged registers are what the measurement reads.
; CHECK:      call i32 @cq_template_add_i32(i32 %[[OUT]], i32 %[[OUT2]])

; The compare itself, in the callee's clone.
; CHECK-LABEL: define internal i32 @__cq_q_leaf_1(i32 %a)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %{{[a-zA-Z0-9_.]+}}, i80 4294967295)
; CHECK:      call i32 @cq_template_icmp_eq_i80_hl(i32 %[[M]], i80 555)

; Red-green, and it splits on the GATE NAME as well as on presence: pre-change
; this printed `gate=E6-condtree`, which no other fixture in the i80 family does.
; DBG-NOT: pure-callee leaf fails
; DBG-NOT: E6-condtree
