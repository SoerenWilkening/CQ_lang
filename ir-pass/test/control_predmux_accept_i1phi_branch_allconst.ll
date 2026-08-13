; control_predmux_accept_i1phi_branch_allconst.ll — ACCEPT (bd q2wk =
; 3c6m.14 L6 Inc 5, PRD §4.4b): the SHIP-FLOOR shape, exercising sub-rules
; (A) AND (B) TOGETHER.
;
; %p is an i1 phi at a region-INTERNAL merge (%sc — inside the region, not the
; region ENTRY, not the region MERGE) whose incomings are ALL i1 CONSTANTS, and
; it feeds a conditional branch inside the region. This is what plain
; `clang -O1` emits for a short-circuit `a || b` it did not if-convert, nested
; under an outer tainted guard (s_log1p.c's `hx > 0 || hx <= 0xbfd2bec4`):
; the diamond survives and the disjunction is re-materialized as a phi over i1
; constants.
;
; BOTH new sub-rules are load-bearing here, and (B) is what BEFORE tripped on:
;   (B) because every incoming is a CONSTANT, %p is UNTAINTED, so the E6
;       "classical branch inside a tainted region" gate fired first — the
;       pre-change plugin declines at gate=E6-classicalbr on `br i1 %p`, NOT at
;       gate=E6-condtree. %p is region-internal and phi-derived, so
;       `valueWillTaintAfterFlatten` now proves the flatten itself taints it.
;   (A) then `isConvertiblePhiCond` admits %p as a condition-tree node (i1;
;       parent %sc in-region and != entry; 3 unique incoming blocks; every
;       incoming an i1 constant, in the strict `isBooleanCondTree` substrate
;       grammar) and RECORDS it, so `convertPhis` takes the boolean-algebra
;       path for exactly this phi.
;
; The conversion is ∨ᵢ (EP(eᵢ) ∧ vᵢ): the ∧true term survives as the bare edge
; predicate EP(%a→%sc) = c1 ∧ ¬c2, and BOTH ∧false terms (EP(%entry→%sc),
; EP(%b→%sc)) drop. So the branch is predicated on real tainted flags and the
; region flattens to a straight-line controlled-copy stream — nothing predicated
; on a classical i1 and no phi/br i1/select left behind.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %a, label %sc
a:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %b, label %sc
b:
  %c3 = icmp eq i32 %q, 42
  br i1 %c3, label %sc, label %sideb
sc:
  %p = phi i1 [ false, %entry ], [ true, %a ], [ false, %b ]
  br i1 %p, label %t, label %f
t:
  %vt = add i32 %q, 1
  br label %join
f:
  %vf = mul i32 %q, 3
  br label %join
join:
  %vj = phi i32 [ %vt, %t ], [ %vf, %f ]
  br label %merge
sideb:
  %u = mul i32 %q, 7
  br label %merge
merge:
  %rm = phi i32 [ %vj, %join ], [ %u, %sideb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; The five compare leaves the flattened predicate tree needs: c1 (sgt 5), c2
; (slt 100), c3 (eq 42) plus the De Morgan negations ¬c2 (sge 100) and ¬c1
; (sle 5) — the no-NOT invariant. ¬c2 is the direct witness of the SURVIVING
; ∧true term %p = EP(%a→%sc) = c1 ∧ ¬c2; ¬c1 and c3 remain only inside the
; block predicate P(%sc) (the ∨ of all three reaching edges), never as a %p
; term — that is the ∧false drop.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 42)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 100)
;
; The muxed arms route through a |0> flag rail under controlled copies —
; ¬flag by the self-inverse cqrt_x bracket:
; CHECK:     call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_x(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
;
; Nothing of the diamond survives — in particular no branch still predicated on
; the classical i1 phi:
; CHECK-NOT: br i1
; CHECK-NOT: phi i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
