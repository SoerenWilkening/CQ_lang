; control_predmux_reject_i1cmp_shield_phi.ll — DECLINE (bd q2wk, PRD §4.4b
; rule (B), residual (d)). The shape NO adversarial lens found — it was caught by
; the Rule-13 JUDGE while adjudicating the other five, and it is the reason rule
; (B)'s fence had to be the "mirror what convertPhis actually does" form rather
; than a bare entry-block check.
;
; THE SHIELD. `%cc = icmp eq i1 %sp, false` is an i1-OPERAND compare.
; `isSupportedCompareLeaf` accepts it, so `isSupportedCondTree` treats the whole
; compare as an opaque LEAF and never recurses into `%sp` — which means NONE of
; `isConvertiblePhiCond`'s four fences (i1 type / not `R.Entry` / >1 unique
; incoming block / strict-grammar incomings) is ever consulted, even though
; `%sp` violates three of them at once: single incoming block, and a
; `trunc i32 %k to i1` incoming that is off the strict substrate grammar and
; derived from a classical function ARGUMENT.
;
; Rule (B)'s walk, however, DOES reach `%sp` (it recurses through the compare's
; operands). Before the fence it answered "region-internal phi ⇒ the flatten will
; taint it" and the region was claimed — and because every merge phi here is i1,
; `convertPhis` takes the boolean-algebra path and mints NO select, so there was
; nothing downstream to decline: the module COMPILED (rc 0) where the pre-q2wk
; plugin declined. The emitted network was verified semantically exact, so this
; was never a miscompile — but it was an accept strictly wider than the argument
; that justified it, which under the Prime Directive is the thing to close.
;
; With the fence, `valueWillTaintAfterFlatten` mirrors `convertPhis`: the
; single-incoming `%sp` RAUWs to `%tr`, so the walk recurses into `%tr` and finds
; only the classical argument `%k` — answer FALSE. The region leaves at
; `gate=E6-classicalbr`, untouched, and `ControlDetect` declines.
;
; Note the fence closes this WITHOUT tightening `isSupportedCondTree` to recurse
; through i1-operand compares. That was the alternative, and it was rejected: an
; `icmp` over i1 is non-canonical at `-O1` (instcombine rewrites it to `xor`), so
; tightening the permissive grammar would risk pre-existing accepts for a shape
; that cannot arise from the frontend. Where the shielded phi DOES convert to a
; tainted value, the claim is honest and the substrate's own `collectCondTree`
; adjudicates the i1-operand compare downstream — the accepted mutate-then-decline
; posture.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %k) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 5
  %tr = trunc i32 %k to i1               ; off-grammar AND classical
  br i1 %c0, label %a, label %sideb
a:
  br label %b
b:
  %sp = phi i1 [ %tr, %a ]               ; single incoming ⇒ RAUWs to %tr
  %cc = icmp eq i1 %sp, false            ; ← the i1-operand compare SHIELD
  br i1 %cc, label %t, label %f
t:
  %vt  = icmp eq i32 %q, 7
  %vt2 = icmp eq i32 %q, 70
  br label %merge
f:
  %vf  = icmp eq i32 %q, 9
  %vf2 = icmp eq i32 %q, 90
  br label %merge
sideb:
  %vs  = icmp eq i32 %q, 11
  %vs2 = icmp eq i32 %q, 110
  br label %merge
merge:                                   ; all-i1 phis ⇒ BoolAlg, no select minted
  %p1 = phi i1 [ %vt, %t ], [ %vf, %f ], [ %vs, %sideb ]
  %p2 = phi i1 [ %vt2, %t ], [ %vf2, %f ], [ %vs2, %sideb ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %s  = add i32 %z1, %z2
  %m  = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; Nothing lowered — detect-before-mutate.
; CHECK-NOT: cqrt_
; CHECK-NOT: cq_template_
