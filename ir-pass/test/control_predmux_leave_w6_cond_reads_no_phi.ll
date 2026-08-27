; control_predmux_leave_w6_cond_reads_no_phi.ll — LEAVE (bd oudq = 3c6m.14 L6
; Inc 6, W6): the "reads a phi this claim would CONVERT" half of the witness.
;
; W6 claims an upstream br region when the merge's own TAINTED conditional
; branch reads — at a cond-tree NODE — an i1 phi the claim would convert. BOTH
; halves are load-bearing, and this file pins the second one. Here the merge
; block does host the sole 2-incoming i1 phi and does end in a tainted branch,
; but that branch's condition is a plain compare on the rail (`icmp slt %q, 3`)
; and never reads the phi: the downstream region rooted at %isn is therefore NOT
; stranded on an entry phi — it leaves for its own, unrelated reasons — so
; claiming the upstream diamond would buy nothing and would only move the claim
; order (bd 8dwo) on a shape no PredMux gate needs. The witness must not fire.
;
; A blanket "merge ends in a tainted br" witness WOULD fire here, so this is the
; discriminating fixture for the phi-reading condition. MEASURED, both ways: with
; the condition, the module keeps today's `nested control flow` decline
; (`ControlDetect::recoverRegion` sees a tainted cond branch on the merge
; successor and returns `RegionShape::Nested`) and the output is byte-identical
; to the pre-oudq plugin's; without it, the upstream flattens and the module
; declines the generic `control flow under quantum control` instead — it does NOT
; compile, so the CHECK line below (and the DBG leave) is what detects the
; regression, not a compile/decline flip. (An earlier draft of this header said
; "the module compiles"; the Rule-13 prose-vs-code lens measured otherwise.)
;
;
; DECLINE-STRING UPDATE (bd hcrg, phi-reading half): this module used to decline at DETECTION
; with `nested control flow` — `recoverRegion` saw a tainted conditional branch
; on the merge successor and returned `RegionShape::Nested`. hcrg reclassified
; that signal as SEQUENTIAL, so the upstream diamond is now recovered as a flat
; region and declines one step later, in ArmClassify, on its own arm content
; (`value-arm swap-route`). Still a loud decline, one stage further down.
;
; THIS FILE'S PIN IS UNAFFECTED, which is the point of having it: the assertion
; that matters is the `gate=W-witness` DBG line — the header above already says
; the decline STRING does not discriminate the W6 guard. The CHECK line is
; updated to the string the code now emits so the two cannot drift.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %hi = icmp eq i32 %q, 32767
  br i1 %hi, label %chk, label %isn        ; diamond: arm = %chk, merge = %isn

chk:
  %lo = icmp ne i32 %q, 0
  br label %isn

isn:                                       ; merge — sole 2-incoming i1 phi …
  %isnan = phi i1 [ false, %entry ], [ %lo, %chk ]
  %c1    = icmp slt i32 %q, 3              ; … which the branch does NOT read
  br i1 %c1, label %out, label %body

body:
  %z = zext i1 %isnan to i32               ; the phi is DATA here, not a cond node
  %w = mul i32 %z, 5
  br label %out

out:
  %r = phi i32 [ %q, %isn ], [ %w, %body ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: value-arm swap-route under quantum control
; (Deliberately NO trailing "no rail was allocated" negative checks here, unlike
; most decline fixtures in this suite: `opt` writes ZERO bytes of module on a
; `DS_Error`, so FileCheck only ever scans the stderr line and such a check can
; never fail — it reads as detect-before-mutate evidence while proving nothing.
; The `gate=` DBG line below is the real witness that the region was LEFT.)

; The upstream diamond is LEFT — the discriminating pin for the phi-reading half
; of W6 (a blanket "merge ends in a tainted br" witness would claim it and this
; leave would vanish).
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=isn gate=W-witness
