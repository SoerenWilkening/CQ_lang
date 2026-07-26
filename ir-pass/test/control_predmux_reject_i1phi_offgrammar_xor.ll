; control_predmux_reject_i1phi_offgrammar_xor.ll — DECLINE / STRICT-GRAMMAR
; FENCE (bd q2wk = 3c6m.14 L6 Inc 5, PRD §4.4b rule (A), the BRANCH-consumer
; side).
;
; Inc 5 (A) admits an i1 PHI as a condition-tree node via
; `isConvertiblePhiCond`, but ONLY when every incoming is admissible under the
; STRICT substrate grammar `isBooleanCondTree` (i1 constants; compare leaves
; over non-i1 operands; distinct-operand `and i1`/`or i1`). It deliberately
; does NOT use the PERMISSIVE `isSupportedCondTree`, which additionally admits
; xor-true and the select-form short-circuits. This fixture pins that gap with
; the smallest witness: `%n = xor i1 %ca, true` as one incoming of the i1 phi
; `%flag`, and `%flag` consumed by a `br i1` inside the region.
;
; WHY the strict grammar is load-bearing here: `isConvertiblePhiCond` is the
; CLAIM, and the phis it admits are recorded in `PredMuxRegion::BoolAlgPhis` so
; `convertPhis` takes the boolean-algebra path (∨ᵢ EP(eᵢ) ∧ vᵢ) for exactly
; those. Had the claim used the permissive grammar, `convertPhis`' own
; emit-time `isBooleanCondTree` check (scope-less, so xor-true is off-grammar
; there too) would fall back to the Inc-1 SELECT CHAIN — and `literal()` would
; then hand `buildNegation` a general `select i1 EP, v1, v2` whose arms are not
; the 0/1 constants its `cast<ConstantInt>` assumes. That is a BROKEN MODULE
; (Rule 2: verify-clean is not the gate; here not even verify-clean), not a
; decline. So this shape must still leave PredMux at E6-condtree and reach the
; existing loud decline — the Prime Directive posture, byte-for-byte unchanged
; from before Inc 5.
;
; SIBLING: control_predmux_i1phi_offgrammar_fallback.ll pins the SELECT-consumer
; version of this same fence (an off-grammar `trunc` incoming feeding a
; `select`); THIS fixture is the BRANCH-consumer version (an off-grammar
; xor-true incoming feeding a `br i1`), which is the path rule (A) newly walks.
;
; RED-GREEN NOTE: replacing the single incoming `%n` with the bare compare `%ca`
; (i.e. deleting the `xor`) makes this exact CFG ACCEPT and lower verify-clean
; under Inc 5 while still declining before it — so the fence sits precisely on
; the xor, not on some unrelated ladder rung.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %sideb
inner:
  %c2 = icmp eq i32 %q, 7
  br i1 %c2, label %ia, label %ib
ia:
  %ca = icmp slt i32 %q, 3
  %n  = xor i1 %ca, true                    ; permissive-only node: NOT strict grammar
  br label %ijoin
ib:
  %cb = icmp sgt i32 %q, 8
  br label %ijoin
ijoin:
  %flag = phi i1 [ %n, %ia ], [ %cb, %ib ]  ; off-grammar incoming ⇒ not convertible
  br i1 %flag, label %ja, label %jb         ; …and it is a BRANCH condition
ja:
  %va = add i32 %q, 3
  br label %jjoin
jb:
  %vb = mul i32 %q, 5
  br label %jjoin
jjoin:
  %vv = phi i32 [ %va, %ja ], [ %vb, %jb ]
  br label %merge
sideb:
  %u = mul i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %vv, %jjoin ], [ %u, %sideb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; PredMux leaves at gate=E6-condtree (`br i1 %flag`), identically before and
; after Inc 5, and the region falls through to the shipped nested-control
; decline. Nothing is lowered.
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
; CHECK-NOT: cqrt_alloc
; CHECK-NOT: cq_template_
