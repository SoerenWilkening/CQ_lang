; lowering_uncompute_interior_leak_loop_rail.ll — LEAK PROBE (M-B Increment 5a,
; bd test_C_libtooling-6uqc). §2.9 AT-MOST-ONCE, applied per candidate: no rail
; minted inside a loop enters the interior partition.
;
; Every gate here is re-executed once per iteration, so a rail is re-MINTED each
; time. One reversal emitted at a function-scope point would adjoint a K-times
; gate once and reset a re-allocated register K−1 times too many — (K−1) hidden
; measurements plus a double free (Rules 5/6). The whole-DAG spine states the same
; property twice (FreePoint's `kMsgLoopBackedge` per terminal, and the driver's
; acyclic backstop over `D.Calls`); the interior partition states it a THIRD time,
; at CANDIDATE selection, because its candidates are not terminals and never reach
; `computeFreePoint` at all.
;
; PER CANDIDATE, NOT PER GROUP, deliberately: a straight-line rail in the same
; function is still discharged. Only the in-loop ones leak.
;
; The 7.3 iteration-local group is the ONE in-loop reversal in the tree and it has
; its own affirmative proof (`IterationLocalBlocks`); Inc 5 does not extend it, and
; a loop-aware interior partition is tracked as later work.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_loop(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %m, %loop ]
  %a = mul i32 %q, 3
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  %i2 = add i32 %i, 1
  %e = icmp slt i32 %i2, 4
  br i1 %e, label %loop, label %out
out:
  ret i32 %acc
}

; CHECK-LABEL: define i32 @leak_loop(
; CHECK: call i32 @cq_template_mul_i32_hl
; CHECK: call i32 @cq_template_icmp_slt_i32_hl
; CHECK: call i32 @cqrt_measure_i32
; CHECK-NOT: _unc
; CHECK-NOT: call void @cqrt_free
