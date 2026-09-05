; lowering_reject_inloop_control_rail_fanout.ll — DECLINE (bd test_C_libtooling-8h7d.5):
; the Rule-8 LINEAR-LINEAGE / FAN-OUT guard, reached through the round-2 path.
;
;     for (...) { if (q > 5) q = cq_phi(q, b); q = q + 7; }
;     int a = q + 9;  int b = q ^ 3;   /* TWO in-place consumers of the exit rail */
;     return cq_measure(a) + cq_measure(b);
;
; After the region is flattened, the rail's exit value `%qn` has TWO forward
; in-place consumers, `%a1 = add %qn, 9` and `%a2 = xor %qn, 3`. Both are
; STRAIGHT-LINE, so M-C (`classifyInPlaceReassignment`) may legitimately claim
; either — probe r3h/b4 measures it firing in place post-loop — and collapsing the
; rail would serialise them onto ONE handle: the measured values become `q+9` and
; `q+9^3`, not the source's two independent records (`emitRegion`'s no-cloning
; note; Rule 8). A fan-out of a superposed source needs an ancilla / `cqrt_cswap`,
; not an in-place collapse.
;
; THIS IS THE `Unproven` CELL OF `railValueConsumerDisposition`, AND THAT IS WHAT
; THE FIXTURE PINS (bd 8h7d.5 Rule-13 ROUND 4, finding OD-A). The guard no longer
; counts a `BinaryOperator` by the dtzb SHAPE alone; it counts one that will really
; be lowered in place. Three cells, and this file pins the middle one:
;   * `InPlace`     — a chain member, or already `taint.InPlaceRailOps`. Counted.
;   * `Unproven`    — straight-line, unclaimed. M-C may or may not take it, and no
;                     one here can predict G6/G7, so it is COUNTED (Prime
;                     Directive: only the case with a PROOF is dropped). ← HERE.
;   * `OutOfPlace`  — inside a loop or a `blockCanRepeat` block, unclaimed. M-C's
;                     G5 refuses it OUTRIGHT, so it is dropped.
;
; WHAT THIS FILE USED TO BE, and why it moved. It used to carry
; `%o2 = add %qm, 9` INSIDE the loop body, asserting that "both lower to in-place
; `cqrt_addc_i32`". That assertion was MEASURABLY FALSE — an off-chain, unmarked
; `add` in a loop body is `OutOfPlace` by G5 and lowers to a fresh
; `cq_template_add_i32_hl` rail — and the program's REAL hazard was never fan-out
; at all: `%o2` reads the PRE-`addc` register AFTER the in-place `addc` on the same
; rail. That program now declines under the fence that names its actual hazard,
; and it ships as lowering_reject_inloop_rail_record_offchain_add.ll. Same class as
; round 3's r3f/m1 and r3p/t3 message-owner moves: the decline was right, the
; reason on the label was not.
;
; Round 1 fires the same `kMsgRailFanout` for the control-free spelling
; (lowering_reject_loop_rail_fanout.ll); this fixture pins that round 2 asks the
; SAME question, because round 1 never sees a loop with in-body tainted control
; (gate L2 leaves it unclaimed).
;
; MUTATION: make the guard drop the `Unproven` cell as well as `OutOfPlace` and
; this fixture goes green-when-it-should-be-red.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried rail has multiple in-place consumers
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = add i32 %q, 7                                 ; in-place rail self-update
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %a1 = add i32 %qn, 9                                 ; straight-line: Unproven
  %a2 = xor i32 %qn, 3                                 ; straight-line: Unproven
  %m1 = call i32 @cq_measure_si32(i32 %a1)
  %m2 = call i32 @cq_measure_si32(i32 %a2)
  %s = add i32 %m1, %m2
  ret i32 %s
}
