; control_predmux_reject_i80_cmp_qq.ll — DECLINE (bd 3c6m.61, the E4 i80-compare
; clause boundary): the Q+Q twin of control_predmux_accept_i80_cmp_arm.ll.
;
; i80 ships the `_hl` compare row (one handle + one literal) for all 10
; predicates, AND a QQ row. The fence is narrower than it first looks, and this
; was MEASURED rather than read off the source (a Rule-13 lens caught the first
; draft of this comment asserting a `lowerCompareImpl` i80 QQ fence that does not
; exist):
;   * Q+Q `icmp i80` in the DATA position lowers fine, to
;     `cq_template_icmp_<pred>_i80`.
;   * Q+Q `icmp i80` as a SELECT CONDITION cannot mint a flag —
;     `qqSelectLeafWidth` (CompareLowering.cpp) fences `i80` out of the
;     select-leaf grid.
; PredMux cannot cheaply distinguish those positions pre-flatten, so the E4
; clause uses ONE conservative gate for both: admit an arm-resident `icmp i80`
; only when exactly one operand is a ConstantInt. Here BOTH operands are tainted
; (`%man` is derived from `%bc`), so the region is LEFT unclaimed and the tainted
; diamond falls to the control detector's loud decline. Declining the
; data-position Q+Q form too is a deliberate over-decline (bd 3c6m.14.1).
;
; WHY THE TEST IS `isa<ConstantInt>` AND NOT A TAINT QUERY: PredMux runs
; PRE-flatten, where taint is not yet final — a currently-untainted
; region-internal value can become tainted by the flatten itself (the
; `valueWillTaintAfterFlatten` phenomenon the Inc-3 QROM index gate had to model).
; A ConstantInt is monotone: never tainted, before or after. Claiming on a taint
; query could therefore flatten a region whose compare only becomes Q+Q
; afterwards, and it would decline at `lowerCompareImpl` AFTER the mutation —
; verify-clean and loud, but a detect-before-mutate half-lower (Rule 9), exactly
; the class the Inc-1 fp128 finding closed.
;
; WHAT DISCRIMINATES, AND WHAT DOES NOT — stated precisely, because it was
; MEASURED against a pre-3c6m.61 plugin rather than assumed:
;   * The decline STRING does NOT discriminate. This input declined before
;     3c6m.61 too, on the old blanket "no i80 compare at all" exclusion, with a
;     byte-identical message.
;   * The CQ_PREDMUX_DBG leave line does NOT discriminate either — it is
;     `gate=E4-dataflow` at this same compare on BOTH plugins. (Contrast the
;     bd `oudq` leave fixtures, where the DBG line genuinely did split.)
;   * WHAT DOES: the DIFFERENTIAL against control_predmux_accept_i80_cmp_arm.ll.
;     The two files are the same region, same block structure, same claim
;     witness, differing in ONE operand — a ConstantInt there, `%bc` here — and
;     they land on OPPOSITE sides. That pair is the boundary evidence.
; The DBG pin below is therefore a FORWARD regression pin, not a red-green one:
; it fires if a later widening admits the Q+Q shape, or moves the leave to some
; other gate that merely happens to keep declining today. (`gate=`/`entry=`/
; `merge=` are contractual; the `at:` operand's SSA slot numbers are not, which
; is why it is matched loosely.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG

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
  %eq = icmp eq i80 %man, %bc             ; Q+Q i80 — no template row; E4 leaves
  %w = select i1 %eq, x86_fp80 %q, x86_fp80 0xK3FFF8000000000000000
  %k1 = fadd x86_fp80 %w, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                    ; 2 merge phis = the W3 claim witness
  %z = phi x86_fp80 [ %k1, %nan ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %w, %nan ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; NB the diagnostic is matched with NO interior wildcard: `{{.*}}` there would
; also match the DIFFERENT `nested control flow under quantum control` message,
; and the two are emitted by different owners.
; CHECK: error{{.*}}: cq controlled lowering: control flow under quantum control
;
; NO `CHECK-NOT: cq_template_*` here, deliberately. On a loud decline `opt`
; writes zero bytes to stdout, so under `not %cq-opt … 2>&1 | %filecheck` the
; ENTIRE FileCheck input is the one-line stderr diagnostic — a `CHECK-NOT` on an
; emitted symbol scans that line and can never fire. It reads as a
; nothing-was-lowered guarantee while asserting nothing (a Rule-13 lens finding).
; The real nothing-was-lowered evidence is the non-zero exit plus the DBG leave
; line below; a symbol-level guarantee would need `-o %t` and a separate scan.

; The discriminating half: the region must leave at E4-dataflow, ON this compare.
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=merge gate=E4-dataflow at:{{.*}}icmp eq i80
