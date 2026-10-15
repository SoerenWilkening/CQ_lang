; control_predmux_reject_notcond_no_rail.ll — DECLINE (bd test_C_libtooling-fn1q
; increment 2, Rule-13 round 1 finding P2-1). THE SCOPE FENCE ON THE ARM-SWAP FOLD.
;
; A multi-phi tainted diamond whose branch condition is the grammar's own NOT
; spelling, `xor %cmp, true`, with NO RAIL ANYWHERE IN THE MODULE. It declines, and
; this fixture exists to keep it declining.
;
; ⚠ THE FIRST SPELLING OF THE FOLD TOOK THIS MODULE, AND THE COMMENT THAT SAID IT
; COULD NOT WAS THE DEFECT. Increment 2 folds `select(¬c,T,F)` to `select(c,F,T)` at
; the flatten's select site, to pay for the `xor %rail, true` its own `buildNegation`
; arm emits. The shipped comment asserted, as a load-bearing SCOPE argument, that
; `xor X, true` reaches that site "from NOTHING BUT that rail arm ... narrow by
; construction, not by a filter". It enumerated `buildNegation`'s four behaviours and
; stopped. It omitted the OTHER producer: `literal()` is `canonicalizePred(cond)`, and
; `canonicalizePred` has NO xor arm — it returns such a condition UNCHANGED. E6 admits
; `xor X, 1` in its own right. So this module delivered a bare xor to the fold and
; went from the ORACLE's loud `control flow` decline to an ACCEPT.
;
; ⚠ THE ACCEPT WAS SEMANTICALLY CORRECT, AND THAT IS NOT THE POINT. The fold is a
; sound identity; the objection is that it is an accept-direction widening OUTSIDE
; this increment's stated scope, shipped with no fixture, no probe family and no
; round — and the corpus could not see it: of 2126 fixtures exactly ONE carries an
; `xor i1 …, true` feeding a `br`, and none on a claimable region. An instrument is
; blind in the shape nobody has pointed it at (L10). The fold now REQUIRES the xor's
; operand to be a rail leaf, which makes it exactly as wide as the `buildNegation`
; arm it exists to pay for.
;
; ⚠ RETIREMENT TRIGGER (L8): admitting a general `xor X, true` edge predicate is a
; deliberate, separate increment owing its own red-green pair. On the day it lands
; this file becomes an ACCEPT emitting four controlled-copy merges with the two arms
; exchanged. RE-DERIVE IT THEN; DO NOT DELETE IT.
;
; ⚠ FLIPPED TO AN ACCEPT by bd test_C_libtooling-dm7f.77 — the retirement
; trigger above, re-derived as it asks (the file keeps its name, L8). The general
; `xor X, true` condition landed as its own increment with its own red-green pair
; (the REGISTER CONDITION, RegCondLeaf.h; fixtures control_regcond_*), NOT as a
; widening of the arm-swap fold, which still requires a rail operand. The peel
; turns the four merge φ into four selects on `%n = xor %c, true`; the condition
; is a fresh register (`xor_i1_hl(cmp, 1)`) read through four copy flags, giving
; four controlled-copy merges `out_k = !c ? 2 : k`, each flag uncopied and freed,
; then `!c` and the compare discharged after their last control read and freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define i32 @probe(
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 1)
; CHECK-NEXT:  %[[N:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1_hl(i32 %[[C]], i1 true)
; CHECK-COUNT-8: call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:       call void @cqrt_cnot(i32 %[[N]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT:  call void @cq_template_xor_i1_hl_unc(i32 %[[N]], i32 %[[C]], i1 true)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[N]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[C]], i32 %[[H]], i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C]])
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  %n = xor i1 %c, true
  br i1 %n, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %c6 = phi i32 [ 2, %arm ], [ 7, %entry ]
  %d7 = phi i32 [ 2, %arm ], [ 8, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %m3 = call i32 @cq_measure_si32(i32 %c6)
  %m4 = call i32 @cq_measure_si32(i32 %d7)
  %m5 = call i32 @cq_measure_si32(i32 %q)
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %m3
  %s3 = add i32 %s2, %m4
  %s4 = add i32 %s3, %m5
  ret i32 %s4
}

