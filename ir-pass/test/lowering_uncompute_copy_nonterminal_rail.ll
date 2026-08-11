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
; IT NOW ALSO WITNESSES THE bd 5pio RECORD FREEZE, and that is a change of premise
; worth stating rather than quietly re-baselining. This fixture used to say it "does
; not rule on whether the copy-out surface needs bd 261j(a)'s RECORD FREEZE — that is
; bd 8gi5's open scope question for the owner". That question was RULED (owner,
; 2026-08-11): `isCopyOutSink` IS a `recordsIntoKeptCarrier` now, so a copy-out source
; seeds the freeze and the correlation propagates BACKWARD to its ancestors.
;
; The consequence is visible below and is exactly the hazard the ruling targets. Three
; rails, three different verdicts, all from one seed:
;   %h_op1  a DESCENDANT of the copied rail — the walk is backward-only, so it is not
;           correlated at all: reversed and FREED.
;   %h_op   the copy SOURCE itself — correlated, but its gate is a `cq_template_*`
;           producer, a basis permutation of its parents: reversed and FREED.
;   %h      an ANCESTOR of the copy source — correlated, and its gate is `cqrt_ry_`,
;           which is NOT a basis permutation: reversed but NOT FREED (left allocated).
; Freeing `%h` would be a hidden measurement of a rail a function of which was copied
; onto the kept carrier `%dst`, collapsing it (Rules 6/8). The leak is Rule 6's
; sanctioned fallback.
;
; THE ORDERING TEST — the reason this fixture exists — SURVIVES INTACT. The freeze
; suppresses a FREE, never an adjoint, so `cqrt_free(%h_op)` still exists and still
; follows `cqrt_copy_i32(%h_op, %dst)`. Deleting the `PreservingSinks` push still
; turns this fixture red (the arm-kill matrix is unaffected).
;
; IT STILL DOES NOT CLAIM THE SHAPE IS EMITTER-REACHABLE: bd 8gi5 censused all five
; sites that mint an uncontrolled 2-arg `cqrt_copy_<W>` and none produces it, and a
; mechanical re-census over 1241 lowered modules found 11 copies whose source is a
; directly-rotated rail and ZERO of them freed. Hand-written IR does reach it (the
; pass carves every `cqrt_*` callee out of `declineTaintEscapes`), and an ordering bug
; on accepted input is a defect whether or not an emitter reaches it today.
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
;
; …and there the reversal STOPS. The Ry root is fully reverse-played but NOT freed:
; it is a bd 5pio FROZEN rail (correlated with the kept copy destination through
; %[[OP]], and `cqrt_ry_` is not a basis permutation). The rail is LEFT ALLOCATED.
;
; This `CHECK-NOT` is a real discrimination control, not decoration: before the ruling
; the pass emitted `call void @cqrt_free(i32 %[[H]])` on the very next line, so an
; accidental revert of the seed turns this fixture red. It is unbounded (no later
; positive directive of this prefix), so the window runs to EOF.
; CHECK-NOT: call void @cqrt_free(i32 %[[H]])
; CHECK-NOT: cqrt_measure
