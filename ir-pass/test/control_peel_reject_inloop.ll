; control_peel_reject_inloop.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, **P9 — A DELIBERATE ADDITION TO SCOPE §3's P1-P8
; PARTITION**): the fused 2-phi region sits inside a classically-bounded loop.
; `regionEntryInLoop` (the reducibility-INDEPENDENT cycle walk, not `LoopInfo` —
; an irreducible cycle has no `LoopInfo` loop) refuses it.
;
; ⚠ WHY THE EXTRA CLAUSE, AND WHY IT IS THE CONSERVATIVE DIRECTION. Every measured
; member of the peel's population is straight-line. An in-loop 2-phi merge declines
; `control flow` TODAY; peeling it would hand the flattener a region that
; `flatRegionRollableInLoop` may ROLL IN PLACE (bd 8h7d.5) with a peeled `select`
; and a freshly cloned tainted compare in the loop BODY — a combination nothing in
; the tree has measured, in the one neighbourhood where CLAUDE.md's record is eight
; findings over six adversarial rounds on one function (the per-activation rail
; leaks, which stage 2b is structurally blind to). The 4.4 select is itself
; loop-legal (bd 9ymx), so this is not a claim that the shape is unsound — it is a
; refusal to widen two axes at once. Widening P9 is a follow-on row with its own
; adversarial rounds.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`), one
; row of its P1-P9 DECLINE PARTITION. The peel is ACCEPT-ONLY and NEVER diagnoses:
; a shape that fails any clause is left BYTE-UNTOUCHED and reaches its existing
; loud owner unchanged. Over-declining is safe (Prime Directive); the peel's job is
; to remove a BOOKKEEPING over-decline, not to widen the accept class.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @example() {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %hdr
hdr:
  %i = phi i32 [ 0, %entry ], [ %in, %lat ]
  %acc = phi i32 [ 0, %entry ], [ %s, %lat ]
  %c = icmp eq i32 %q, 1
  br i1 %c, label %m, label %a
a:
  tail call void @cq_phi(double noundef 7.000000e-01)
  br label %m
m:
  %mux = phi i32 [ 5, %a ], [ 2, %hdr ]
  %mux2 = phi i32 [ 9, %a ], [ 4, %hdr ]
  %s = add nsw i32 %acc, %mux
  br label %lat
lat:
  %in = add nuw nsw i32 %i, 1
  %e = icmp eq i32 %in, 4
  br i1 %e, label %out, label %hdr
out:
  %r = tail call i32 @cq_measure_si32(i32 noundef %q)
  ret i32 %r
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
