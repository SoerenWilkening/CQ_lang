; control_predmux_leave_w6_selectchain_phi.ll — LEAVE (bd oudq = 3c6m.14 L6
; Inc 6, W6): the CONVERTIBILITY half of the new claim witness.
;
; W6's promise is that claiming the upstream region turns the stranding phi into
; something the downstream branch can use as a condition tree — i.e. the Inc-2
; BOOLEAN ALGEBRA ∨ᵢ(EPᵢ ∧ vᵢ), whose nodes are and/or over compare leaves. A phi
; `convertPhis` sends down its OTHER path — the Inc-1 chained `select` — buys the
; downstream claim nothing: `isSupportedCondTree` has no general `select i1` node
; (only the two poison-shielded short-circuit forms), so the downstream region
; would leave at `E6-condtree` exactly as before, and the upstream claim would be
; pure claim-order churn on a still-declining module.
;
; The shipped gate gets that for free, because it asks the question with the
; grammar itself: W6 fires only on
;   isSupportedCondTree(cond, 0, &Convertible) && !isSupportedCondTree(cond, 0, &Downstream)
; over the scopes `{InRegion={Mg}, Entry=nullptr}` and `{InRegion={Mg},
; Entry=Mg}`. Here the phi's `%chk` incoming is a `trunc i32 %q to i1`, which
; `isBooleanCondTree` rejects inside `isConvertiblePhiCond` (no trunc/xor/select
; leaves) — so the phi is inadmissible under BOTH scopes, the `Convertible` call
; is false, and the witness does not fire. `convertPhis` would indeed have sent
; this phi down its Inc-1 select-chain path. The module keeps today's decline,
; byte-identical to the pre-oudq plugin.
;
; This mirrors the emit-side pin control_predmux_i1phi_offgrammar_fallback.ll one
; level up: same off-grammar incoming, but here it is the CLAIM that must notice.
;
; WHAT DISCRIMINATES (measured — the decline STRING does not): with the
; grammar check relaxed so W6 fires here, the upstream flattens to the Inc-1
; select chain `select i1 %ne, i1 false, i1 %t`, the downstream branch is still
; unusable as a cond tree (`isSupportedCondTree` has no general `select i1`) and
; the module declines with the SAME `nested control flow` string. The Rule-13
; prose-vs-code lens caught the first draft of this header claiming otherwise.
; The DBG line at the bottom is therefore the actual pin: it asserts the upstream
; region is LEFT at `W-witness`, which is exactly what the guard buys.
;
;
; DECLINE-STRING UPDATE (bd hcrg, convertibility half): this module used to decline at DETECTION
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
  br i1 %hi, label %chk, label %isn

chk:
  %t = trunc i32 %q to i1                  ; ← OFF-GRAMMAR incoming
  br label %isn

isn:                                       ; merge — the would-be W6 phi
  %isnan = phi i1 [ false, %entry ], [ %t, %chk ]
  %inf   = icmp eq i32 %q, 100
  %c1    = or i1 %inf, %isnan              ; read at an `or` tree node …
  br i1 %c1, label %out, label %body       ; … by a tainted branch

body:                                      ; a nested tainted region downstream
  %c2 = icmp slt i32 %q, 3
  br i1 %c2, label %arm, label %join
arm:
  %va = add i32 %q, 11
  br label %join
join:
  %vj = phi i32 [ %va, %arm ], [ %q, %body ]
  br label %out

out:
  %r = phi i32 [ %q, %isn ], [ %vj, %join ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: value-arm swap-route under quantum control
; (Deliberately NO trailing "no rail was allocated" negative checks here, unlike
; most decline fixtures in this suite: `opt` writes ZERO bytes of module on a
; `DS_Error`, so FileCheck only ever scans the stderr line and such a check can
; never fail — it reads as detect-before-mutate evidence while proving nothing.
; The `gate=` DBG line below is the real witness that the region was LEFT.)

; The upstream diamond is LEFT — the discriminating pin for the convertibility
; half of W6 (with the guard gone this leave disappears; the decline string does
; not change, so only this line detects the regression).
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=isn gate=W-witness
