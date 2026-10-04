; lowering_io_tape_chained_theta.ll — ACCEPT (Phase 7.6). THE ROOTS-VS-RAILS
; DISCRIMINATOR for the bd 261j(a) record freeze.
;
; A CHAINED theta puts `cqrt_ry` on a DERIVED template rail, not on a root:
; `RotationLowering` emits the second rotation on the EXISTING handle it was handed,
; and here that handle is a `cq_template_add` producer's result. So the defective
; free lands on a rail that is not a root, and EVERY 'freeze the correlated ROOTS'
; formulation leaves it standing.
;
; MEASURED against the shipped pass before this fix (six lines of ordinary C —
; `int x=seed; cq_theta(&x,.5); int y=x+1; int z=y; cq_theta(&z,.25); printf("%d",z);`,
; clang -O1, EXIT=0 — the `%W` read of the root was added later, see the Increment-3
; note below): TWO defective frees were emitted,
;     cqrt_ry_i32(%OP,-0.25) ; cq_template_add_i32_hl_unc(%OP,%H,1) ; cqrt_free(%OP)
;     cqrt_ry_i32(%H,-0.5)   ; cqrt_free(%H)
; and BOTH were certified by `free_pairing_check.py` — %OP via T1-unc-reversal and
; %H via A2-reduces-to-identity. (That is also the correction to bd 261j(b): the
; checker tightening is not A2-only.) Note what changed and what did not: those
; three ADJOINT lines are still emitted verbatim. Only the two `cqrt_free`s are
; gone. The freeze subtracts frees, never reversals.
;
; Under the shipped rule both ROTATED rails freeze:
;   Recorded   = {%OP, %W}                 (the tape writes read them)
;   Correlated = {%OP, %W, %H}             (backward over the DAG ancestor edges)
;   %OP  carries `cqrt_ry_i32(%OP, 0.25)`  -> not basis-preserving -> FROZEN
;   %H   carries `cqrt_ry_i32(%H, 0.5)`    -> not basis-preserving -> FROZEN
;   %W   carries no rotation at all        -> reverses and FREES
; so neither rotated rail is freed: both are fully reverse-played and then left
; allocated (Rule 6's fallback), while %W — same DAG, no rotation — frees. `opt`
; exits 0 with no diagnostic. The %W contrast is the same one
; lowering_io_tape_derived_uncompute.ll pins, here inside one module.
;
; ── THE `%W = x * 5` LINE IS NOT DECORATION (M-A Increment 3, bd
; test_C_libtooling-6uqc). READ THIS BEFORE DELETING IT. ────────────────────────
; Without it this module DECLINES with
;     cq rotation lowering: non-diagonal gate over a live derived record
; and the decline is CORRECT, not an over-decline: with the chained `Ry` sitting on
; the DERIVED rail, `%H` is a live, undischarged basis record of `%OP` (`%OP = 3H`)
; at the instant the gate fires, so `%OP`'s reduced state is diagonal and the
; rotation acts on a mixture. Census 0.1 forecast exactly this module (SPIKE
; §2R.5, the spine-aware column) and the owner ruled the spine-aware reading in
; (§2R.5a, 2026-08-27): "all three real disagreeing programs are genuinely dephased
; at the theta", and the spine's later `_unc` read of `%H` plus its adjoint
; `cqrt_ry(%H, -0.5)` are the compiler undoing ITSELF, not the user reading data.
; The ORIGINAL body — the same program without `%W` — is preserved verbatim as the
; negative twin lowering_reject_live_record_io_tape_chained_theta.ll.
; `%W = x * 5` is a template READ of the root emitted AFTER the gate whose result
; is taped, i.e. an OBSERVING data use of `%H` after `T`. Under the ruled predicate
; that makes `%H` the program's own live data (clause 3) and its dephasing of `T`
; source semantics — the same principle that keeps
; lowering_stale_record_add_before_theta.ll green. Every 7.6 property this fixture
; existed to pin is unchanged; only the liveness of the root moved.
;
; Contrast lowering_io_tape_derived_uncompute.ll, whose %OP has the SAME producer
; but NO rotation on it, and therefore still reverses and frees. The two fixtures
; together pin that the freeze keys on the GATES A RAIL CARRIES, not on the rail's
; position in the DAG. (%W below is that same contrast, in-module.)
;
; VEHICLE-OP NOTE (bd test_C_libtooling-6uqc, M-C Increment 2a — `add` only).
; The DERIVED rail below is built with `mul`, not `add`, and that is load-bearing
; for what this file discriminates: since M-C a dead-parent `q + c` lowers to the
; VOID in-place `cqrt_addc_<W>`, which mints NO rail — so with `add` there would
; be exactly ONE rail here and the PER-RAIL freeze decision this fixture exists to
; pin would have nothing to discriminate between. `mul` is information-losing and
; therefore outside the dtzb in-place bijection family at every batch. The
; in-place spelling of the same program is covered end to end by
; tests/e2e/slice_io_chained_theta.c, whose golden carries it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [6 x i8] c"%d %d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = mul i32 %q, 3
  %q2 = call i32 @cq_theta_si32(i32 %s, double 2.500000e-01)
  %w = mul i32 %q, 5                                          ; ROOT read AFTER the gate
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q2, i32 %w)
  ret void
}

; The forward stream, the tape write, then the FULL reverse-play. NEITHER of the
; two ROTATED rails is freed; the un-rotated %W is:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP]], double 2.500000e-01)
; CHECK:     %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[W]])
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[W]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[W]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP]], double -2.500000e-01)
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 3)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; ONE PREFIX PER GUARDED HANDLE (a CHECK-NOT is bounded by the next positive
; directive of its OWN prefix — see lowering_io_tape_partial_freeze_order.ll's
; header for why stacking them in one prefix is a silent hole).
; NOFREEH:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREEH-NOT:  call void @cqrt_free(i32 %[[H2]])
; NOFREEOP:     %[[OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; NOFREEOP-NOT: call void @cqrt_free(i32 %[[OP2]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
