; control_inplace_ry_stateprep_compound_cond.ll — ACCEPT (was
; `control_inplace_ry_reject_stateprep_compound_cond.ll`; `git mv`, IR
; byte-unchanged), bd test_C_libtooling-dm7f.52.
;
; ⚠ THE DECLINE BELOW IS HISTORY, AND ITS RETIREMENT TRIGGER FIRED AND WAS
; HONOURED. dm7f.52 admits a compound `and`/`or`/`xor`/logical-`select`
; condition for the in-place Ry / state-prep class (`classifyArms`
; `CondIsTree`), minted by `CondTreeEmit` and stripped LIFO. The trigger said F2
; must then be asked of EVERY LEAF and of every register any leaf pins:
;   * the INTEGER half already is — `LazyValueInfo::getConstantRangeOnEdge` and
;     `isImpliedCondition` decompose a logical `and`/`or` natively, so a register
;     pinned by any leaf on the edge is pinned here too (and the `CondWire`
;     exclusion is built from the tree's leaf-union `Prov`);
;   * the fp ANCHOR was not (it read only `BI->getCondition()` as an `FCmpInst`)
;     and now asks every `fcmp` the edge forces (`forcedFcmpLeaves`) — pinned by
;     `control_inplace_ry_reject_stateprep_tree_fcmp_leaf_derived.ll` and its
;     one-token accept control.
; This module's stream is analytic: f = [q > 5] ∧ [p < 9] on a fresh ancilla,
; cRy(f, r, .9) on the fresh SEED-0 rail, the exact LIFO strip, three proven-|0>
; frees. The arm's seed (`i32 0`) is the merge's pred incoming (F1) and no live
; tainted register is pinned to 0 on either edge (F2).
;
; ---- HISTORY (the decline this file used to pin, kept verbatim) ------------
; control_inplace_ry_reject_stateprep_compound_cond.ll — DECLINE: a COMPOUND
; `&&` condition (clang's `select i1`) over a state-prep arm.
;
; `classifyArms` refuses a non-`CmpInst` condition outright, before any arm is
; looked at. Measured IDENTICAL on the pre-Inc-4 oracle.
;
; ⚠ THIS FIXTURE IS ALSO F2's RETIREMENT TRIGGER, COMMITTED (PRD §14.2b). F2
; reads ONE compare and needs no `and`/`or` leaf walk ONLY BECAUSE compound
; conditions reach no control accept path. A compound condition DOES fold, and it
; folds a SECOND register too — `if (q == 5 && p == 3) { r = p; cq_theta(&r, .9); }`
; arrives as `cq_theta(i32 3, .9)` (probe `p08q`). THE DAY COMPOUND CONDITIONS
; ARE ADMITTED TO ANY CONTROL ACCEPT PATH, F2 MUST BE ASKED OF EVERY LEAF OF THE
; FLAG NETWORK, AND OF EVERY REGISTER ANY LEAF PINS — not just of the register
; the arm rotates. Written now rather than discovered later (the bd 8h7d.5
; F-1/F-3 discipline).
;
; (the old RUN line and its decline assertions are dropped from this quotation:
;  lit and FileCheck match their prefixes as substrings anywhere on a line.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  %c2 = icmp slt i32 %p, 9
  %cc = select i1 %c1, i1 %c2, i1 false
  br i1 %cc, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK:      %[[CQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: %[[CP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[P:[a-zA-Z0-9_.]+]], i32 9)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[CQ]], i32 %[[CP]], i32 %[[G]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[G]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[CQ]], i32 %[[CP]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[CP]], i32 %[[P]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CP]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[CQ]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CQ]])
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
