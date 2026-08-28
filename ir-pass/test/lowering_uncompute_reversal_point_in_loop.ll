; lowering_uncompute_reversal_point_in_loop.ll — SAFE LEAK (Phase 5 §2.9). THE
; AT-MOST-ONCE guard, on the shape that needs no preserving-sink anchor at all and
; was ALREADY WRONG AT HEAD 1ec8c45.
;
; THE INVARIANT. The whole-DAG reversal is emitted ONCE, so the point it is emitted
; at must EXECUTE at most once per execution of the forward gates. The driver used to
; establish that with two tests, and both are about other things:
;   * the §2.9 acyclic backstop asks whether a recovered GATE sits in a loop;
;   * the dominance scan asks whether every gate DOMINATES the insertion point —
;     which says every gate ran BEFORE it, and says nothing about how many TIMES the
;     insertion point itself runs.
; Neither is the property. `dagInsertPoint` takes the nearest common POST-dominator
; of the per-terminal anchors, and the nearest common post-dominator of two divergent
; NON-loop arms is routinely a LOOP-BODY block that both arms branch into.
;
; MEASURED at HEAD 1ec8c45 on exactly this module, with no bd 8gi5/e4zs sink anchors
; involved: `cq_template_add_i32_hl_unc` and `cqrt_free(%h_op)` are emitted INSIDE
; `%loop`. `opt` exits 0 and `opt -passes=verify` is clean. So a rail minted once is
; RESET once per iteration — iterations 2..K reset a rail that is provably not |0>,
; which is (K-1) hidden measurements plus a double free (Rules 5/6), and the adjoint
; of a once-run gate is applied K times (the wrong unitary).
;
; Here both uses of the terminal `%b` are tape writes in divergent arms, so the
; anchors are `%T` and `%E` and their nearest common post-dominator is `%loop`.
; Nothing is in a loop except the answer.
;
; THE GUARD leaves the whole DAG allocated — Rule 6's fallback for a rail we cannot
; place a free for — and is silent rather than a diagnostic, matching what §2.9
; already does for a loop-resident gate. It runs AFTER the dominance scan so it
; cannot swallow the loud `kMsgDivergentArm` decline (bd 261j(a) risk 1; an earlier
; draft placed before it did exactly that, MEASURED rc=1 -> rc=0).
;
; The Phase-7.3 ITERATION-LOCAL exception is affirmative and is NOT exercised here:
; such a group is reversed in-body once per iteration BY DESIGN over rails re-minted
; each iteration, and `FreePoint` has already re-checked that its anchor is in-body.
; `lowering_loop_*` cover that path; this module has no recognized loop region.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the pre-loop `q + c` lowers
; IN PLACE (`cqrt_addc_<W>`), so the rail the tape sink reads is the root. The
; placement property under test — the reversal point vs a sink inside a loop — is
; unchanged; only which register carries the value is.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEATONCE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)

define void @reversal_point_in_loop(i32 %u0, i32 %n, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b = add i32 %q, 2                      ; the terminal
  %tape = call i32 @cqrt_tape_alloc()
  br i1 %c, label %T, label %E

T:                                        ; both uses are in DIVERGENT arms …
  %w1 = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %b)
  br label %loop

E:
  %w2 = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %b)
  br label %loop

loop:                                     ; … and their post-dominator is a LOOP body
  %i = phi i32 [ 0, %T ], [ 0, %E ], [ %i1, %loop ]
  %i1 = add i32 %i, 1
  %cc = icmp slt i32 %i1, %n
  br i1 %cc, label %loop, label %exit

exit:
  ret void
}

; The forward stream lowers normally — nothing here is loop-resident:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 2)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]])

; NOTHING is reversed and NOTHING is freed, anywhere in the module. Its OWN prefix
; with a SINGLE positive anchor, so both negatives run anchor -> EOF (a `CHECK-NOT`
; is bounded by the next positive directive OF ITS OWN PREFIX — bd memory
; filecheck-check-not-window-trap; `tools/fixture_guard_liveness.py` proves the free
; guard executes by injecting the exact free HEAD emitted):
; NOFREEATONCE:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEATONCE-NOT: call void @cqrt_free(
; NOFREEATONCE-NOT: _unc(
