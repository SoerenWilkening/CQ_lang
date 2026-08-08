; control_predmux_reject_i80_cmp_purecallee_qq.ll — DECLINE (bd 3c6m.14.1): the
; Q+Q boundary of the widened pure-callee proof.
;
; THE DIFFERENTIAL PAIR, and the reason this file exists in this exact form.
; Per bd memory [[predmux-decline-fixture-discrimination]], a decline fixture
; that would have declined before the change too — with a byte-identical message
; — pins nothing on its own. This one is in that category: an ACCEPT-ONLY gate
; was widened, and this shape stayed outside it, so it declined before and
; declines now, identically. What makes it evidence is that it is
; control_predmux_accept_i80_cmp_purecallee.ll's module with ONE OPERAND CHANGED:
;
;     accept:  %eq = icmp eq i80 %man, 9223372036854775808   ; one ConstantInt ⇒ _hl
;     this:    %eq = icmp eq i80 %man, %other                ; two handles     ⇒ QQ
;
; Same callee, same caller, same region, same claim witness, opposite verdicts.
; That pair IS the boundary; neither half may be edited without the other.
;
; WHY IT MUST STAY DECLINED. bd 3c6m.61 measured (correcting its own first
; draft): i80 DOES ship a QQ compare row, and a Q+Q `icmp i80` in the DATA
; position lowers fine — what is fenced is the SELECT-LEAF flag mint,
; `qqSelectLeafWidth` in CompareLowering.cpp, which declines width "i80". A
; claimed region carrying a Q+Q i80 compare that feeds a select would therefore
; flatten and only THEN decline: still loud, but POST-MUTATION, which is the
; detect-before-mutate half-lower the Inc-1 fp128 finding closed. `@leaf` here
; puts the compare in exactly that position. The proof cannot cheaply tell the
; two positions apart (the consuming select may not exist yet), so ONE
; conservative rule — exactly one ConstantInt operand — covers both. Splitting
; them is (C), left open by bd 3c6m.14.1.
;
; The DBG line is the discriminating evidence here, and it does NOT split
; against the pre-change plugin — it is a FORWARD regression pin. It fires if a
; later widening opens the Q+Q position, and it names the exact instruction, so
; it cannot be satisfied by a decline arriving from somewhere else.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

; Identical to the accept sibling's @leaf except that the compare's second
; operand is derived, not constant.
define x86_fp80 @leaf(x86_fp80 %v) {
e:
  %bc = bitcast x86_fp80 %v to i80
  %man = and i80 %bc, 18446744073709551615
  %other = or i80 %bc, 9223372036854775808
  %eq = icmp eq i80 %man, %other
  %r = select i1 %eq, x86_fp80 %v, x86_fp80 0xK3FFF8000000000000000
  ret x86_fp80 %r
}

define x86_fp80 @probe(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %arm, label %norm

arm:
  %r = call x86_fp80 @leaf(x86_fp80 %q)
  %k1 = fadd x86_fp80 %r, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                  ; 2 merge phis = the W3 claim witness
  %z = phi x86_fp80 [ %k1, %arm ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %r, %arm ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; No interior wildcard: `{{.*}}control flow under quantum control` would also
; match the `nested` message, which a different owner emits.
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

; DBG: CQ_PREDMUX_DBG: pure-callee leaf fails at:{{.*}}icmp eq i80 %man, %other
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=merge gate=E4-dataflow at:{{.*}}call x86_fp80 @leaf
