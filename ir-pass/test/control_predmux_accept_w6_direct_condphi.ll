; control_predmux_accept_w6_direct_condphi.ll — ACCEPT (bd oudq = 3c6m.14 L6
; Inc 6, W6): the stranding phi at the ROOT of the branch condition.
;
; The sibling accept (control_predmux_accept_w6_stranded_merge_condphi.ll) puts
; the merge's i1 phi at an `or` NODE of the downstream condition. `br i1 %phi`
; — the phi used DIRECTLY, with no tree around it — is a second live accept
; position, because `isSupportedCondTree` tests the `PHINode` case FIRST, before
; the constant, compare, and/or, xor-true and short-circuit-select cases. It is
; also the shape the fdlibm `__isnanl` early-exit takes whenever `clang -O1` does
; NOT fold the following `isinf`/`iszero` tests into the same `or` chain, so it is
; not a synthetic corner. Two delta-round lenses flagged it independently as an
; accept surface with no fixture: pinned here (Rule 12 — the shipped accept shape
; gets a fixture, not just the one the target cell happened to produce).
;
; Everything else matches the sibling: the upstream diamond leaves at
; `W-witness` before Inc 6, the downstream region rooted at %isn leaves at
; `E6-condtree` (its entry phi is never converted), and W6 breaks the deadlock by
; claiming the upstream one so `convertPhis(R.Merge)` turns the phi into the
; Inc-2 boolean algebra ∨ᵢ(EPᵢ ∧ vᵢ) = `and(%hi, %nan)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FLAT %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %hi = icmp eq i32 %q, 32767
  br i1 %hi, label %chk, label %isn        ; triangle: arm = %chk, merge = %isn

chk:
  %lo  = icmp ne i32 %q, 0
  %hb  = icmp ugt i32 %q, 7
  %nan = or i1 %lo, %hb
  br label %isn

isn:                                       ; MERGE of the upstream triangle …
  %isnan = phi i1 [ false, %entry ], [ %nan, %chk ]
  br i1 %isnan, label %out, label %body     ; ← the phi AS the whole condition

body:
  %c2 = icmp slt i32 %q, 3                 ; (W1 nested-tainted witness)
  br i1 %c2, label %arm, label %join
arm:
  %va = add i32 %q, 11
  br label %join
join:
  %vj = phi i32 [ %va, %arm ], [ %q, %body ]
  %vw = mul i32 %vj, 5
  br label %out

out:
  %r = phi i32 [ %q, %isn ], [ %vw, %join ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; `%isnan` becomes `hi ∧ (lo ∨ hb)` — the source predicate verbatim — and BOTH
; polarities of every leaf are minted, since the answer mux needs the predicate
; positive and the interior join mux needs it negated (the no-NOT invariant
; pushes each negation to the leaves).
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 32767)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 32767)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 0)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK-DAG: call i32 @cq_template_icmp_ugt_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_ule_i32_hl(i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_free(
; CHECK:     call i32 @cqrt_measure_i32(

; No conditional CFG survives anywhere in the function (the blocks that remain
; are joined by unconditional branches).
; FLAT:     define i32 @probe(
; FLAT-NOT: br i1
; FLAT-NOT: phi
; FLAT-NOT: select i1
