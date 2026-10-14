; control_predmux_accept_i80_cmp_pred_sweep.ll — ACCEPT (bd 3c6m.14.6): the
; PREDICATE SWEEP for the arm-resident i80 `_hl` compare. The E4 clause
; (PredMuxFlatten.cpp, `isSpeculatableDataflow`) is predicate-BLIND —
;
;     if (OpTy->isIntegerTy(80))
;       return AdmitI80Compare && (isa<ConstantInt>(I.getOperand(0)) !=
;                                  isa<ConstantInt>(I.getOperand(1)));
;
; — so the surface it opens is all 10 icmp predicates at i80, in both operand
; orders. Before this fixture the whole tree pinned exactly TWO of the twenty
; cells on a CHECK line: `eq` handle-left (accept_i80_cmp_arm.ll) and `ugt`
; arriving via the `ult` flip (accept_i80_cmp_const_left.ll). Eight predicates
; and eighteen cells were held up by no fixture at all.
;
; Both halves of the grammar are load-bearing and neither is exercised by a
; single-predicate fixture:
;
;  (1) THE PREDICATE TOKEN. `compareName` (TemplateName.cpp) splices the
;      predicate between the op stem and the width. Every one of the 10 rows
;      ships `_hl`, `_hl_inv` and `_hl_unc` in the generated grid (measured:
;      60 defined `cq_template_icmp_*_i80*` symbols in libcq_templates.a =
;      10 preds x {qq,hl} x {fwd,inv,unc}).
;
;  (2) THE FLIP. There are NO `_lh` compare templates at ANY width, by design
;      (opcode_table.yaml compare rows carry no *_lh variant; 0 such symbols in
;      the archive). `lowerCompareImpl` therefore moves the handle to the LHS
;      and applies `flipPredicate` == `CmpInst::getSwappedPredicate`. The flip
;      must land on a predicate that is still in scope AND on a shipped i80 row,
;      or the emitter would `getOrInsertFunction` a phantom — verify-clean,
;      `opt` exit 0, LINK FAILURE at stage 3. @probe_const_left pins all 10
;      flips; @probe_handle_left pins all 10 unflipped rows as the control.
;
; EACH SLOT CARRIES A UNIQUE CONSTANT (LDBL_NBIT + slot). That is deliberate and
; load-bearing: with one shared constant an ordered CHECK can SLIDE FORWARD to a
; later line bearing the wanted predicate, so a `flipPredicate` deletion fails
; late (or, for a cyclic permutation, not at all). With unique constants the
; (predicate, constant) pair is unique and FileCheck goes red at the FIRST wrong
; slot. Every CHECK also requires the literal `call i32 @` / `call void @`
; prefix so the module-scope `declare` lines — all 10 symbols get one — can
; never satisfy a check.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi x86_fp80' < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

; Handle LEFT, ConstantInt right — the `_hl` shape reaches the template with the
; predicate UNCHANGED. Ten slots, ten predicates, ten distinct constants.
define x86_fp80 @probe_handle_left(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %nan, label %norm

nan:
  %bc = bitcast x86_fp80 %q to i80
  %man = and i80 %bc, 18446744073709551615
  %p0 = icmp eq i80 %man, 9223372036854775808
  %w0 = select i1 %p0, x86_fp80 %q, x86_fp80 0xK3FFF8000000000000000
  %p1 = icmp ne i80 %man, 9223372036854775809
  %w1 = select i1 %p1, x86_fp80 %w0, x86_fp80 0xK3FFF8000000000000000
  %p2 = icmp ugt i80 %man, 9223372036854775810
  %w2 = select i1 %p2, x86_fp80 %w1, x86_fp80 0xK3FFF8000000000000000
  %p3 = icmp uge i80 %man, 9223372036854775811
  %w3 = select i1 %p3, x86_fp80 %w2, x86_fp80 0xK3FFF8000000000000000
  %p4 = icmp ult i80 %man, 9223372036854775812
  %w4 = select i1 %p4, x86_fp80 %w3, x86_fp80 0xK3FFF8000000000000000
  %p5 = icmp ule i80 %man, 9223372036854775813
  %w5 = select i1 %p5, x86_fp80 %w4, x86_fp80 0xK3FFF8000000000000000
  %p6 = icmp sgt i80 %man, 9223372036854775814
  %w6 = select i1 %p6, x86_fp80 %w5, x86_fp80 0xK3FFF8000000000000000
  %p7 = icmp sge i80 %man, 9223372036854775815
  %w7 = select i1 %p7, x86_fp80 %w6, x86_fp80 0xK3FFF8000000000000000
  %p8 = icmp slt i80 %man, 9223372036854775816
  %w8 = select i1 %p8, x86_fp80 %w7, x86_fp80 0xK3FFF8000000000000000
  %p9 = icmp sle i80 %man, 9223372036854775817
  %w9 = select i1 %p9, x86_fp80 %w8, x86_fp80 0xK3FFF8000000000000000
  %k1 = fadd x86_fp80 %w9, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                  ; 2 merge phis = the W3 PredMux claim witness
  %z = phi x86_fp80 [ %k1, %nan ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %w9, %nan ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; ConstantInt LEFT — byte-identical to the above except the operand order. Every
; slot must come out with the SWAPPED predicate; eq/ne self-map, the other eight
; pair up. An unflipped emission here is a wrong-comparison silent miscompile.
define x86_fp80 @probe_const_left(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %nan, label %norm

nan:
  %bc = bitcast x86_fp80 %q to i80
  %man = and i80 %bc, 18446744073709551615
  %p0 = icmp eq i80 9223372036854775808, %man
  %w0 = select i1 %p0, x86_fp80 %q, x86_fp80 0xK3FFF8000000000000000
  %p1 = icmp ne i80 9223372036854775809, %man
  %w1 = select i1 %p1, x86_fp80 %w0, x86_fp80 0xK3FFF8000000000000000
  %p2 = icmp ugt i80 9223372036854775810, %man
  %w2 = select i1 %p2, x86_fp80 %w1, x86_fp80 0xK3FFF8000000000000000
  %p3 = icmp uge i80 9223372036854775811, %man
  %w3 = select i1 %p3, x86_fp80 %w2, x86_fp80 0xK3FFF8000000000000000
  %p4 = icmp ult i80 9223372036854775812, %man
  %w4 = select i1 %p4, x86_fp80 %w3, x86_fp80 0xK3FFF8000000000000000
  %p5 = icmp ule i80 9223372036854775813, %man
  %w5 = select i1 %p5, x86_fp80 %w4, x86_fp80 0xK3FFF8000000000000000
  %p6 = icmp sgt i80 9223372036854775814, %man
  %w6 = select i1 %p6, x86_fp80 %w5, x86_fp80 0xK3FFF8000000000000000
  %p7 = icmp sge i80 9223372036854775815, %man
  %w7 = select i1 %p7, x86_fp80 %w6, x86_fp80 0xK3FFF8000000000000000
  %p8 = icmp slt i80 9223372036854775816, %man
  %w8 = select i1 %p8, x86_fp80 %w7, x86_fp80 0xK3FFF8000000000000000
  %p9 = icmp sle i80 9223372036854775817, %man
  %w9 = select i1 %p9, x86_fp80 %w8, x86_fp80 0xK3FFF8000000000000000
  %k1 = fadd x86_fp80 %w9, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:
  %z = phi x86_fp80 [ %k1, %nan ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %w9, %nan ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; Every slot pins four things: the mint's predicate AND constant, that the
; compare reads the MASKED mantissa (never the raw bitcast — dropping the `and`
; silently changes the test), that the strip recomputes the SAME predicate from
; the SAME operands, and that the strip NAMES the rail the very next line frees
; (bd 8txa — CHECK-NEXT, because that adjacency is emitter-guaranteed).

; CHECK-LABEL: define x86_fp80 @probe_handle_left(
; CHECK:      %[[MAN:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %{{[a-zA-Z0-9_.]+}}, i80 18446744073709551615)
; CHECK:      %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i80_hl(i32 %[[MAN]], i80 9223372036854775808)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i80_hl(i32 %[[MAN]], i80 9223372036854775809)
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i80_hl(i32 %[[MAN]], i80 9223372036854775810)
; CHECK:      %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_uge_i80_hl(i32 %[[MAN]], i80 9223372036854775811)
; CHECK:      %[[F4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i80_hl(i32 %[[MAN]], i80 9223372036854775812)
; CHECK:      %[[F5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ule_i80_hl(i32 %[[MAN]], i80 9223372036854775813)
; CHECK:      %[[F6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i80_hl(i32 %[[MAN]], i80 9223372036854775814)
; CHECK:      %[[F7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i80_hl(i32 %[[MAN]], i80 9223372036854775815)
; CHECK:      %[[F8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i80_hl(i32 %[[MAN]], i80 9223372036854775816)
; CHECK:      %[[F9:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sle_i80_hl(i32 %[[MAN]], i80 9223372036854775817)
; bd r2j3.32: each slot's merge rail is the next slot's copy source, so the
; rails are reversed LIFO after the last reader and every flag strip is DEFERRED
; behind them: the strips arrive in REVERSE slot order, each still naming the
; rail the very next line frees.
; CHECK:      call void @cq_template_icmp_sle_i80_hl_unc(i32 %[[F9]], i32 %[[MAN]], i80 9223372036854775817)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F9]])
; CHECK:      call void @cq_template_icmp_slt_i80_hl_unc(i32 %[[F8]], i32 %[[MAN]], i80 9223372036854775816)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F8]])
; CHECK:      call void @cq_template_icmp_sge_i80_hl_unc(i32 %[[F7]], i32 %[[MAN]], i80 9223372036854775815)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F7]])
; CHECK:      call void @cq_template_icmp_sgt_i80_hl_unc(i32 %[[F6]], i32 %[[MAN]], i80 9223372036854775814)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F6]])
; CHECK:      call void @cq_template_icmp_ule_i80_hl_unc(i32 %[[F5]], i32 %[[MAN]], i80 9223372036854775813)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F5]])
; CHECK:      call void @cq_template_icmp_ult_i80_hl_unc(i32 %[[F4]], i32 %[[MAN]], i80 9223372036854775812)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F4]])
; CHECK:      call void @cq_template_icmp_uge_i80_hl_unc(i32 %[[F3]], i32 %[[MAN]], i80 9223372036854775811)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F3]])
; CHECK:      call void @cq_template_icmp_ugt_i80_hl_unc(i32 %[[F2]], i32 %[[MAN]], i80 9223372036854775810)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call void @cq_template_icmp_ne_i80_hl_unc(i32 %[[F1]], i32 %[[MAN]], i80 9223372036854775809)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK:      call void @cq_template_icmp_eq_i80_hl_unc(i32 %[[F0]], i32 %[[MAN]], i80 9223372036854775808)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F0]])

; The flip half. Source order is eq ne ugt uge ult ule sgt sge slt sle; the
; emitted order must be eq ne ult ule ugt uge slt sle sgt sge.
; CHECK-LABEL: define x86_fp80 @probe_const_left(
; CHECK:      %[[MAN:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %{{[a-zA-Z0-9_.]+}}, i80 18446744073709551615)
; CHECK:      %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i80_hl(i32 %[[MAN]], i80 9223372036854775808)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i80_hl(i32 %[[MAN]], i80 9223372036854775809)
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i80_hl(i32 %[[MAN]], i80 9223372036854775810)
; CHECK:      %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ule_i80_hl(i32 %[[MAN]], i80 9223372036854775811)
; CHECK:      %[[F4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i80_hl(i32 %[[MAN]], i80 9223372036854775812)
; CHECK:      %[[F5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_uge_i80_hl(i32 %[[MAN]], i80 9223372036854775813)
; CHECK:      %[[F6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i80_hl(i32 %[[MAN]], i80 9223372036854775814)
; CHECK:      %[[F7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sle_i80_hl(i32 %[[MAN]], i80 9223372036854775815)
; CHECK:      %[[F8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i80_hl(i32 %[[MAN]], i80 9223372036854775816)
; CHECK:      %[[F9:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i80_hl(i32 %[[MAN]], i80 9223372036854775817)
; bd r2j3.32: each slot's merge rail is the next slot's copy source, so the
; rails are reversed LIFO after the last reader and every flag strip is DEFERRED
; behind them: the strips arrive in REVERSE slot order, each still naming the
; rail the very next line frees.
; CHECK:      call void @cq_template_icmp_sge_i80_hl_unc(i32 %[[F9]], i32 %[[MAN]], i80 9223372036854775817)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F9]])
; CHECK:      call void @cq_template_icmp_sgt_i80_hl_unc(i32 %[[F8]], i32 %[[MAN]], i80 9223372036854775816)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F8]])
; CHECK:      call void @cq_template_icmp_sle_i80_hl_unc(i32 %[[F7]], i32 %[[MAN]], i80 9223372036854775815)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F7]])
; CHECK:      call void @cq_template_icmp_slt_i80_hl_unc(i32 %[[F6]], i32 %[[MAN]], i80 9223372036854775814)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F6]])
; CHECK:      call void @cq_template_icmp_uge_i80_hl_unc(i32 %[[F5]], i32 %[[MAN]], i80 9223372036854775813)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F5]])
; CHECK:      call void @cq_template_icmp_ugt_i80_hl_unc(i32 %[[F4]], i32 %[[MAN]], i80 9223372036854775812)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F4]])
; CHECK:      call void @cq_template_icmp_ule_i80_hl_unc(i32 %[[F3]], i32 %[[MAN]], i80 9223372036854775811)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F3]])
; CHECK:      call void @cq_template_icmp_ult_i80_hl_unc(i32 %[[F2]], i32 %[[MAN]], i80 9223372036854775810)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call void @cq_template_icmp_ne_i80_hl_unc(i32 %[[F1]], i32 %[[MAN]], i80 9223372036854775809)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK:      call void @cq_template_icmp_eq_i80_hl_unc(i32 %[[F0]], i32 %[[MAN]], i80 9223372036854775808)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F0]])
