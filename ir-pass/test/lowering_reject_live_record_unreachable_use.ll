; lowering_reject_live_record_unreachable_use.ll — DECLINE: a post-gate data use
; in an UNREACHABLE block cannot exempt the record (M-A Increment 1, bd
; test_C_libtooling-6uqc; the Rule-13 round's F3 finding).
;
; Clause 3 exempts a record that some USER reads after the gate, on the ruled
; ground that a live record is the program's own data and its dephasing is source
; semantics. That ground evaporates when the reader is unreachable: nothing ever
; reads `%d`, so it is a dead entangled basis record of the wire at the instant
; the chained `Ry` fires — exactly the shape the guard exists to decline.
;
; THE MECHANISM. `provablyBefore` is `DT.dominates(T, UI) &&
; !isPotentiallyReachable(UI, T)`. Both halves are VACUOUSLY TRUE for an
; instruction in a block with no predecessors — LLVM's dominator tree treats an
; unreachable block as dominated by everything, and nothing is reachable from it
; — so the exemption was granted by a use that can never execute. The fix adds
; the explicit `DT.isReachableFromEntry(UI->getParent())` test; unproven
; reachability now means NO exemption (Prime Directive).
;
; FIXTURE-ONLY TODAY, on purpose. `clang -O1` deletes unreachable blocks, so no
; `.c` spelling reaches this; the shape is written directly, the same idiom as
; lowering_uncompute_sink_move_past_unwalked_gate.ll. It is committed anyway
; because an unreachable block is reachable INSIDE the pass — Phase-4 flattening
; and the 7.4 break reverse-play both detach blocks mid-pipeline, and this guard
; runs after all of them.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = add i32 %q, 1                                          ; DEAD record of the wire
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; chained, in-place Ry
  ret i32 %q2

dead:                                                          ; no predecessors
  %m = call i32 @cq_measure_si32(i32 %d)                       ; a use that can never run
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
