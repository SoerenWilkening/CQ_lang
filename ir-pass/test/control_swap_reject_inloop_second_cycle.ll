; control_swap_reject_inloop_second_cycle.ll — DECLINE (bd test_C_libtooling-8h7d.5,
; gate (D) of `ControlDetect::flatRegionRollableInLoop`). A flat tainted-condition
; phase diamond whose entry sits on an IRREDUCIBLE SUB-CYCLE that is NESTED INSIDE
; a perfectly ordinary natural loop.
;
; THIS IS THE PROBE THAT SHOWS WHY GATE (A) IS NOT ENOUGH. Gate (A) asks
; `LI.getLoopFor(Pred)` for a natural loop and gate (B) asks that every region
; block sit at its depth — and BOTH PASS HERE, because the outer `head → … →
; olatch → head` loop is natural and `LoopInfo` puts every block of the
; irreducible inner cycle at that one depth (an irreducible cycle is not a loop,
; so `getLoopFor` reports the enclosing one). The region would then be flattened
; into a cycle that `LoopLowering`'s rail analysis, `markIfRailLocal` and
; `FreePoint`'s back-edge reject — all `LoopInfo`-gated — CANNOT SEE, which is
; precisely the hazard the d8jl guard's irreducible half exists for.
;
; The `%pred`/`%merge`/`%x` cycle has TWO entries (`%head` branches into `%pred`
; AND into `%x`), so no block dominates it and it is irreducible — the clang -O1
; shape of a `goto` into the middle of a loop body. Gate (D) re-runs the
; `regionEntryInLoop` reachability with the OUTER loop's back edge and exits cut,
; reaches `%pred` again, and declines.
;
; MEASURED, so the fixture cannot silently start passing for the wrong reason:
; deleting the second entry edge (`br i1 %ec, …` → `br label %pred`) makes the
; inner cycle NATURAL and the identical region then LOWERS (`opt` exit 0). So
; gate (D) — not (A), (B) or (C) — is what refuses this one.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: Broken module
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %x0, double %b, i32 %n, i32 %e) {
entry:
  br label %head
head:                                    ; preds = %entry, %olatch  (natural loop header)
  %i = phi i32 [ 0, %entry ], [ %inext, %olatch ]
  %ec = icmp eq i32 %e, 0
  br i1 %ec, label %pred, label %x       ; TWO entries into {pred, arm, merge, x}
pred:                                    ; preds = %head, %x
  %q = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5                ; TAINTED (quantum) condition
  br i1 %c, label %arm, label %merge
arm:                                     ; preds = %pred
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:                                   ; preds = %arm, %pred
  %qm = phi i32 [ %g, %arm ], [ %q, %pred ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  br label %x
x:                                       ; preds = %head, %merge
  %d = phi i32 [ 0, %head ], [ %m, %merge ]
  %dc = icmp sgt i32 %d, 0
  br i1 %dc, label %pred, label %olatch  ; the irreducible back edge into %pred
olatch:                                  ; preds = %x
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %head, label %exit
exit:
  ret i32 %i
}
