; lowering_reject_inloop_control_rail_fanout.ll — DECLINE (bd test_C_libtooling-8h7d.5):
; the Rule-8 LINEAR-LINEAGE / FAN-OUT guard, reached through the NEW round-2 path.
;
;     for (...) { if (q > 5) q = cq_phi(q, b); q = q + 7; other = q_pre + 9; }
;
; After the region is flattened, the routed base `%q` (the collapsed header phi)
; has TWO forward in-place consumers: `%qn = add %qm, 7`, which is the carried
; rail, and `%o2 = add %qm, 9`, which is read at the exit. Both lower to in-place
; `cqrt_addc_i32(h, ·)` on ONE handle, so collapsing the rail would serialise them
; — the measured value becomes `q+7+9`, not the source's two independent records
; (`emitRegion`'s no-cloning note; Rule 8). A fan-out of a superposed source needs
; an ancilla / `cqrt_cswap`, not an in-place collapse.
;
; Same `kMsgRailFanout` round 1 fires for the control-free spelling
; (lowering_reject_loop_rail_fanout.ll); this fixture pins that round 2 asks the
; SAME question, because round 1 never sees a loop with in-body tainted control
; (gate L2 leaves it unclaimed).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried rail has multiple in-place consumers
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %q, %loop ]
  %qn = add i32 %qm, 7                                 ; in-place rail self-update
  %o2 = add i32 %qm, 9                                 ; SECOND in-place consumer
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %o2)
  ret i32 %m
}
