; lowering_uncompute_preserving_sink_in_loop.ll — SAFE LEAK (Phase 5 §2.9). The
; BACKSTOP that comes with the bd 8gi5(3)/e4zs ordering fix.
;
; That fix makes every source-preserving sink an anchor of the whole-DAG insertion
; point, so the reversal lands after every preserving read. Moving the insertion
; point LATER looks unconditionally safe — it only adds reads that already
; happened — and it is not: the reversal can end up inside a natural LOOP, where one
; emitted stream runs once per iteration over rails minted once. That is (K-1)
; hidden measurements plus a double free, i.e. the §2.9 hazard through a new door.
;
; MEASURED with the backstop removed, on exactly this module: both adjoints and both
; `cqrt_free`s are emitted INSIDE `%loop`, and `free_pairing_check.py` reports both
; frees `UNPROVEN U3-extern-rail` (rc=1). With it, nothing is emitted and the DAG is
; LEFT ALLOCATED.
;
; *** THE BACKSTOP TESTS THE FINAL INSERTION POINT, NOT THIS SINK. *** Its first
; draft tested whether the SINK sat in a loop, and that was a silent miscompile
; found by the bd 8gi5/e4zs Rule-13 round: `dagInsertPoint` takes the nearest common
; POST-dominator of the anchors, and the nearest common post-dominator of two
; divergent NON-loop arms is routinely a loop-body block both arms branch into — so
; the reversal lands in a loop with no sink and no recovered gate in one, and a
; sink-block test never fires. The sibling fixture
; lowering_uncompute_reversal_point_in_loop.ll pins that shape, which needs no sink
; at all and was ALREADY broken at HEAD. This fixture keeps its own value as the
; case where sink and insertion point coincide.
;
; The draft was also COARSE (one loop-resident sink abandoned every terminal in the
; group, leaking reversals HEAD placed correctly) and PRE-EMPTIVE (it sat before the
; dominance scan, so it swallowed the loud `kMsgDivergentArm` decline into a silent
; rc-0 leak — bd 261j(a) risk 1). The shipped guard runs AFTER that scan.
;
; The backstop is otherwise the SAME test the acyclic §2.9 backstop applies to
; `D.Calls` (`LI.getLoopFor`, with the Phase-7.3 iteration-local exception) and has
; the same silent outcome — a leak, not a diagnostic — because that is what §2.9
; already does for a loop-resident GATE. Rule 6's fallback for a rail we cannot place
; a free for is to leave it allocated; a leak is safe, a mis-placed free is not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREELOOP < %t.cqd0.ll
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
