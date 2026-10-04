; control_inplace_ry_tape_after_region.ll — ACCEPT: a 7.6 OUTPUT-TAPE write of
; the register a FLAT control-in-place Ry arm rotated.
;
;     if (q == 5) { cq_theta(&r, .9); }   /* Inc-1 control-in-place Ry arm */
;     printf("%d\n", r);                     /* 7.6 tape write on the POST-region value */
;     return cq_measure(q);
;
; bd test_C_libtooling-drbq Increment 3, round-1 Rule-13 review finding F-L5-2
; (L5; independently measured by L7 as 15 moved `*_printf_*` cells of
; `tools/inplace_twin_matrix.py`). THE PRE-Inc-3 ORACLE DECLINES THIS PROGRAM
; `cq I/O output sink: tainted argument has continued lineage`, so this is a
; disposition FLIP on a straight-line program and it is deliberate.
;
; WHY IT IS AN OVER-DECLINE REPAIR AND NOT A WIDENING — the decisive measurement.
; The 7.6 sink guard asks TERMINALITY, not measuredness. Both facts were measured
; on the pre-Inc-3 oracle before this fixture was written:
;   * `int r = 0; cq_theta(&r,.3); printf("%d\n", r); return 0;`  — an UNMEASURED,
;     superposed register taped with NO control flow anywhere: **ACCEPTS**, and
;     the lowered IR is byte-identical on both binaries. So taping a live
;     superposed rail is already inside 7.6's admitted semantics.
;   * the same with a second `cq_theta` AFTER the `printf` — **DECLINES** on both
;     binaries. The guard's real subject is a NON-TERMINAL value.
; Under M-α the taped value was `Base`, whose lineage "continues" into the
; hoisted arm gate — a continuation manufactured by the RAUW, not written by the
; user. Under M-β the taped value is the hoisted gate `T`, which is genuinely
; terminal, and the guard answers the question the source actually poses. The
; rail is FROZEN by Inc 1's structural freeze, so nothing reverse-plays or frees
; it and the guard's own stated hazard (a whole-DAG use-after-free before the
; tape reads) cannot arise. Stage 2b strict is clean on the emitted module.
;
; ⚠ THE Rz TWIN OF THIS PROGRAM STILL DECLINES, and that asymmetry is a KNOWN
; ARTIFACT, not a fence: the Rz stem keeps M-α, so its taped value is still
; `Base` and the manufactured continuation is still there. Filed as
; `test_C_libtooling-j2ac`; it disappears on its own when the Rz stem moves to
; M-β (`test_C_libtooling-drbq.10`). Do NOT "fix" this fixture by making the Ry
; stem decline again to match.
;
; DECLINE SIBLING: `control_inplace_ry_reject_tape_continued.ll` — the same
; program with a genuine continuation after the write. Read the two together.
;
; VERBATIM `clang -O1` output for
;   #include <stdio.h>
;   int slice(void) { int q=3, r=7;
;                     cq_theta(&q,0.5); cq_theta(&r,0.25);
;                     if (q == 5) { cq_theta(&r, 0.9); }
;                     printf("%d\n", r);
;                     return cq_measure(q); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %7)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1)
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Flag mint, ONE controlled Ry on the disjoint rail, strip, free — then the tape
; write NAMING THAT SAME RAIL, and only the CONDITION register is measured.
; CHECK: %[[T:tape[0-9]*]] = call i32 @cqrt_tape_alloc()
; CHECK: %[[Q:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK: %[[R:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i32(i32 %[[T]], i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])

; The rotated rail is FROZEN: no adjoint, no free of it, no route, no work rail,
; and every front-end intrinsic is lowered.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_measure_si
