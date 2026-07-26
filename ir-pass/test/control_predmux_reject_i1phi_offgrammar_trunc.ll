; control_predmux_reject_i1phi_offgrammar_trunc.ll — DECLINE probe (bd q2wk =
; 3c6m.14 L6 Inc 5, PRD §4.4b sub-rule (A), the STRICT-substrate row).
;
; Inc 5 admits an i1 PHI as a node of an E6 branch-condition tree, but ONLY when
; every incoming is inside the strict substrate grammar `isBooleanCondTree`
; (i1 constants; compare leaves over NON-i1 operands; distinct-operand and/or).
; `trunc i32 %q to i1` is a raw bit extract: it has NO flag-mint shape, and the
; boolean-algebra composer would hand `buildNegation` a node that is neither a
; cmp/and/or/xor nor a constant. So an i1 phi carrying a trunc must NOT be
; claimable as a branch condition — `recoverRegion` leaves at `E6-condtree` and
; the region falls through to the existing loud decline, char-for-char.
;
; The fence is LOAD-BEARING, not incidental: this exact CFG with the sole edit
; `%t = trunc i32 %q to i1` → `%t = icmp eq i32 %q, 3` (a grammar-conforming
; compare leaf) is CLAIMED and fully lowered by the Inc-5 pass — so the trunc
; incoming is the only reason this module declines. Both plugins (pre- and
; post-Inc-5) leave at the same gate for the same branch and emit the identical
; diagnostic: pre-Inc-5 because a PHI was not a cond-tree node at all,
; post-Inc-5 because the incoming is off-grammar.
;
; The sibling `control_predmux_i1phi_offgrammar_fallback.ll` pins the same
; grammar for an i1 phi feeding a SELECT condition; this one pins it for the
; harder E6 BRANCH-condition surface Inc 5 opened.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t  = trunc i32 %q to i1                  ; off-grammar: a raw bit, no flag-mint shape
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %sc, label %rhs
rhs:
  ; the bypass edge to %merge is what puts %sc (and its phi-conditioned
  ; terminator) INSIDE the region instead of making it the region's merge.
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %sc, label %merge
sc:
  %p = phi i1 [ true, %entry ], [ %t, %rhs ]
  br i1 %p, label %tb, label %merge
tb:
  %vt = add i32 %q, 1
  br label %merge
merge:
  %rm = phi i32 [ %vt, %tb ], [ %q, %sc ], [ %q, %rhs ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
