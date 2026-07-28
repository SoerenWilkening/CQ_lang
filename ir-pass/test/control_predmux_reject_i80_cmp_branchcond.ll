; control_predmux_reject_i80_cmp_branchcond.ll — DECLINE (bd 3c6m.61, the OTHER
; E4 i80-compare clause boundary): 3c6m.61 widened the ARM-RESIDENT (dataflow)
; compare only. An `icmp i80` used as a tainted BRANCH CONDITION is a different
; job — PredMux would have to build BOTH polarities of it as an edge literal
; (the De Morgan leaf-inversion of §4.3) and feed it to the 3c6m.12 flag-mint
; network — so `isSupportedCompareLeaf`, the leaf predicate of E6's
; `isSupportedCondTree`, is deliberately NOT widened: it still caps integers at
; 64 bits and the region leaves at `E6-condtree`.
;
; No measured libm cell needs this shape (hypotl's two i80 compares are both arm
; selects), and over-declining a shape we did not set out to build is correct —
; Rule 17's decline belongs to inputs outside the target shape. The sibling
; FLAT-diamond form (an i80 compare as the ROOT branch condition, no PredMux
; involved) declines identically today via SelectClassify/ArmClassify; both are
; tracked as an additive widening, not correctness debt.
;
; As with the Q+Q sibling, and MEASURED the same way: neither the decline string
; nor the CQ_PREDMUX_DBG leave line discriminates pre- vs post-3c6m.61 — both are
; byte-identical on both plugins. The DBG pin below is a FORWARD regression pin.
; Its value is that it names WHICH gate holds this shape: `E6-condtree`, i.e. the
; leaf predicate `isSupportedCompareLeaf` — NOT the E4 clause this increment
; widened. So if someone later widens `isSupportedCompareLeaf` to admit i80, this
; line fails and forces that to be a deliberate, reviewed decision rather than a
; silent side effect.
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
  br i1 %c, label %outer, label %skip      ; inner tainted br below = the W1 witness

outer:
  %bc = bitcast x86_fp80 %q to i80
  %man = and i80 %bc, 18446744073709551615
  %ic = icmp eq i80 %man, 9223372036854775808
  br i1 %ic, label %in1, label %in2        ; i80 BRANCH condition — E6-condtree leaves

in1:
  %a = fadd x86_fp80 %q, 0xKBFFE8000000000000000
  br label %merge

in2:
  %b = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

skip:
  %d = fsub x86_fp80 %q, 0xK3FFF8000000000000000
  br label %merge

merge:
  %z = phi x86_fp80 [ %a, %in1 ], [ %b, %in2 ], [ %d, %skip ]
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %z)
  ret x86_fp80 %m
}

; Pinned character-for-character, with NO interior wildcard: this shape declines
; with the NESTED message specifically, and an interior `{{.*}}` would silently
; accept the plain `control flow under quantum control` from a different owner
; too. (No `CHECK-NOT` on emitted symbols — see the sibling qq fixture for why
; such a check is structurally vacuous on a decline path.)
; CHECK: error{{.*}}: cq controlled lowering: nested control flow under quantum control

; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=merge gate=E6-condtree at:{{.*}}br i1 %ic
