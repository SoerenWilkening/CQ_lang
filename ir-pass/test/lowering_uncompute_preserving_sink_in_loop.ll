; lowering_uncompute_preserving_sink_in_loop.ll — SAFE LEAK (Phase 5 §2.9). The
; BACKSTOP that comes with the bd 8gi5(3)/e4zs ordering fix.
;
; That fix makes every source-preserving sink an anchor of the whole-DAG insertion
; point, so the reversal lands after every preserving read. Moving the insertion
; point LATER looks unconditionally safe — it only adds reads that already
; happened — and it is not: a sink inside a natural LOOP would drag the insertion
; point into the loop BODY, and the reversal would then run once per iteration over
; rails minted once. That is a use-after-free plus (K-1) double frees, i.e. the
; §2.9 hazard arriving through a new door.
;
; MEASURED with the backstop removed, on exactly this module: both adjoints and both
; `cqrt_free`s are emitted INSIDE `%loop`, and `free_pairing_check.py` reports both
; frees `UNPROVEN U3-extern-rail` (rc=1). With it, nothing is emitted and the DAG is
; LEFT ALLOCATED.
;
; The backstop is the SAME test the acyclic §2.9 backstop already applies to
; `D.Calls` (`LI.getLoopFor`, with the Phase-7.3 iteration-local exception), applied
; to the sink anchors — deliberately the same rule and the same silent outcome, a
; leak rather than a diagnostic, because that is what §2.9 already does for a
; loop-resident GATE. Rule 6's fallback for a rail we cannot place a free for is to
; leave it allocated; a leak is safe, a mis-placed free is not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=NOFREELOOP
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)

define void @sink_in_loop(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1
  %b = add i32 %a, 2
  %tape = call i32 @cqrt_tape_alloc()
  br label %loop

loop:                                   ; the preserving read is LOOP-RESIDENT
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %w = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %a)
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, %n
  br i1 %c, label %loop, label %exit

exit:
  ret void
}

; The forward stream lowers normally — the gates are outside the loop, so the
; acyclic backstop on `D.Calls` does NOT fire; only the new sink backstop does:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %[[OP]], i32 2)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OP]])

; NOTHING is reversed and NOTHING is freed, anywhere in the module. Its OWN prefix
; with a SINGLE positive anchor, so both negatives run anchor -> EOF: a `CHECK-NOT`
; is bounded by the next positive directive OF ITS OWN PREFIX, and a second anchor
; here would silently kill the first guard (bd memory
; filecheck-check-not-window-trap; `tools/fixture_guard_liveness.py` proves the free
; guard executes by injecting one).
; NOFREELOOP:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREELOOP-NOT: call void @cqrt_free(
; NOFREELOOP-NOT: _unc(
