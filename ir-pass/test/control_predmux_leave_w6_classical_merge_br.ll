; control_predmux_leave_w6_classical_merge_br.ll — LEAVE (bd oudq = 3c6m.14 L6
; Inc 6, W6): the TAINTED-MERGE-BRANCH half of the new claim witness.
;
; W6 claims an upstream br region only when the merge's own branch is a TAINTED
; conditional br. That gate is what keeps the witness inside the anti-overlap
; envelope: `ControlDetect::recoverRegion` declines a region whose merge ends in
; a TAINTED cond branch as `RegionShape::Nested` (it tests `hasTaintedCondBranch`
; on both successors before any shape match, and a diamond's merge IS a
; successor), so W6 can only claim shapes that already decline. Flip that branch
; to a CLASSICAL condition and the very same CFG is a shipped-owner shape:
; `recoverRegion` returns `RegionShape::Diamond` and `classifyArms` owns the
; verdict — here a precise `value-arm swap-route` decline, byte-identical on the
; pre- and post-oudq plugins.
;
; The geometry is the accept twin's
; (control_predmux_accept_w6_stranded_merge_condphi.ll) — same diamond, same sole
; 2-incoming i1 merge phi read at an `or` cond-tree node in the merge block.
; ONLY the taint of the merge branch differs: `%lo` and `%inf` are built from the
; UNTAINTED argument `%u0`, so `%isnan` and `%c1` never enter `Taint.Tainted` and
; `Taint.Tainted.count(MgBI->getCondition())` is false.
;
; DELETE-THE-GUARD (measured, not argued): with the taint half removed, W6 fires,
; the upstream flattens (`%isnan` → `and(%hi, %lo)`) and the disposition MOVES —
; the shipped owner loses its diamond and the module declines the generic
; `control flow under quantum control` instead. BOTH pins below therefore fire:
; the CHECK line (the decline string changes) and the DBG line (the
; `gate=W-witness` leave disappears).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %hi = icmp eq i32 %q, 32767              ; TAINTED — the shipped-owner diamond
  br i1 %hi, label %chk, label %isn

chk:
  %lo = icmp ne i32 %u0, 0                 ; CLASSICAL (argument-derived)
  br label %isn

isn:                                       ; merge — sole 2-incoming i1 phi
  %isnan = phi i1 [ false, %entry ], [ %lo, %chk ]
  %inf   = icmp eq i32 %u0, 100            ; CLASSICAL
  %c1    = or i1 %inf, %isnan              ; read at an `or` tree node …
  br i1 %c1, label %out, label %body       ; … by a CLASSICAL branch: not W6's

body:
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

; The upstream diamond is LEFT — this is the line that discriminates the taint
; half of W6 (without it the region would be claimed and this leave would vanish).
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=isn gate=W-witness
