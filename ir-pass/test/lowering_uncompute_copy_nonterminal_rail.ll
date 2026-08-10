; lowering_uncompute_copy_nonterminal_rail.ll — ACCEPT (Phase 5). The COPY-OUT half
; of the same root cause (bd test_C_libtooling-8gi5 item 3; the tape half is
; lowering_uncompute_tape_nonterminal_rail.ll and bd test_C_libtooling-e4zs).
;
; `cqrt_copy_<W>(src, dst)` is the method-B copy-out: like a tape write it READS its
; src without consuming it (`ChainWalk::isCopyOutSink`), which is why the closure
; scan treats it as a benign terminal user. Benign for CLOSURE is not benign for
; ORDERING — it is still a use, and the rail's `cqrt_free` must follow it. When the
; copied rail is an UPSTREAM one (here `%a`, whose lineage continues into the
; terminal `%b`) it was in no `Terminal->users()` scan, so the reversal was placed
; ahead of it.
;
; MEASURED before the fix: `cqrt_free(%h_op)` emitted BEFORE
; `cqrt_copy_i32(%h_op, %dst)`; `opt` rc=0 and verify clean; stage 2b reports
; `VIOLATION F2-use-after-free`. Both surfaces are pinned separately rather than by
; one fixture because they are two independent predicate arms — deleting either
; `PreservingSinks` push individually turns exactly one of these two fixtures red
; (arm-kill matrix, bd memory gate-validation-not-corpus-silence-2026-07-31).
;
; TWO THINGS THIS FIXTURE DOES NOT CLAIM. It does not rule on whether the copy-out
; surface needs bd 261j(a)'s RECORD FREEZE — that is bd 8gi5's open scope question
; for the owner, and `isCopyOutSink` is deliberately NOT a
; `recordsIntoKeptCarrier`. And it does not claim the shape is emitter-reachable:
; bd 8gi5 censused all five sites that mint an uncontrolled 2-arg `cqrt_copy_<W>`
; and none of them produces it. Hand-written IR does (the pass carves every `cqrt_*`
; callee out of `declineTaintEscapes`), and an ordering bug on accepted input is a
; defect whether or not an emitter reaches it today.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_copy_i32(i32, i32)

define i32 @copied_upstream(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1                     ; the NON-terminal rail the copy reads
  %b = add i32 %a, 2                     ; lineage continues ⇒ %b is the terminal
  %dst = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %a, i32 %dst)
  ret i32 0
}

; Forward stream, then the copy-out of the UPSTREAM rail:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     %[[OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OP]], i32 2)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %{{[a-zA-Z0-9_.]+}})
;
; ONLY THEN the reversal — the ordering is the fixture (see the tape sibling):
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP1]], i32 %[[OP]], i32 2)
; CHECK:     call void @cqrt_free(i32 %[[OP1]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
; CHECK-NOT: cqrt_measure
