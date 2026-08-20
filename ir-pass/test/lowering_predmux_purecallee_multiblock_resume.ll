; lowering_predmux_purecallee_multiblock_resume.ll — bd ziuw, the COVERAGE half.
;
; The ziuw rewrite turned the pure-callee proof from a C++ mutual recursion into
; an explicit `PureCalleeFrame` worklist. Doing that INVENTED state the recursion
; never had: a per-frame block cursor, a per-frame instruction cursor, and a
; `BlockEntered` / `AwaitingCall` pair that must be resumed correctly when a child
; walk returns. The deep-chain fixture exercises DEPTH; it cannot exercise that
; state at all — its bodies are single-block, single-call, `hits=0`.
;
; *** THE GAP, MEASURED (the Rule-13 round's lens 4). *** A census of the 205
; candidate fixtures found 52 distinct (fixture, walk-root) pairs that print a
; `pure-callee` line, and exactly FOUR walk roots with more than one basic block —
; and not one of them composes the two things this file composes:
;   reject_i80_cmp_purecallee_armdiamond.ll  @inner   3 blocks, verdict=1, ZERO calls
;   leave_speccall_recursive.ll              @purefn  call in block 2, child hits OnStack ⇒ FALSE
;   leave_speccall_loop.ll                   @purefn  fails the SCC test before any block walk
;   reject_poisonbr_callee.ll                @pf      strict cond-br reject in block 0
; The one fixture with a TRUE-returning child, purecallee_memo_cost.ll, has
; ALL-single-block bodies (two calls in one block, hits=12) — it never leaves the
; block. So "a child returns TRUE and the parent then advances into a LATER block"
; was uncovered.
;
; WHAT THIS FILE COMPOSES, and each part is a distinct worklist transition:
;   @g0  calls @g1 in b1, then AGAIN in b2       — resume-after-TRUE-child, then a
;                                                  BLOCK CROSSING, then a memo hit
;   @g1  calls @g2 TWICE inside b1, then walks on to b2 — resume-after-TRUE-child
;                                                  WITHIN a block, plus a memo hit
;   @g2  three blocks, no calls                  — a plain multi-block completion
;
; NOT A BUG PIN — a REGRESSION pin. The rewrite is byte-identical here: this
; module through a `cq-opt` built from the pre-change commit 72da1f2 and through
; the current one gives the same stdout, stderr and exit code. The counter triple
; below is what would go red if the cursor resume across a block boundary after a
; TRUE child were ever broken, and nothing else in the tree would.
;
; `invocations=5 bodies=3 hits=2` reads directly off the structure: 5 call edges
; walked (g0→g1 ×2, g1→g2 ×2, plus the root), 3 distinct bodies, 2 memo hits (the
; second @g1 and the second @g2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: env CQ_PREDMUX_COUNT=1 %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=COST

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @g2(i32 %a) #0 {
entry:
  %x = add i32 %a, 1
  br label %b1
b1:
  %y = mul i32 %x, 3
  br label %b2
b2:
  %z = add i32 %y, %a
  ret i32 %z
}

define i32 @g1(i32 %a) #0 {
entry:
  %p = add i32 %a, 7
  br label %b1
b1:
  %k = call i32 @g2(i32 %p)
  %k2 = call i32 @g2(i32 %k)      ; second call: memo hit, resume INSIDE the block
  br label %b2
b2:
  %r = add i32 %k2, %p
  ret i32 %r
}

define i32 @g0(i32 %a) #0 {
entry:
  br label %b1
b1:
  %u = call i32 @g1(i32 %a)       ; TRUE child, then the block ENDS
  br label %b2
b2:
  %v = call i32 @g1(i32 %u)       ; memo hit in a LATER block
  ret i32 %v
}

define void @example(i32 %u0, i32 %arg) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %cnd = icmp sgt i32 %q, 3
  br i1 %cnd, label %arm, label %merge
arm:
  %r = call i32 @g0(i32 %arg)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; The 6.5 arm really claimed — otherwise the COST line measures a proof that ran
; on nothing (an exit code says the module lowered, never WHICH gate lowered it).
; CHECK: call i32 @g0(
; CHECK: cqrt_copy_i32_controlled

; THE PIN.
; COST: CQ_PREDMUX_COUNT: pure-callee mode=strict root=g0 verdict=1 invocations=5 bodies=3 hits=2
