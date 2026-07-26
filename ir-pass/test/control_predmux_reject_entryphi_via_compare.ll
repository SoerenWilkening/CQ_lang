; control_predmux_reject_entryphi_via_compare.ll — DECLINE (bd q2wk, PRD §4.4b
; rule (B)). The sibling of control_predmux_reject_i1phi_entry_block.ll: there the
; ENTRY-block phi is used DIRECTLY as a branch condition and rule (A)'s
; `isConvertiblePhiCond` fences it; here the same entry phi is hidden behind one
; `icmp`, so rule (A) never sees a phi at all and only rule (B)'s gate decides.
;
; This shape is the q2wk Rule-13 finding that FOUR of six independent adversarial
; lenses reported. `valueWillTaintAfterFlatten` answered "the flatten will taint
; this" for ANY region-internal phi — but `RegionFlattener::run()` converts the
; phis of every region block EXCEPT `R.Entry`, so an entry phi survives the
; flatten unconverted and the condition stays a CLASSICAL runtime i1. The E6
; gate was therefore admitting the region on a promise the code did not keep.
; The fix passes `R.Entry` into the shared predicate, so this declines at the
; CLAIM gate — detect-before-mutate, nothing flattened.
;
; Why it matters even though no lens could build a wrong unitary from it: with a
; surviving select the shape was caught downstream by SelectClassify's GATE-2
; untainted-leaf check, but in a select-free region (an i1 merge phi takes the
; boolean-algebra path) it COMPILED SILENTLY where the pre-q2wk plugin declined —
; sound, because a classical runtime operand rides the sanctioned `_hl` literal
; slot and is never promoted to a qubit handle, but an accept wider than the
; increment's own correctness argument. Over-declining is safe; that asymmetry is
; not.
;
; %eph is admissible on every OTHER count — 2 unique incoming blocks, integer,
; region-internal — so the ENTRY-block placement is the sole load-bearing
; rejection, exactly as in the rule-(A) twin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -passes=verify -disable-output %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %arg) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %g  = icmp sgt i32 %u0, 0            ; classical (arg-derived): roots no claim
  br i1 %g, label %pa, label %pb
pa:
  br label %rentry
pb:
  br label %rentry

rentry:                                ; ← the CLAIMED region entry (tainted %ct)
  %eph = phi i32 [ %arg, %pa ], [ 9, %pb ]     ; ← the ENTRY-BLOCK phi
  %ct  = icmp sgt i32 %q, 5
  br i1 %ct, label %arm, label %merge
arm:
  %cc = icmp eq i32 %eph, 0            ; ← entry phi reached through a compare
  br i1 %cc, label %t, label %f
t:
  %vt = add i32 %q, 1
  br label %ajoin
f:
  %vf = mul i32 %q, 3
  br label %ajoin
ajoin:
  %av = phi i32 [ %vt, %t ], [ %vf, %f ]
  %aw = add i32 %av, 7
  br label %merge

merge:                                 ; 2 merge phis = the PredMux claim witness
  %rm = phi i32 [ %av, %ajoin ], [ %q, %rentry ]
  %rn = phi i32 [ %aw, %ajoin ], [ 0, %rentry ]
  %sum = add i32 %rm, %rn
  %m  = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; Nothing lowered: the region is LEFT unclaimed, so no rail is allocated and no
; template is minted before the decline.
; CHECK-NOT: cqrt_
; CHECK-NOT: cq_template_
