; lowering_predmux_purecallee_memo_cost.ll — ACCEPT + COST PIN (bd 3c6m.14.4).
;
; `isSpeculatablePureCalleeBodyImpl` recursed once per call instruction with only
; the `OnStack` cycle breaker. `OnStack` is ERASED ON EXIT — it is a cycle
; breaker, never a visited set — so two sibling calls to the same callee re-walk
; the shared subtree in full and the invocation count is the number of distinct
; PATHS through the call DAG: O(2^D) on a doubling graph. Same hazard shape as
; bd xzdx ("a build gate a 66-line input can hang is a DoS on every e2e slice").
;
; THE COST IS PINNED AS A CALL COUNT, NEVER A WALL TIME, so this fixture cannot
; go flaky (the bd xzdx precedent). Closed forms for a chain where every `f_i`
; calls `f_{i+1}` TWICE and every node passes:
;
;     no memo    invocations = bodies = 2^(D+1) - 1
;     per-query  invocations = 2D + 1,  bodies = D + 1,  hits = D
;
; TWO DEPTHS, deliberately. One data point cannot distinguish `2D+1` from any
; other law that happens to pass through it; two pin the linear form. D=4 and
; D=12 give 9/5/4 and 25/13/12 against un-memoised 31 and 8191.
;
; WHY NOT A BIGGER D. The obvious demonstrator is D=24 — 33,554,431 invocations,
; ~43 s un-memoised — but a fixture whose FAILURE costs 43 s is a fixture people
; disable, and it buys nothing: the CHECK below already fails on the first
; wrong number. At D=4/D=12 the whole module runs in 0.37 s, FASTER than the
; shipped `lowering_predmux_speccall_flatten.ll` it is modelled on, and the red
; run costs 8191 invocations, i.e. nothing.
;
; *** THE MEMO IS PER-QUERY AND MUST STAY THAT WAY — see PredMuxFlatten.cpp. ***
; A module-lifetime memo keyed on `Function*` is UNSOUND: `unrollConstTripLoops`
; runs BETWEEN the two `flattenPredMuxRegions` fixpoints and removes CFG cycles,
; so a verdict flips FALSE -> TRUE inside one `opt` run (reproduced with a
; one-character edit to `lowering_predmux_leave_speccall_loop.ll`). This fixture
; does NOT pin that — it cannot, since both designs give the same counts here.
; `lowering_predmux_leave_speccall_loop.ll` is the file that would go red.
;
; NOTE the DIVERGENCE between `invocations` and `bodies` is itself the assertion
; that the memo is live: without it the two numbers are equal.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: env CQ_PREDMUX_COUNT=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=COST

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; ---- D = 4 ----
define i32 @d4_0(i32 %a) {
  %x = call i32 @d4_1(i32 %a)
  %y = call i32 @d4_1(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d4_1(i32 %a) {
  %x = call i32 @d4_2(i32 %a)
  %y = call i32 @d4_2(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d4_2(i32 %a) {
  %x = call i32 @d4_3(i32 %a)
  %y = call i32 @d4_3(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d4_3(i32 %a) {
  %x = call i32 @d4_4(i32 %a)
  %y = call i32 @d4_4(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d4_4(i32 %a) {
  %r = mul i32 %a, 3
  ret i32 %r
}

; ---- D = 12 ----
define i32 @d12_0(i32 %a) {
  %x = call i32 @d12_1(i32 %a)
  %y = call i32 @d12_1(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_1(i32 %a) {
  %x = call i32 @d12_2(i32 %a)
  %y = call i32 @d12_2(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_2(i32 %a) {
  %x = call i32 @d12_3(i32 %a)
  %y = call i32 @d12_3(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_3(i32 %a) {
  %x = call i32 @d12_4(i32 %a)
  %y = call i32 @d12_4(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_4(i32 %a) {
  %x = call i32 @d12_5(i32 %a)
  %y = call i32 @d12_5(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_5(i32 %a) {
  %x = call i32 @d12_6(i32 %a)
  %y = call i32 @d12_6(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_6(i32 %a) {
  %x = call i32 @d12_7(i32 %a)
  %y = call i32 @d12_7(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_7(i32 %a) {
  %x = call i32 @d12_8(i32 %a)
  %y = call i32 @d12_8(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_8(i32 %a) {
  %x = call i32 @d12_9(i32 %a)
  %y = call i32 @d12_9(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_9(i32 %a) {
  %x = call i32 @d12_10(i32 %a)
  %y = call i32 @d12_10(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_10(i32 %a) {
  %x = call i32 @d12_11(i32 %a)
  %y = call i32 @d12_11(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_11(i32 %a) {
  %x = call i32 @d12_12(i32 %a)
  %y = call i32 @d12_12(i32 %a)
  %r = add i32 %x, %y
  ret i32 %r
}
define i32 @d12_12(i32 %a) {
  %r = mul i32 %a, 3
  ret i32 %r
}

; The drivers are `lowering_predmux_speccall_flatten.ll`'s nested tainted value
; region with the arm call retargeted at each chain root — the shape that
; actually reaches the E4 pure-callee call admission. Without it the proof is
; never queried and the COST lines never print.
define i32 @drv_d4(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @d4_0(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}

define i32 @drv_d12(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @d12_0(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}

; Both regions really did claim — otherwise the COST lines measure a proof that
; ran on nothing.
; CHECK: @__cq_q_d4_0_1(
; CHECK: @__cq_q_d12_0_1(

; THE PIN. Exact numbers, both depths, in module order.
; COST: CQ_PREDMUX_COUNT: pure-callee root=d4_0 verdict=1 invocations=9 bodies=5 hits=4
; COST: CQ_PREDMUX_COUNT: pure-callee root=d12_0 verdict=1 invocations=25 bodies=13 hits=12
