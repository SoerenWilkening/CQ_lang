; control_inplace_ry_reject_inloop_lifted_phi.ll — DECLINE. The IN-LOOP sibling
; of `control_inplace_ry_lifted_phi_after_region.ll`: the same classical guard
; (`if (OPQ) r = cq_phi(r, .5);`) placed INSIDE the rolled loop body, below the
; control-in-place Ry region.
;
; bd test_C_libtooling-drbq Increment 3, round-1 Rule-13 review finding F-L5-1.
; The flat form of this shape ACCEPTS (that fixture); this one does not, and the
; PAIR is the point — the fix to `resolveWireBase` repairs the ACYCLIC lift and
; deliberately buys nothing in the loop.
;
; WHY IT DECLINES, and why the decline is CORRECT rather than a leftover.
; PIPELINE ORDER decides it: `collapseFlattenedLoopRails` (round 2) runs at
; `CQLoweringPass.cpp:340`, `declineClassicalMuxes` — which owns the 5j5 lift —
; runs at `:399`. So when round 2 asks its step-(1) question, the classical join
; φ `%rj` is STILL IN THE MODULE and sits in the rail's LATCH lineage: the rail
; header φ `%r`'s latch incoming is `%rj`, and `peelInPlaceBase` stops at a φ, so
; the closed self-cycle `peelInPlaceBase(LatV) == &P` fails and round 2 refuses
; the loop LOUDLY with `kMsgCrossIter`. Teaching `collapseRailPhisIn` to peel a
; classical mux inside a rail cycle is a REAL widening of the loop accept class —
; it needs its own increment, its own probe family and its own Rule-13 round, and
; it is explicitly NOT what the F-L5-1 repair does.
;
; So: loud, accurately owned, Prime-Directive-correct over-decline. The
; pre-Inc-3 oracle also declines this program, one fence earlier (P1's
; `condition predates a non-diagonal gate`, before the loop stage is reached) —
; both binaries refuse it, only the owner moved.
;
; VERBATIM `clang -O1` output for
;   volatile int OPQ = 1;
;   int slice(void) { int q=3, r=7;
;                     q = cq_theta(q,0.5); r = cq_theta(r,0.25);
;                     for (int i = 0; i < 3; ++i) {
;                       if (q == 5) { r = cq_theta(r, 0.9); }
;                       if (OPQ)    { r = cq_phi(r, 0.5); }
;                       q = cq_theta(q, 0.3);
;                     }
;                     return cq_measure(q) + cq_measure(r); }
;
; Guard: LoopLowering::collapseRailPhisIn step (1). It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
;
; 3qlq(prep_a2): HAND DECISION — the register `cq_phi` here was NEVER the subject.
; This fixture pins an uncompute / mux / measurement-ordering / specialization rule
; and used `%r = cq_phi_<sfx>(%x, θ)` only as "a gate on a handle".  D1 removes that
; spelling, so the gate is re-spelled `cq_theta_<sfx>` — the OTHER in-place rotation
; on the same rail, which is what the corpus uses everywhere else for the same job.
; MEASURED on the Inc-1 binary: the swap reproduces this fixture's ORIGINAL asserted
; diagnostic, so the CHECK lines are UNCHANGED and the property is pinned by exactly
; the text it was pinned by before.  (prep_a measured the same 16 files against the
; pre-3qlq ORACLE; this is the independent re-measurement on the SUBJECT.)
; ⚠ Note what the swap does NOT preserve: Rz is DIAGONAL and Ry is not, so a rule
; that turned on diagonality would move.  None of these 16 do — that is what the
; character-for-character reproduction of the diagnostic establishes.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

@OPQ = global i32 1, align 4

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  br label %7

3:                                                ; preds = %20
  %4 = tail call i32 @cq_measure_si32(i32 noundef %22)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %21)
  %6 = add nsw i32 %5, %4
  ret i32 %6

7:                                                ; preds = %0, %20
  %8 = phi i32 [ 0, %0 ], [ %23, %20 ]
  %9 = phi i32 [ %2, %0 ], [ %21, %20 ]
  %10 = phi i32 [ %1, %0 ], [ %22, %20 ]
  %11 = icmp eq i32 %10, 5
  br i1 %11, label %12, label %14

12:                                               ; preds = %7
  %13 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 9.000000e-01)
  br label %14

14:                                               ; preds = %12, %7
  %15 = phi i32 [ %13, %12 ], [ %9, %7 ]
  %16 = load volatile i32, ptr @OPQ, align 4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %20, label %18

18:                                               ; preds = %14
  %19 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 5.000000e-01)
  br label %20

20:                                               ; preds = %18, %14
  %21 = phi i32 [ %19, %18 ], [ %15, %14 ]
  %22 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 3.000000e-01)
  %23 = add nuw nsw i32 %8, 1
  %24 = icmp eq i32 %23, 3
  br i1 %24, label %3, label %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations
