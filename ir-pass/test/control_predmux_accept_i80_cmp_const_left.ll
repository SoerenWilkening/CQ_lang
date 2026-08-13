; control_predmux_accept_i80_cmp_const_left.ll — ACCEPT (bd 3c6m.61): the second
; live position of the Inc-7 i80-compare clause, pinning the TWO things
; control_predmux_accept_i80_cmp_arm.ll does not exercise.
;
;  (1) The ConstantInt operand on the LEFT. `lowerCompareImpl` has no `_lh`
;      compare templates, so a classical-on-left compare is lowered by moving the
;      handle to the LHS and applying `flipPredicate` (`getSwappedPredicate`).
;      That flip must land on a predicate that is still in scope AND on a shipped
;      i80 row, or the emitter would `getOrInsertFunction` a phantom symbol —
;      verify-clean, `opt` exit 0, and a LINK FAILURE at stage 3. Here
;      `ult(K, %man)` must come out as `cq_template_icmp_ugt_i80_hl(%man, K)`.
;
;  (2) A predicate other than `eq`. The E4 clause is predicate-blind, so the
;      accept surface it opens is all 10 icmp predicates at i80; the generated
;      grid ships every one with `_hl`, `_hl_inv` and `_hl_unc` (verified against
;      runtime/cq_templates.h). `eq` alone would not witness that.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi x86_fp80' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @probe(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %nan, label %norm

nan:
  %bc = bitcast x86_fp80 %q to i80
  %man = and i80 %bc, 18446744073709551615
  %isn = icmp ult i80 9223372036854775808, %man   ; constant LEFT, predicate ult
  %w = select i1 %isn, x86_fp80 %q, x86_fp80 0xK3FFF8000000000000000
  %k1 = fadd x86_fp80 %w, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                  ; 2 merge phis = the W3 PredMux claim witness
  %z = phi x86_fp80 [ %k1, %nan ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %w, %nan ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; The handle moves to the LHS and `ult` flips to `ugt` — NOT an `_lh` symbol
; (there are none for compares) and NOT an unflipped `ult`.
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i80_hl(i32 %{{[a-zA-Z0-9_.]+}}, i80 9223372036854775808)
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[F]],
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[F]],
; CHECK:     call void @cqrt_x(i32 %[[F]])
; The strip must carry the SAME flipped predicate as the forward mint, or it
; would recompute a different function and leave the rail dirty at the free.
; CHECK:     call void @cq_template_icmp_ugt_i80_hl_unc(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i80 9223372036854775808)
; CHECK:     call void @cqrt_free(i32 %[[F]])
