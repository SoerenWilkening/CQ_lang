; loop_carried_handle_accept_guarded.ll — bd `test_C_libtooling-h1ip`, the
; GUARDED (rotated) loop-carried handle: a RUNTIME trip bound.
;
; ⚠ THIS FILE WAS `loop_carried_handle_reject_guarded.ll` UNTIL 2026-09-20 AND IT
; IS RE-DERIVED, NOT REPLACED.  Its own L8 trigger said *"hoisting the alloc ABOVE
; the guard and rewriting the exit phi would make this lower too … the day that
; lands, this file becomes an ACCEPT.  Re-derive it then; do NOT delete it."*
; That trigger was character-for-character correct about the verdict.
;
; ONE EDIT from `loop_carried_handle_accept_select_merge.ll`: the loop is ROTATED
; behind a ZERO-TRIP GUARD, which is what `clang -O1` produces for `for (i < n)`
; with a RUNTIME `n`.
;
; WHAT (Z8) WAS PROTECTING, kept because the reason outlives the verdict.  The
; promotion's `cqrt_alloc` lived in the PREHEADER and the guard's false edge
; BYPASSES it, so the exit phi muxed the CLASSICAL seed `5` against a handle.
; The module declined EITHER WAY — without (Z8) `declineClassicalMuxes` refused
; the EXIT phi with a true sentence about the wrong instruction, pointing at the
; merge instead of at the loop (CLAUDE.md L6).  (Z8) bought the accurate message,
; it never bought safety.
;
; WHAT LANDED, and it is the OWNER'S RULING Q1 of 2026-09-20 (*"hoist it — accept
; the dead alloc"*): the mint point for a guarded loop is the GUARD'S OWN
; terminator, and every out-of-loop phi incoming that carries the SEED on the
; guard's edge is rewritten to that handle and recorded in the promotion's own
; `PromotedCarriedHandlePhis`.  The exit phi then muxes two `i32` HANDLES under
; the loop's own CLASSICAL guard — the identical argument the header phi already
; stands on: exactly one incoming is live per execution and WHICH one is a
; classical fact the hardware already has.
;
; ⚠ THE COST IS REAL, WAS THE OWNER'S TO TAKE, AND IS TAKEN: `n <= 0` allocates
; `|5>` and never uses it.  It is left allocated, never freed dirty (Rule 6).  On
; the zero-trip path the exit phi names that register and the program measures
; it, which is the RIGHT ANSWER (a zero-trip loop leaves the variable at its
; seed) — so the allocation is not merely harmless, it is what makes the
; zero-trip path expressible at all.
;
; ⚠ WHAT THIS FILE DOES **NOT** COVER, said so it is not later cited as though it
; did: the MULTI-EXIT carried handle (bd `h7ee` Rule-13 round 2, R2-3) is a
; DISTINCT shape — it has no guard, so this hoist does not reach it and it still
; declines.
;
; ⚠ L8 RETIREMENT TRIGGER: this file moves when the guard recognition
; (`Pre->getUniquePredecessor()` + a conditional terminator), the bypass-incoming
; proof, or the mint-point choice changes.  RE-DERIVE it then; do not delete it,
; and do not predict which string it would land on.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.g0.ll
; RUN: %filecheck %s < %t.g0.ll

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %n) {
entry:
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit

ph:
  br label %head

head:
  %i = phi i32 [ 0, %ph ], [ %inext, %head ]
  %a = phi i32 [ 5, %ph ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %r = phi i32 [ 5, %entry ], [ %anext, %head ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; THE HOIST — the trip-1 register is minted in the GUARD'S OWN BLOCK, BEFORE the
; guard branch.  These two lines being in this order, in `entry`, is the whole
; increment: minted after the `br` it would not dominate the zero-trip edge, and
; minted in `%ph` it would not exist there at all.
; CHECK: entry:
; CHECK-NEXT: %guard = icmp sgt i32 %n, 0
; CHECK-NEXT: %cq.carried = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: br i1 %guard, label %ph, label %exit

; The header phi names it on the preheader edge, as it did before the hoist.
; CHECK: %a = phi i32 [ %cq.carried, %ph ], [ %out, %head ]

; THE REWRITE — the exit phi's ZERO-TRIP incoming is the same register, so both
; its incomings are `i32` handles and it is a handle VARIABLE, not a data mux.
; CHECK: exit:
; CHECK-NEXT: %r = phi i32 [ %cq.carried, %entry ], [ %out, %head ]
; CHECK-NEXT: %m1 = call i32 @cqrt_measure_i32(i32 %r)
