; control_inplace_ry_reject_stateprep_runtime_seed_quantum_incoming.ll — DECLINE
; (F1's identity clause, the NO-CLONING split; bd test_C_libtooling-z0re): a runtime
; seed on the arm, a LIVE QUANTUM REGISTER on the straight-through edge.
;
;     int r = q; if (q != s) r = cq_theta(s, .2);          // probe e09, from C
;
; This is the β reading of F2's header with a RUNTIME seed. MEASURED at -O1: the
; Pred incoming stays `%q` (no pass substitutes `s` for `q` on the `q == s` edge —
; no GVN/NewGVN/JumpThreading/CVP in the pipeline, IPSCCP folds only constants), so
; the module is a mux of a prepared rail and a live register, which is Rule 8's
; no-cloning mux and has no rotation-arm lowering. Before bd z0re F1's FIRST
; clause (literal-only) fired on this module with `state prep seed does not match
; the merge incoming`; now the runtime seed passes that clause and the SECOND
; clause's split names the physics: `state prep merged with a quantum register`.
; A STRING mover, verdict unchanged — recorded in TRACK_Z0RE.md §6.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep merged with a quantum register under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, %s
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %s, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %q, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}
